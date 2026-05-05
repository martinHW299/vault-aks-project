# modules/aks/variables.tf

variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "cluster_name" { type = string }
variable "node_count" { type = number }
variable "node_size" { type = string }
variable "kubernetes_version" { type = string }
variable "project" { type = string }
variable "environment" { type = string }

variable "temporary_name_for_rotation" {
  description = "Nombre temporal requerido por AzureRM para rotar/actualizar el default node pool"
  type        = string
  default     = "tempnp"
}
