locals {
  # A passed-in key counts as set only if it is not empty or blank
  operator_keys_passed_in = nonsensitive(try(trimspace(var.operator_private_key), "") != "")

  operator_private_key = var.enable_driver_authentication ? coalesce(one(tls_private_key.operator[*].private_key_pem_pkcs8), var.operator_private_key) : null
  operator_public_key  = var.enable_driver_authentication ? coalesce(one(tls_private_key.operator[*].public_key_pem), var.operator_public_key) : null

  # The Operator expects the Secret under this exact name in its own namespace
  operator_private_key_secret_name = "humanitec-operator-private-key"
}

# Convenience key used only if driver authentication is enabled and no operator_private_key is passed in.
# Not recommended for production use.
resource "tls_private_key" "operator" {
  count = var.enable_driver_authentication && !local.operator_keys_passed_in ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

# Helm chart installation on target cluster
resource "helm_release" "humanitec_operator" {
  name             = var.helm_release_name
  namespace        = var.helm_release_namespace
  create_namespace = var.helm_release_create_namespace

  repository = var.helm_release_repository
  chart      = var.helm_release_chart
  version    = var.helm_release_version

  repository_ca_file   = var.helm_release_repository_ca_file
  repository_cert_file = var.helm_release_repository_cert_file
  repository_key_file  = var.helm_release_repository_key_file
  repository_username  = var.helm_release_repository_username
  repository_password  = var.helm_release_repository_password
  pass_credentials     = var.helm_release_pass_credentials
  devel                = var.helm_release_devel
  verify               = var.helm_release_verify
  keyring              = var.helm_release_keyring

  description                = var.helm_release_description
  atomic                     = var.helm_release_atomic
  cleanup_on_fail            = var.helm_release_cleanup_on_fail
  dependency_update          = var.helm_release_dependency_update
  disable_crd_hooks          = var.helm_release_disable_crd_hooks
  disable_openapi_validation = var.helm_release_disable_openapi_validation
  disable_webhooks           = var.helm_release_disable_webhooks
  force_update               = var.helm_release_force_update
  lint                       = var.helm_release_lint
  max_history                = var.helm_release_max_history
  postrender                 = var.helm_release_postrender
  recreate_pods              = var.helm_release_recreate_pods
  render_subchart_notes      = var.helm_release_render_subchart_notes
  replace                    = var.helm_release_replace
  reset_values               = var.helm_release_reset_values
  reuse_values               = var.helm_release_reuse_values
  skip_crds                  = var.helm_release_skip_crds
  take_ownership             = var.helm_release_take_ownership
  timeout                    = var.helm_release_timeout
  upgrade_install            = var.helm_release_upgrade_install
  wait                       = var.helm_release_wait
  wait_for_jobs              = var.helm_release_wait_for_jobs

  values          = var.helm_release_values
  set             = var.helm_release_set
  set_list        = var.helm_release_set_list
  set_sensitive   = var.helm_release_set_sensitive
  set_wo          = var.helm_release_set_wo
  set_wo_revision = var.helm_release_set_wo_revision
}

# Public key registration in the Orchestrator for authenticating the Operator against Humanitec-hosted Drivers
resource "humanitec_key" "operator" {
  count = var.enable_driver_authentication ? 1 : 0

  key = local.operator_public_key
}

# Private key made available to the Operator for signing requests to Humanitec-hosted Drivers
resource "kubernetes_secret_v1" "operator_private_key" {
  count = var.enable_driver_authentication ? 1 : 0

  metadata {
    name = local.operator_private_key_secret_name
    # Referencing the release ensures that the namespace exists before the Secret is created
    namespace = helm_release.humanitec_operator.namespace
  }

  data = {
    privateKey              = local.operator_private_key
    humanitecOrganisationID = var.humanitec_org_id
  }

  # Make the Operator use the private key only once the public key is registered.
  # On destroy, the Secret is removed before the registration.
  depends_on = [humanitec_key.operator]
}
