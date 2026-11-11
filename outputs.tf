output "operator_public_key" {
  description = "Public key of the Operator in PEM format. `null` if `enable_driver_authentication` is `false`."
  value       = local.operator_public_key
}
output "operator_private_key" {
  description = "Private key of the Operator in PEM format. `null` if `enable_driver_authentication` is `false`."
  value       = local.operator_private_key
  sensitive   = true
}
output "operator_public_key_id" {
  description = "ID of the public key registered in the Humanitec Organization. `null` if `enable_driver_authentication` is `false`."
  value       = one(humanitec_key.operator[*].id)
}
output "operator_public_key_fingerprint" {
  description = "Fingerprint (SHA256 hash of the DER representation) of the public key registered in the Humanitec Organization. Use it to debug authentication against Humanitec-hosted Drivers. `null` if `enable_driver_authentication` is `false`."
  value       = one(humanitec_key.operator[*].fingerprint)
}
output "operator_private_key_secret_name" {
  description = "Name of the Kubernetes Secret holding the private key of the Operator. `null` if `enable_driver_authentication` is `false`."
  value       = one(kubernetes_secret_v1.operator_private_key[*].metadata[0].name)
}
output "helm_release_namespace" {
  description = "Kubernetes namespace where the Operator is installed"
  value       = helm_release.humanitec_operator.namespace
}
output "helm_release_name" {
  description = "Name of the Helm release for the Operator"
  value       = helm_release.humanitec_operator.name
}
output "helm_release_version" {
  description = "Chart version used for the Operator installation"
  value       = helm_release.humanitec_operator.version
}
output "helm_release_repository" {
  description = "Repository used for the Operator Helm chart"
  value       = helm_release.humanitec_operator.repository
}
output "helm_release_chart" {
  description = "Chart name used for the Operator Helm chart"
  value       = helm_release.humanitec_operator.chart
}
