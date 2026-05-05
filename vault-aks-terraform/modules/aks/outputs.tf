# modules/aks/outputs.tf

output "kube_config" {
  description = "Kubernetes credentials object"
  sensitive   = true
  value       = azurerm_kubernetes_cluster.this.kube_config[0]
}

output "kube_config_raw" {
  description = "Raw kubeconfig (para guardar en ~/.kube/config)"
  sensitive   = true
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
}

output "node_subnet_id" {
  description = "Subnet ID where AKS nodes live"
  value       = azurerm_subnet.aks_nodes.id
}

output "vnet_id" {
  description = "VNet ID"
  value       = azurerm_virtual_network.this.id
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "vnet_name" {
  description = "Nombre de la VNet creada"
  value       = azurerm_virtual_network.this.name
}
