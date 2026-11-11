variable "humanitec_org_id" {
  description = "Humanitec Organization ID. Required if `enable_driver_authentication` is `true`, ignored otherwise."
  type        = string
  nullable    = true
  default     = null
  validation {
    condition     = !var.enable_driver_authentication || try(trimspace(var.humanitec_org_id), "") != ""
    error_message = "humanitec_org_id must be set to a non-empty value if enable_driver_authentication is true."
  }
}
variable "enable_driver_authentication" {
  description = "Enable authentication of the Operator against Humanitec-hosted Drivers. Requires `humanitec_org_id`. Registers the public key in the Humanitec Organization and stores the private key in the Kubernetes Secret `humanitec-operator-private-key` in the namespace `helm_release_namespace`. Pass in a key pair via `operator_private_key` and `operator_public_key`, or leave both unset to generate a convenience key pair. Only required if you use Humanitec-hosted Drivers. See https://developer.humanitec.com/platform-orchestrator/docs/integration-and-extensions/humanitec-operator/installation/#configure-authentication-for-drivers"
  type        = bool
  nullable    = false
  default     = false
}
variable "operator_private_key" {
  description = "Private key for the Humanitec Operator authentication against Humanitec-hosted Drivers. Must be a multiline string starting with -----BEGIN PRIVATE KEY----- and having a final line break. Both or neither of `operator_public_key` and `operator_private_key` must be set, and only if `enable_driver_authentication` is `true`. If not set while `enable_driver_authentication` is `true`, a convenience key pair will be generated using a `tls_private_key` resource and stored in the Terraform state, but this is not recommended for production use."
  type        = string
  sensitive   = true
  nullable    = true
  default     = null
  validation {
    condition     = (try(trimspace(var.operator_private_key), "") != "") == (try(trimspace(var.operator_public_key), "") != "")
    error_message = "Either both or neither of operator_private_key and operator_public_key must be set to a non-empty value. Leave both unset to generate a convenience key."
  }
  validation {
    condition     = var.enable_driver_authentication || (try(trimspace(var.operator_private_key), "") == "" && try(trimspace(var.operator_public_key), "") == "")
    error_message = "operator_private_key and operator_public_key can only be set if enable_driver_authentication is true."
  }
}
variable "operator_public_key" {
  description = "Public key for the Humanitec Operator authentication against Humanitec-hosted Drivers. Must be a multiline string starting with -----BEGIN PUBLIC KEY----- and having a final line break. Both or neither of `operator_public_key` and `operator_private_key` must be set, and only if `enable_driver_authentication` is `true`. If not set while `enable_driver_authentication` is `true`, a convenience key pair will be generated using a `tls_private_key` resource and stored in the Terraform state, but this is not recommended for production use."
  type        = string
  nullable    = true
  default     = null
}
variable "helm_release_namespace" {
  description = "Kubernetes namespace where to install the Operator"
  type        = string
  nullable    = false
  default     = "humanitec-operator-system"
}
variable "helm_release_create_namespace" {
  description = "Choose whether to create the Kubernetes namespace"
  type        = bool
  nullable    = false
  default     = true
}
variable "helm_release_name" {
  type        = string
  description = "Name of the Helm release for the Operator"
  nullable    = false
  default     = "humanitec-operator"
}
variable "helm_release_version" {
  type        = string
  description = "Chart version to use for the Operator installation in the format `X.Y.Z`. If this is not specified, the latest version is installed."
  nullable    = true
  default     = null
}
variable "helm_release_repository" {
  description = "Repository where to locate the requested chart. If is a URL the chart is installed without installing the repository. Set it to `null` for a local chart."
  type        = string
  nullable    = true
  default     = "oci://ghcr.io/humanitec/charts"
}
variable "helm_release_chart" {
  description = "Chart name to be installed. A path may be used."
  type        = string
  nullable    = false
  default     = "humanitec-operator"
}

