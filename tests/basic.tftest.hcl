# See https://developer.hashicorp.com/terraform/language/tests for more on how to write tests.
# See https://developer.hashicorp.com/terraform/language/tests/mocking for information on mocking providers.

# Mock the providers so that tests run without a Kubernetes cluster or Humanitec Organization
mock_provider "helm" {}
mock_provider "humanitec" {}
mock_provider "kubernetes" {}
mock_provider "tls" {}

variables {
  helm_release_version = "1.2.3"
}

run "installs_chart_with_defaults" {
  command = plan

  assert {
    condition     = helm_release.humanitec_operator.repository == "oci://ghcr.io/humanitec/charts"
    error_message = "Default repository must be the public Humanitec chart repository"
  }
  assert {
    condition     = helm_release.humanitec_operator.chart == "humanitec-operator"
    error_message = "Default chart must be humanitec-operator"
  }
  assert {
    condition     = helm_release.humanitec_operator.version == "1.2.3"
    error_message = "Chart version must be taken from helm_release_version"
  }
  assert {
    condition     = helm_release.humanitec_operator.name == "humanitec-operator"
    error_message = "Default release name must be humanitec-operator"
  }
  assert {
    condition     = helm_release.humanitec_operator.namespace == "humanitec-operator-system"
    error_message = "Default namespace must be humanitec-operator-system"
  }
  assert {
    condition     = helm_release.humanitec_operator.create_namespace == true
    error_message = "Namespace must be created by default"
  }
  assert {
    condition     = length(helm_release.humanitec_operator.set) == 0
    error_message = "The module must not set any chart values by default"
  }
  assert {
    condition     = output.helm_release_name == "humanitec-operator" && output.helm_release_namespace == "humanitec-operator-system"
    error_message = "helm_release_name and helm_release_namespace outputs must reflect the release"
  }
  assert {
    condition     = output.helm_release_chart == "humanitec-operator" && output.helm_release_version == "1.2.3" && output.helm_release_repository == "oci://ghcr.io/humanitec/charts"
    error_message = "helm_release_chart, helm_release_version and helm_release_repository outputs must reflect the release"
  }
}

run "disables_driver_authentication_by_default" {
  command = plan

  assert {
    condition     = length(tls_private_key.operator) == 0
    error_message = "No convenience key must be generated when driver authentication is disabled"
  }
  assert {
    condition     = length(humanitec_key.operator) == 0
    error_message = "No public key must be registered when driver authentication is disabled"
  }
  assert {
    condition     = length(kubernetes_secret_v1.operator_private_key) == 0
    error_message = "No private key Secret must be created when driver authentication is disabled"
  }
  assert {
    condition     = output.operator_public_key == null && output.operator_private_key == null
    error_message = "Key outputs must be null when driver authentication is disabled"
  }
  assert {
    condition     = output.operator_public_key_id == null && output.operator_public_key_fingerprint == null
    error_message = "Key registration outputs must be null when driver authentication is disabled"
  }
  assert {
    condition     = output.operator_private_key_secret_name == null
    error_message = "operator_private_key_secret_name output must be null when driver authentication is disabled"
  }
}

run "installs_chart_with_custom_release_settings" {
  command = plan

  variables {
    helm_release_name             = "my-operator"
    helm_release_namespace        = "my-namespace"
    helm_release_create_namespace = false
  }

  assert {
    condition     = helm_release.humanitec_operator.name == "my-operator"
    error_message = "Release name must be taken from helm_release_name"
  }
  assert {
    condition     = helm_release.humanitec_operator.namespace == "my-namespace"
    error_message = "Namespace must be taken from helm_release_namespace"
  }
  assert {
    condition     = helm_release.humanitec_operator.create_namespace == false
    error_message = "create_namespace must be taken from helm_release_create_namespace"
  }
}

run "installs_chart_from_custom_repository" {
  command = plan

  variables {
    helm_release_repository = "oci://registry.example.com/charts"
    helm_release_chart      = "my-humanitec-operator"
  }

  assert {
    condition     = helm_release.humanitec_operator.repository == "oci://registry.example.com/charts"
    error_message = "Repository must be taken from helm_release_repository"
  }
  assert {
    condition     = helm_release.humanitec_operator.chart == "my-humanitec-operator"
    error_message = "Chart must be taken from helm_release_chart"
  }
}

