variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "app_location" {
  description = "Azure region para recursos de app (p.ej., PostgreSQL en rg-bci-app)"
  type        = string
  default     = null
}

variable "project" {
  description = "Project/organization prefix"
  type        = string
  default     = "bci"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "infra"
}

# ─── Resource Groups ─────────────────────────────────────────────────────────
variable "rg_infra_name" {
  type    = string
  default = "rg-bci-infra"
}

variable "rg_app_name" {
  type    = string
  default = "rg-bci-app"
}

# ─── AKS ─────────────────────────────────────────────────────────────────────
variable "aks_cluster_name" {
  type    = string
  default = "aks-bci-infra"
}

variable "aks_node_count" {
  type    = number
  default = 1
}

variable "aks_node_size" {
  type    = string
  default = "B_Standard_B1ms"
}

variable "kubernetes_version" {
  type    = string
  default = "1.35.3"
}

# ─── PostgreSQL (pod en AKS) ──────────────────────────────────────────────────
variable "postgres_admin_user" {
  type    = string
  default = "vaultadmin"
}

variable "postgres_admin_password" {
  type      = string
  sensitive = true
}

variable "postgres_db_name" {
  type    = string
  default = "vault"
}

# ─── Azure PostgreSQL Flexible Server ─────────────────────────────────────────
variable "postgres_server_name" {
  type    = string
  default = "psql-bci-vault"
}

# ─── Vault ───────────────────────────────────────────────────────────────────
variable "vault_namespace" {
  type    = string
  default = "bci-infra"
}