# Optional attributes of the helm_release resource.
# Descriptions taken from https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release
# A value of null leaves the attribute unset so the provider default applies.
variable "helm_release_atomic" {
  description = "If set, installation process purges chart on fail. The wait flag will be set automatically if atomic is used. Defaults to `false`."
  type        = bool
  default     = null
}
variable "helm_release_cleanup_on_fail" {
  description = "Allow deletion of new resources created in this upgrade when upgrade fails. Defaults to `false`."
  type        = bool
  default     = null
}
variable "helm_release_dependency_update" {
  description = "Run helm dependency update before installing the chart. Defaults to `false`."
  type        = bool
  default     = null
}
variable "helm_release_description" {
  description = "Add a custom description"
  type        = string
  default     = null
}
variable "helm_release_devel" {
  description = "Use chart development versions, too. Equivalent to version '>0.0.0-0'. If `helm_release_version` is set, this is ignored"
  type        = bool
  default     = null
}
variable "helm_release_disable_crd_hooks" {
  description = "Prevent CRD hooks from running, but run other hooks. See helm install --no-crd-hook"
  type        = bool
  default     = null
}
variable "helm_release_disable_openapi_validation" {
  description = "If set, the installation process will not validate rendered templates against the Kubernetes OpenAPI Schema. Defaults to `false`."
  type        = bool
  default     = null
}
variable "helm_release_disable_webhooks" {
  description = "Prevent hooks from running. Defaults to `false`."
  type        = bool
  default     = null
}
variable "helm_release_force_update" {
  description = "Force resource update through delete/recreate if needed. Defaults to `false`."
  type        = bool
  default     = null
}
variable "helm_release_keyring" {
  description = "Location of public keys used for verification. Used only if `helm_release_verify` is true. Defaults to `/.gnupg/pubring.gpg` in the location set by `home`."
  type        = string
  default     = null
}
variable "helm_release_lint" {
  description = "Run helm lint when planning. Defaults to `false`."
  type        = bool
  default     = null
}
variable "helm_release_max_history" {
  description = "Limit the maximum number of revisions saved per release. Use 0 for no limit. Defaults to 0 (no limit)."
  type        = number
  default     = null
}
variable "helm_release_pass_credentials" {
  description = "Pass credentials to all domains. Defaults to `false`."
  type        = bool
  default     = null
}
variable "helm_release_postrender" {
  description = "Postrender command configuration."
  type = object({
    binary_path = string
    args        = optional(list(string))
  })
  default = null
}
variable "helm_release_recreate_pods" {
  description = "Perform pods restart during upgrade/rollback. Defaults to `false`."
  type        = bool
  default     = null
}
variable "helm_release_render_subchart_notes" {
  description = "If set, render subchart notes along with the parent. Defaults to `true`."
  type        = bool
  default     = null
}
variable "helm_release_replace" {
  description = "Re-use the given name, even if that name is already used. This is unsafe in production. Defaults to `false`."
  type        = bool
  default     = null
}
variable "helm_release_repository_ca_file" {
  description = "The repositories CA File"
  type        = string
  default     = null
}
variable "helm_release_repository_cert_file" {
  description = "The repositories cert file"
  type        = string
  default     = null
}
variable "helm_release_repository_key_file" {
  description = "The repositories cert key file"
  type        = string
  default     = null
}
variable "helm_release_repository_password" {
  description = "Password for HTTP basic authentication"
  type        = string
  sensitive   = true
  default     = null
}
variable "helm_release_repository_username" {
  description = "Username for HTTP basic authentication"
  type        = string
  default     = null
}
variable "helm_release_reset_values" {
  description = "When upgrading, reset the values to the ones built into the chart. Defaults to `false`."
  type        = bool
  default     = null
}
variable "helm_release_reuse_values" {
  description = "When upgrading, reuse the last release's values and merge in any overrides. If 'helm_release_reset_values' is specified, this is ignored. Defaults to `false`."
  type        = bool
  default     = null
}
variable "helm_release_set" {
  description = "Custom values to be merged with the values."
  type = list(object({
    name  = string
    value = optional(string)
    type  = optional(string)
  }))
  nullable = false
  default  = []
}
variable "helm_release_set_wo" {
  description = "Custom values to be merged with the values. This is the same as \"helm_release_set\" but write-only."
  type = list(object({
    name  = string
    value = string
    type  = optional(string)
  }))
  ephemeral = true
  nullable  = false
  default   = []
}
variable "helm_release_set_wo_revision" {
  description = "The current revision of the write-only \"helm_release_set_wo\" attribute. Incrementing this integer value will cause Terraform to update the write-only value."
  type        = number
  default     = null
}
variable "helm_release_set_list" {
  description = "Custom list values to be merged with the values."
  type = list(object({
    name  = string
    value = list(string)
  }))
  nullable = false
  default  = []
}
variable "helm_release_set_sensitive" {
  description = "Custom sensitive values to be merged with the values."
  type = list(object({
    name  = string
    value = string
    type  = optional(string)
  }))
  sensitive = true
  nullable  = false
  default   = []
}
variable "helm_release_skip_crds" {
  description = "If set, no CRDs will be installed. By default, CRDs are installed if not already present. Defaults to `false`."
  type        = bool
  default     = null
}
variable "helm_release_take_ownership" {
  description = "If set, allows Helm to adopt existing resources not marked as managed by the release. Defaults to `false`."
  type        = bool
  default     = null
}
variable "helm_release_timeout" {
  description = "Time in seconds to wait for any individual Kubernetes operation. Defaults to 300 seconds."
  type        = number
  default     = null
}
variable "helm_release_upgrade_install" {
  description = "If true, the provider will install the release at the specified version even if a release not controlled by the provider is present: this is equivalent to running 'helm upgrade --install' with the Helm CLI. WARNING: this may not be suitable for production use -- see the 'Upgrade Mode' note in the provider documentation. Defaults to `false`."
  type        = bool
  default     = null
}
variable "helm_release_values" {
  description = "List of values in raw yaml format to pass to Helm."
  type        = list(string)
  default     = null
}
variable "helm_release_verify" {
  description = "Verify the package before installing it. Defaults to `false`."
  type        = bool
  default     = null
}
variable "helm_release_wait" {
  description = "Will wait until all resources are in a ready state before marking the release as successful. Defaults to `true`."
  type        = bool
  default     = null
}
variable "helm_release_wait_for_jobs" {
  description = "If wait is enabled, will wait until all Jobs have been completed before marking the release as successful. Defaults to `false`."
  type        = bool
  default     = null
}