run "installs_local_chart" {
  command = plan

  variables {
    helm_release_repository = null
    helm_release_chart      = "./charts/humanitec-operator-1.2.3.tgz"
  }

  assert {
    condition     = helm_release.humanitec_operator.repository == null
    error_message = "Repository must be unset when helm_release_repository is null"
  }
  assert {
    condition     = helm_release.humanitec_operator.chart == "./charts/humanitec-operator-1.2.3.tgz"
    error_message = "Chart must be taken from helm_release_chart"
  }
}

run "passes_custom_chart_values" {
  command = plan

  variables {
    helm_release_values = [
      yamlencode({ controllerManager = { replicas = 2 } })
    ]
    helm_release_set = [
      {
        name  = "controllerManager.podSecurityContext.runAsUser"
        value = "655320000"
      }
    ]
    helm_release_set_list = [
      {
        name  = "controllerManager.manager.args"
        value = ["--leader-elect"]
      }
    ]
    helm_release_set_sensitive = [
      {
        name  = "some.secret"
        value = "s3cr3t"
      }
    ]
  }

  assert {
    # Compare element-wise: OpenTofu treats var.helm_release_values as a tuple in test assertions
    condition     = length(helm_release.humanitec_operator.values) == 1 && helm_release.humanitec_operator.values[0] == yamlencode({ controllerManager = { replicas = 2 } })
    error_message = "values must be taken from helm_release_values"
  }
  assert {
    condition     = one([for s in helm_release.humanitec_operator.set : s.value if s.name == "controllerManager.podSecurityContext.runAsUser"]) == "655320000"
    error_message = "set must be taken from helm_release_set"
  }
  assert {
    condition     = one([for s in helm_release.humanitec_operator.set_list : s.value if s.name == "controllerManager.manager.args"]) == tolist(["--leader-elect"])
    error_message = "set_list must be taken from helm_release_set_list"
  }
  assert {
    condition     = one([for s in helm_release.humanitec_operator.set_sensitive : s.value if s.name == "some.secret"]) == "s3cr3t"
    error_message = "set_sensitive must be taken from helm_release_set_sensitive"
  }
}

run "passes_optional_release_attributes" {
  command = plan

  variables {
    helm_release_atomic          = true
    helm_release_timeout         = 600
    helm_release_wait            = false
    helm_release_max_history     = 5
    helm_release_description     = "Humanitec Operator"
    helm_release_set_wo_revision = 2
  }

  assert {
    condition     = helm_release.humanitec_operator.atomic == true
    error_message = "atomic must be taken from helm_release_atomic"
  }
  assert {
    condition     = helm_release.humanitec_operator.timeout == 600
    error_message = "timeout must be taken from helm_release_timeout"
  }
  assert {
    condition     = helm_release.humanitec_operator.wait == false
    error_message = "wait must be taken from helm_release_wait"
  }
  assert {
    condition     = helm_release.humanitec_operator.max_history == 5
    error_message = "max_history must be taken from helm_release_max_history"
  }
  assert {
    condition     = helm_release.humanitec_operator.description == "Humanitec Operator"
    error_message = "description must be taken from helm_release_description"
  }
  assert {
    condition     = helm_release.humanitec_operator.set_wo_revision == 2
    error_message = "set_wo_revision must be taken from helm_release_set_wo_revision"
  }
}

