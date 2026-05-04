variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
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

# ─── Resource Groups ────────────────────────────────────────────────────────
variable "rg_infra_name" {
  description = "Resource Group for AKS cluster (infrastructure)"
  type        = string
  default     = "rg-bci-infra"
}

variable "rg_app_name" {
  description = "Resource Group for application resources (Postgres, IPs)"
  type        = string
  default     = "rg-bci-app"
}

# ─── AKS ────────────────────────────────────────────────────────────────────
variable "aks_cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "aks-bci-infra"
}

variable "aks_node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 1
}

variable "aks_node_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

# ─── PostgreSQL ─────────────────────────────────────────────────────────────
variable "postgres_server_name" {
  description = "Azure PostgreSQL Flexible Server name (must be globally unique)"
  type        = string
  default     = "psql-bci-vault"
}

variable "postgres_admin_user" {
  description = "PostgreSQL administrator username"
  type        = string
  default     = "vaultadmin"
}

variable "postgres_admin_password" {
  description = "PostgreSQL administrator password"
  type        = string
  sensitive   = true
  # Set via TF_VAR_postgres_admin_password or terraform.tfvars
}

variable "postgres_sku" {
  description = "PostgreSQL SKU (tier)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgres_db_name" {
  description = "Database name for Vault"
  type        = string
  default     = "vault"
}

# ─── Vault ──────────────────────────────────────────────────────────────────
variable "vault_namespace" {
  description = "Kubernetes namespace for Vault"
  type        = string
  default     = "bci-infra"
}

variable "vault_release_name" {
  description = "Helm release name for Vault"
  type        = string
  default     = "vault"
}
