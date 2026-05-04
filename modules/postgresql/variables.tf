# modules/postgresql/variables.tf

variable "resource_group_name"      { type = string }
variable "location"                 { type = string }
variable "server_name"              { type = string }
variable "admin_user"               { type = string }
variable "admin_password" {
  type      = string
  sensitive = true
}
variable "sku_name"                 { type = string }
variable "db_name"                  { type = string }
variable "project"                  { type = string }
variable "environment"              { type = string }
variable "aks_subnet_id"            { type = string }
variable "vnet_id"                  { type = string }

# Necesarios para crear la subnet delegada dentro de la VNet de AKS
variable "vnet_name"                { type = string }
variable "vnet_resource_group_name" { type = string }
