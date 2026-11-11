# Humanitec Operator on Kubernetes

This repository contains an OpenTofu/Terraform module for installing the [Humanitec Operator](https://developer.humanitec.com/platform-orchestrator/docs/integration-and-extensions/humanitec-operator/overview/) on a Kubernetes cluster.

The module uses a [Helm chart](https://helm.sh) and requires a [`hashicorp/helm` provider](https://registry.terraform.io/providers/hashicorp/helm) configured to access the target cluster. The module exposes all the properties of the [`helm_release` resource](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) as variables named `helm_release_*`.

The chart has its own values, which you can set through the module's `helm_release_values` or `helm_release_set*` variables. To list them, run `helm show values oci://ghcr.io/humanitec/charts/humanitec-operator`. See the [usage example](#set-helm-chart-values) below.

## Authentication for Drivers

The Operator needs to [authenticate against Humanitec-hosted Drivers](https://developer.humanitec.com/platform-orchestrator/docs/integration-and-extensions/humanitec-operator/installation/#configure-authentication-for-drivers) only if you use any of them. The Echo, Template, and any built-in Drivers run inside the Operator and do not need it.

Authentication for Drivers is off by default. To turn it on, set `enable_driver_authentication = true`. The module then does two things:

- It registers the public key in your Humanitec Organization with a [`humanitec_key`](https://registry.terraform.io/providers/humanitec/humanitec/latest/docs/resources/key) resource. This requires a [`humanitec/humanitec` provider](https://registry.terraform.io/providers/humanitec/humanitec).
- It stores the private key and the Humanitec Organization ID in the Kubernetes Secret `humanitec-operator-private-key` in the Operator namespace. This requires a [`hashicorp/kubernetes` provider](https://registry.terraform.io/providers/hashicorp/kubernetes) configured to access the target cluster.

You can pass in a key pair via `operator_private_key` and `operator_public_key`, or let the module generate one.

Connecting a secret store to the Operator is not part of this module. Follow one of the [guides for your secret store type](https://developer.humanitec.com/platform-orchestrator/guides/platform-engineers/security/connect-secret-stores/overview/).

## Usage

### Minimal example: Use the latest Helm chart version, use the public chart repository, no authentication for Drivers

```hcl
module "my_operator" {
  source = "github.com/humanitec-tf-modules/operator-k8s?ref=vX.Y.Z"
  providers = {
    helm = helm
  }
}
```

### Common usage: Pin the Helm chart version, use the public chart repository, no authentication for Drivers

```hcl
module "my_operator" {
  source = "github.com/humanitec-tf-modules/operator-k8s?ref=vX.Y.Z"
  providers = {
    helm = helm
  }

  helm_release_version = "1.2.3"
}
```

### Enable authentication for Drivers with your own key pair

Authentication for Drivers needs the `humanitec` and `kubernetes` providers as well as `helm`. Configure both and pass them in: the module uses `humanitec` to register the public key and `kubernetes` to store the private key.

```hcl
module "my_operator" {
  source = "github.com/humanitec-tf-modules/operator-k8s?ref=vX.Y.Z"
  providers = {
    humanitec  = humanitec
    helm       = helm
    kubernetes = kubernetes
  }

  enable_driver_authentication = true
  humanitec_org_id             = "my-org"
  operator_private_key         = "-----BEGIN PRIVATE KEY----- ..."
  operator_public_key          = "-----BEGIN PUBLIC KEY----- ..."
  helm_release_version         = "1.2.3"
}
```

### Enable authentication for Drivers with a convenience key pair

The module can generate a key pair for convenience, but we do not recommend this for production use because the module stores the private key in the Terraform state. Use an external key management solution and pass in the keys instead.

```hcl
module "my_operator" {
  source = "github.com/humanitec-tf-modules/operator-k8s?ref=vX.Y.Z"
  providers = {
    humanitec  = humanitec
    helm       = helm
    kubernetes = kubernetes
  }

  enable_driver_authentication = true
  humanitec_org_id             = "my-org"
}
```

### Set Helm chart values

You can set any Helm chart value through `helm_release_values` or `helm_release_set`. This example sets a service account annotation and a Pod label for Workload Identity on an AKS cluster:

```hcl
module "my_operator" {
  source = "github.com/humanitec-tf-modules/operator-k8s?ref=vX.Y.Z"
  providers = {
    helm = helm
  }

  # Set Helm chart values via helm_release_values (best readability)
  helm_release_values = [
    yamlencode({
      controllerManager = {
        serviceAccount = {
          annotations = {
            "azure.workload.identity/client-id" = "22222222-2222-2222-2222-222222222222"
          }
        }
        podLabels = {
          "azure.workload.identity/use" = "true"
        }
      }
    }),
  ]
  # Equivalent values via helm_release_set
  # Dots within a key must be escaped as "\\." so that Helm does not read them as nesting
  # helm_release_set = [
  #   {
  #     name  = "controllerManager.serviceAccount.annotations.azure\\.workload\\.identity/client-id"
  #     value = "22222222-2222-2222-2222-222222222222"
  #   },
  #   {
  #     name  = "controllerManager.podLabels.azure\\.workload\\.identity/use"
  #     value = "true"
  #     # Keep the value a string instead of a boolean
  #     type = "string"
  #   }
  # ]
}
```

### Self-hosting the Helm chart

```hcl
module "my_operator" {
  source = "github.com/humanitec-tf-modules/operator-k8s?ref=vX.Y.Z"
  providers = {
    helm = helm
  }

  helm_release_repository         = "oci://my-registry.example.com/my/helm/charts"
  helm_release_chart              = "humanitec-operator"
  helm_release_version            = "1.2.3"
  helm_release_repository_ca_file = "..."
  # Use other "helm_release_repository_*" variables as required to access your own registry
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.11.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 3.0 |
| <a name="requirement_humanitec"></a> [humanitec](#requirement\_humanitec) | ~> 1.9 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 3.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [helm_release.humanitec_operator](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [humanitec_key.operator](https://registry.terraform.io/providers/humanitec/humanitec/latest/docs/resources/key) | resource |
| [kubernetes_secret_v1.operator_private_key](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret_v1) | resource |
| [tls_private_key.operator](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_enable_driver_authentication"></a> [enable\_driver\_authentication](#input\_enable\_driver\_authentication) | Enable authentication of the Operator against Humanitec-hosted Drivers. Requires `humanitec_org_id`. Registers the public key in the Humanitec Organization and stores the private key in the Kubernetes Secret `humanitec-operator-private-key` in the namespace `helm_release_namespace`. Pass in a key pair via `operator_private_key` and `operator_public_key`, or leave both unset to generate a convenience key pair. Only required if you use Humanitec-hosted Drivers. See https://developer.humanitec.com/platform-orchestrator/docs/integration-and-extensions/humanitec-operator/installation/#configure-authentication-for-drivers | `bool` | `false` | no |
| <a name="input_helm_release_atomic"></a> [helm\_release\_atomic](#input\_helm\_release\_atomic) | If set, installation process purges chart on fail. The wait flag will be set automatically if atomic is used. Defaults to `false`. | `bool` | `null` | no |
| <a name="input_helm_release_chart"></a> [helm\_release\_chart](#input\_helm\_release\_chart) | Chart name to be installed. A path may be used. | `string` | `"humanitec-operator"` | no |
| <a name="input_helm_release_cleanup_on_fail"></a> [helm\_release\_cleanup\_on\_fail](#input\_helm\_release\_cleanup\_on\_fail) | Allow deletion of new resources created in this upgrade when upgrade fails. Defaults to `false`. | `bool` | `null` | no |
| <a name="input_helm_release_create_namespace"></a> [helm\_release\_create\_namespace](#input\_helm\_release\_create\_namespace) | Choose whether to create the Kubernetes namespace | `bool` | `true` | no |
| <a name="input_helm_release_dependency_update"></a> [helm\_release\_dependency\_update](#input\_helm\_release\_dependency\_update) | Run helm dependency update before installing the chart. Defaults to `false`. | `bool` | `null` | no |
| <a name="input_helm_release_description"></a> [helm\_release\_description](#input\_helm\_release\_description) | Add a custom description | `string` | `null` | no |
| <a name="input_helm_release_devel"></a> [helm\_release\_devel](#input\_helm\_release\_devel) | Use chart development versions, too. Equivalent to version '>0.0.0-0'. If `helm_release_version` is set, this is ignored | `bool` | `null` | no |
| <a name="input_helm_release_disable_crd_hooks"></a> [helm\_release\_disable\_crd\_hooks](#input\_helm\_release\_disable\_crd\_hooks) | Prevent CRD hooks from running, but run other hooks. See helm install --no-crd-hook | `bool` | `null` | no |
| <a name="input_helm_release_disable_openapi_validation"></a> [helm\_release\_disable\_openapi\_validation](#input\_helm\_release\_disable\_openapi\_validation) | If set, the installation process will not validate rendered templates against the Kubernetes OpenAPI Schema. Defaults to `false`. | `bool` | `null` | no |
| <a name="input_helm_release_disable_webhooks"></a> [helm\_release\_disable\_webhooks](#input\_helm\_release\_disable\_webhooks) | Prevent hooks from running. Defaults to `false`. | `bool` | `null` | no |
| <a name="input_helm_release_force_update"></a> [helm\_release\_force\_update](#input\_helm\_release\_force\_update) | Force resource update through delete/recreate if needed. Defaults to `false`. | `bool` | `null` | no |
| <a name="input_helm_release_keyring"></a> [helm\_release\_keyring](#input\_helm\_release\_keyring) | Location of public keys used for verification. Used only if `helm_release_verify` is true. Defaults to `/.gnupg/pubring.gpg` in the location set by `home`. | `string` | `null` | no |
| <a name="input_helm_release_lint"></a> [helm\_release\_lint](#input\_helm\_release\_lint) | Run helm lint when planning. Defaults to `false`. | `bool` | `null` | no |
| <a name="input_helm_release_max_history"></a> [helm\_release\_max\_history](#input\_helm\_release\_max\_history) | Limit the maximum number of revisions saved per release. Use 0 for no limit. Defaults to 0 (no limit). | `number` | `null` | no |
| <a name="input_helm_release_name"></a> [helm\_release\_name](#input\_helm\_release\_name) | Name of the Helm release for the Operator | `string` | `"humanitec-operator"` | no |
| <a name="input_helm_release_namespace"></a> [helm\_release\_namespace](#input\_helm\_release\_namespace) | Kubernetes namespace where to install the Operator | `string` | `"humanitec-operator-system"` | no |
| <a name="input_helm_release_pass_credentials"></a> [helm\_release\_pass\_credentials](#input\_helm\_release\_pass\_credentials) | Pass credentials to all domains. Defaults to `false`. | `bool` | `null` | no |
| <a name="input_helm_release_postrender"></a> [helm\_release\_postrender](#input\_helm\_release\_postrender) | Postrender command configuration. | <pre>object({<br/>    binary_path = string<br/>    args        = optional(list(string))<br/>  })</pre> | `null` | no |
| <a name="input_helm_release_recreate_pods"></a> [helm\_release\_recreate\_pods](#input\_helm\_release\_recreate\_pods) | Perform pods restart during upgrade/rollback. Defaults to `false`. | `bool` | `null` | no |
| <a name="input_helm_release_render_subchart_notes"></a> [helm\_release\_render\_subchart\_notes](#input\_helm\_release\_render\_subchart\_notes) | If set, render subchart notes along with the parent. Defaults to `true`. | `bool` | `null` | no |
| <a name="input_helm_release_replace"></a> [helm\_release\_replace](#input\_helm\_release\_replace) | Re-use the given name, even if that name is already used. This is unsafe in production. Defaults to `false`. | `bool` | `null` | no |
| <a name="input_helm_release_repository"></a> [helm\_release\_repository](#input\_helm\_release\_repository) | Repository where to locate the requested chart. If is a URL the chart is installed without installing the repository. Set it to `null` for a local chart. | `string` | `"oci://ghcr.io/humanitec/charts"` | no |
| <a name="input_helm_release_repository_ca_file"></a> [helm\_release\_repository\_ca\_file](#input\_helm\_release\_repository\_ca\_file) | The repositories CA File | `string` | `null` | no |
| <a name="input_helm_release_repository_cert_file"></a> [helm\_release\_repository\_cert\_file](#input\_helm\_release\_repository\_cert\_file) | The repositories cert file | `string` | `null` | no |
| <a name="input_helm_release_repository_key_file"></a> [helm\_release\_repository\_key\_file](#input\_helm\_release\_repository\_key\_file) | The repositories cert key file | `string` | `null` | no |
| <a name="input_helm_release_repository_password"></a> [helm\_release\_repository\_password](#input\_helm\_release\_repository\_password) | Password for HTTP basic authentication | `string` | `null` | no |
| <a name="input_helm_release_repository_username"></a> [helm\_release\_repository\_username](#input\_helm\_release\_repository\_username) | Username for HTTP basic authentication | `string` | `null` | no |
| <a name="input_helm_release_reset_values"></a> [helm\_release\_reset\_values](#input\_helm\_release\_reset\_values) | When upgrading, reset the values to the ones built into the chart. Defaults to `false`. | `bool` | `null` | no |
| <a name="input_helm_release_reuse_values"></a> [helm\_release\_reuse\_values](#input\_helm\_release\_reuse\_values) | When upgrading, reuse the last release's values and merge in any overrides. If 'helm\_release\_reset\_values' is specified, this is ignored. Defaults to `false`. | `bool` | `null` | no |
| <a name="input_helm_release_set"></a> [helm\_release\_set](#input\_helm\_release\_set) | Custom values to be merged with the values. | <pre>list(object({<br/>    name  = string<br/>    value = optional(string)<br/>    type  = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_helm_release_set_list"></a> [helm\_release\_set\_list](#input\_helm\_release\_set\_list) | Custom list values to be merged with the values. | <pre>list(object({<br/>    name  = string<br/>    value = list(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_helm_release_set_sensitive"></a> [helm\_release\_set\_sensitive](#input\_helm\_release\_set\_sensitive) | Custom sensitive values to be merged with the values. | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>    type  = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_helm_release_set_wo"></a> [helm\_release\_set\_wo](#input\_helm\_release\_set\_wo) | Custom values to be merged with the values. This is the same as "helm\_release\_set" but write-only. | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>    type  = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_helm_release_set_wo_revision"></a> [helm\_release\_set\_wo\_revision](#input\_helm\_release\_set\_wo\_revision) | The current revision of the write-only "helm\_release\_set\_wo" attribute. Incrementing this integer value will cause Terraform to update the write-only value. | `number` | `null` | no |
| <a name="input_helm_release_skip_crds"></a> [helm\_release\_skip\_crds](#input\_helm\_release\_skip\_crds) | If set, no CRDs will be installed. By default, CRDs are installed if not already present. Defaults to `false`. | `bool` | `null` | no |
| <a name="input_helm_release_take_ownership"></a> [helm\_release\_take\_ownership](#input\_helm\_release\_take\_ownership) | If set, allows Helm to adopt existing resources not marked as managed by the release. Defaults to `false`. | `bool` | `null` | no |
| <a name="input_helm_release_timeout"></a> [helm\_release\_timeout](#input\_helm\_release\_timeout) | Time in seconds to wait for any individual Kubernetes operation. Defaults to 300 seconds. | `number` | `null` | no |
| <a name="input_helm_release_upgrade_install"></a> [helm\_release\_upgrade\_install](#input\_helm\_release\_upgrade\_install) | If true, the provider will install the release at the specified version even if a release not controlled by the provider is present: this is equivalent to running 'helm upgrade --install' with the Helm CLI. WARNING: this may not be suitable for production use -- see the 'Upgrade Mode' note in the provider documentation. Defaults to `false`. | `bool` | `null` | no |
| <a name="input_helm_release_values"></a> [helm\_release\_values](#input\_helm\_release\_values) | List of values in raw yaml format to pass to Helm. | `list(string)` | `null` | no |
| <a name="input_helm_release_verify"></a> [helm\_release\_verify](#input\_helm\_release\_verify) | Verify the package before installing it. Defaults to `false`. | `bool` | `null` | no |
| <a name="input_helm_release_version"></a> [helm\_release\_version](#input\_helm\_release\_version) | Chart version to use for the Operator installation in the format `X.Y.Z`. If this is not specified, the latest version is installed. | `string` | `null` | no |
| <a name="input_helm_release_wait"></a> [helm\_release\_wait](#input\_helm\_release\_wait) | Will wait until all resources are in a ready state before marking the release as successful. Defaults to `true`. | `bool` | `null` | no |
| <a name="input_helm_release_wait_for_jobs"></a> [helm\_release\_wait\_for\_jobs](#input\_helm\_release\_wait\_for\_jobs) | If wait is enabled, will wait until all Jobs have been completed before marking the release as successful. Defaults to `false`. | `bool` | `null` | no |
| <a name="input_humanitec_org_id"></a> [humanitec\_org\_id](#input\_humanitec\_org\_id) | Humanitec Organization ID. Required if `enable_driver_authentication` is `true`, ignored otherwise. | `string` | `null` | no |
| <a name="input_operator_private_key"></a> [operator\_private\_key](#input\_operator\_private\_key) | Private key for the Humanitec Operator authentication against Humanitec-hosted Drivers. Must be a multiline string starting with -----BEGIN PRIVATE KEY----- and having a final line break. Both or neither of `operator_public_key` and `operator_private_key` must be set, and only if `enable_driver_authentication` is `true`. If not set while `enable_driver_authentication` is `true`, a convenience key pair will be generated using a `tls_private_key` resource and stored in the Terraform state, but this is not recommended for production use. | `string` | `null` | no |
| <a name="input_operator_public_key"></a> [operator\_public\_key](#input\_operator\_public\_key) | Public key for the Humanitec Operator authentication against Humanitec-hosted Drivers. Must be a multiline string starting with -----BEGIN PUBLIC KEY----- and having a final line break. Both or neither of `operator_public_key` and `operator_private_key` must be set, and only if `enable_driver_authentication` is `true`. If not set while `enable_driver_authentication` is `true`, a convenience key pair will be generated using a `tls_private_key` resource and stored in the Terraform state, but this is not recommended for production use. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_helm_release_chart"></a> [helm\_release\_chart](#output\_helm\_release\_chart) | Chart name used for the Operator Helm chart |
| <a name="output_helm_release_name"></a> [helm\_release\_name](#output\_helm\_release\_name) | Name of the Helm release for the Operator |
| <a name="output_helm_release_namespace"></a> [helm\_release\_namespace](#output\_helm\_release\_namespace) | Kubernetes namespace where the Operator is installed |
| <a name="output_helm_release_repository"></a> [helm\_release\_repository](#output\_helm\_release\_repository) | Repository used for the Operator Helm chart |
| <a name="output_helm_release_version"></a> [helm\_release\_version](#output\_helm\_release\_version) | Chart version used for the Operator installation |
| <a name="output_operator_private_key"></a> [operator\_private\_key](#output\_operator\_private\_key) | Private key of the Operator in PEM format. `null` if `enable_driver_authentication` is `false`. |
| <a name="output_operator_private_key_secret_name"></a> [operator\_private\_key\_secret\_name](#output\_operator\_private\_key\_secret\_name) | Name of the Kubernetes Secret holding the private key of the Operator. `null` if `enable_driver_authentication` is `false`. |
| <a name="output_operator_public_key"></a> [operator\_public\_key](#output\_operator\_public\_key) | Public key of the Operator in PEM format. `null` if `enable_driver_authentication` is `false`. |
| <a name="output_operator_public_key_fingerprint"></a> [operator\_public\_key\_fingerprint](#output\_operator\_public\_key\_fingerprint) | Fingerprint (SHA256 hash of the DER representation) of the public key registered in the Humanitec Organization. Use it to debug authentication against Humanitec-hosted Drivers. `null` if `enable_driver_authentication` is `false`. |
| <a name="output_operator_public_key_id"></a> [operator\_public\_key\_id](#output\_operator\_public\_key\_id) | ID of the public key registered in the Humanitec Organization. `null` if `enable_driver_authentication` is `false`. |
<!-- END_TF_DOCS -->