run "configures_driver_authentication_with_passed_in_keys" {
  command = plan

  variables {
    enable_driver_authentication = true
    humanitec_org_id             = "my-org"
    operator_private_key         = "-----BEGIN PRIVATE KEY-----\nabc\n-----END PRIVATE KEY-----\n"
    operator_public_key          = "-----BEGIN PUBLIC KEY-----\nabc\n-----END PUBLIC KEY-----\n"
  }

  assert {
    condition     = length(tls_private_key.operator) == 0
    error_message = "No convenience key must be generated when operator_private_key is passed in"
  }
  assert {
    condition     = humanitec_key.operator[0].key == var.operator_public_key
    error_message = "The registered public key must be taken from operator_public_key"
  }
  assert {
    condition     = kubernetes_secret_v1.operator_private_key[0].metadata[0].name == "humanitec-operator-private-key"
    error_message = "The private key Secret must be named humanitec-operator-private-key"
  }
  assert {
    condition     = kubernetes_secret_v1.operator_private_key[0].metadata[0].namespace == "humanitec-operator-system"
    error_message = "The private key Secret must be created in the Operator namespace"
  }
  assert {
    condition     = kubernetes_secret_v1.operator_private_key[0].data.privateKey == var.operator_private_key
    error_message = "The Secret key privateKey must be set to operator_private_key"
  }
  assert {
    condition     = kubernetes_secret_v1.operator_private_key[0].data.humanitecOrganisationID == "my-org"
    error_message = "The Secret key humanitecOrganisationID must be set to humanitec_org_id"
  }
  assert {
    condition     = length(kubernetes_secret_v1.operator_private_key[0].data) == 2
    error_message = "The Secret must only contain the keys privateKey and humanitecOrganisationID"
  }
  assert {
    condition     = output.operator_public_key == var.operator_public_key
    error_message = "operator_public_key output must be set to operator_public_key when the keys are passed in"
  }
  assert {
    condition     = output.operator_private_key == var.operator_private_key
    error_message = "operator_private_key output must be set to operator_private_key when the keys are passed in"
  }
  assert {
    condition     = output.operator_private_key_secret_name == "humanitec-operator-private-key"
    error_message = "operator_private_key_secret_name output must contain the name of the Secret"
  }
  assert {
    condition     = length(helm_release.humanitec_operator.set) == 0 && length(helm_release.humanitec_operator.set_sensitive) == 0
    error_message = "Driver authentication must not pass any chart values"
  }
}

run "creates_private_key_secret_in_custom_namespace" {
  command = plan

  variables {
    enable_driver_authentication = true
    humanitec_org_id             = "my-org"
    helm_release_namespace       = "my-namespace"
  }

  assert {
    condition     = kubernetes_secret_v1.operator_private_key[0].metadata[0].namespace == "my-namespace"
    error_message = "The private key Secret must be created in helm_release_namespace"
  }
}

run "generates_convenience_key_without_operator_private_key" {
  # apply against the mocked providers so that the generated key values are known
  command = apply

  variables {
    enable_driver_authentication = true
    humanitec_org_id             = "my-org"
    helm_release_set_wo          = []
  }

  assert {
    condition     = length(tls_private_key.operator) == 1
    error_message = "A convenience key must be generated when operator_private_key is not passed in"
  }
  assert {
    condition     = tls_private_key.operator[0].algorithm == "RSA" && tls_private_key.operator[0].rsa_bits == 4096
    error_message = "The convenience key must be an RSA key with 4096 bits"
  }
  assert {
    condition     = humanitec_key.operator[0].key == tls_private_key.operator[0].public_key_pem
    error_message = "The registered public key must be the public key of the generated key"
  }
  assert {
    condition     = kubernetes_secret_v1.operator_private_key[0].data.privateKey == tls_private_key.operator[0].private_key_pem_pkcs8
    error_message = "The Secret key privateKey must be set to the generated key in PKCS#8 format"
  }
  assert {
    condition     = output.operator_public_key == tls_private_key.operator[0].public_key_pem
    error_message = "operator_public_key output must contain the public key of the generated key"
  }
  assert {
    condition     = output.operator_private_key == tls_private_key.operator[0].private_key_pem_pkcs8
    error_message = "operator_private_key output must contain the generated key in PKCS#8 format"
  }
  assert {
    condition     = output.operator_public_key_id == humanitec_key.operator[0].id
    error_message = "operator_public_key_id output must contain the ID of the registered key"
  }
  assert {
    condition     = output.operator_public_key_fingerprint == humanitec_key.operator[0].fingerprint
    error_message = "operator_public_key_fingerprint output must contain the fingerprint of the registered key"
  }
}

run "generates_convenience_key_with_empty_operator_keys" {
  command = plan

  variables {
    enable_driver_authentication = true
    humanitec_org_id             = "my-org"
    operator_private_key         = ""
    operator_public_key          = " \n"
  }

  assert {
    condition     = length(tls_private_key.operator) == 1
    error_message = "A convenience key must be generated when both operator keys are empty or blank"
  }
}
