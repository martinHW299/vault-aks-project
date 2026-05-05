# outputs.tf

output "vault_address" {
  description = "VAULT_ADDR — dirección pública de Vault (disponible después del init manual)"
  value       = "http://vault-server-service.bci-infra:8200"
}

output "kube_config_command" {
  description = "Comando para conectarte al cluster AKS"
  value       = "az aks get-credentials --resource-group ${var.rg_infra_name} --name ${var.aks_cluster_name}"
}

output "vault_init_command" {
  description = "Comando para inicializar Vault (solo la primera vez)"
  value       = "kubectl exec -it -n ${var.vault_namespace} deploy/vault -- vault operator init -key-shares=1 -key-threshold=1"
}

output "vault_unseal_command" {
  description = "Comando para unseal Vault (reemplaza <UNSEAL_KEY>)"
  value       = "kubectl exec -it -n ${var.vault_namespace} deploy/vault -- vault operator unseal <UNSEAL_KEY>"
}

output "postgres_host" {
  description = "FQDN del Azure PostgreSQL Flexible Server"
  value       = module.postgresql.postgres_host
}
