# Verifies the validation of the driver authentication inputs

# Mock the providers so that tests run without a Kubernetes cluster or Humanitec Organization
mock_provider "helm" {}
mock_provider "humanitec" {}
mock_provider "kubernetes" {}
mock_provider "tls" {}

variables {
  helm_release_version         = "1.2.3"
  enable_driver_authentication = true
  humanitec_org_id             = "my-org"
  operator_private_key         = "-----BEGIN PRIVATE KEY-----\nabc\n-----END PRIVATE KEY-----\n"
  operator_public_key          = "-----BEGIN PUBLIC KEY-----\nabc\n-----END PUBLIC KEY-----\n"
}

run "rejects_driver_authentication_without_humanitec_org_id" {
  command = plan

  variables {
    humanitec_org_id = null
  }

  expect_failures = [var.humanitec_org_id]
}

run "rejects_driver_authentication_with_empty_humanitec_org_id" {
  command = plan

  variables {
    humanitec_org_id = ""
  }

  expect_failures = [var.humanitec_org_id]
}

run "rejects_driver_authentication_with_blank_humanitec_org_id" {
  command = plan

  variables {
    humanitec_org_id = " \n"
  }

  expect_failures = [var.humanitec_org_id]
}

run "accepts_missing_humanitec_org_id_without_driver_authentication" {
  command = plan

  variables {
    enable_driver_authentication = false
    humanitec_org_id             = null
    operator_private_key         = null
    operator_public_key          = null
  }
}

run "rejects_operator_keys_without_driver_authentication" {
  command = plan

  variables {
    enable_driver_authentication = false
  }

  expect_failures = [var.operator_private_key]
}

run "rejects_operator_private_key_without_driver_authentication" {
  command = plan

  variables {
    enable_driver_authentication = false
    operator_public_key          = null
  }

  expect_failures = [var.operator_private_key]
}

run "rejects_operator_public_key_without_driver_authentication" {
  command = plan

  variables {
    enable_driver_authentication = false
    operator_private_key         = null
  }

  expect_failures = [var.operator_private_key]
}

run "accepts_empty_operator_keys_without_driver_authentication" {
  command = plan

  variables {
    enable_driver_authentication = false
    operator_private_key         = ""
    operator_public_key          = ""
  }

  assert {
    condition     = length(tls_private_key.operator) == 0 && length(humanitec_key.operator) == 0 && length(kubernetes_secret_v1.operator_private_key) == 0
    error_message = "No driver authentication resources must be created when driver authentication is disabled"
  }
}

run "rejects_operator_private_key_without_operator_public_key" {
  command = plan

  variables {
    operator_public_key = null
  }

  expect_failures = [var.operator_private_key]
}

run "rejects_operator_public_key_without_operator_private_key" {
  command = plan

  variables {
    operator_private_key = null
  }

  expect_failures = [var.operator_private_key]
}

run "rejects_empty_operator_private_key_with_operator_public_key" {
  command = plan

  variables {
    operator_private_key = ""
  }

  expect_failures = [var.operator_private_key]
}

run "rejects_blank_operator_public_key_with_operator_private_key" {
  command = plan

  variables {
    operator_public_key = " \n"
  }

  expect_failures = [var.operator_private_key]
}

run "accepts_both_operator_keys" {
  command = plan
}

run "accepts_neither_operator_key" {
  command = plan

  variables {
    operator_private_key = null
    operator_public_key  = null
  }
}

run "accepts_arbitrary_chart_values" {
  # The module does not manage any chart values itself, so no value names are reserved
  command = plan

  variables {
    helm_release_set           = [{ name = "a", value = "1" }]
    helm_release_set_list      = [{ name = "b", value = ["2", "3"] }]
    helm_release_set_sensitive = [{ name = "c", value = "4" }]
    helm_release_set_wo        = [{ name = "d", value = "5" }]
  }
}
