# modules/postgresql/variables.tf

variable "resource_group_name" { type = string }
variable "location" { type = string }

variable "server_name" {
  description = "Nombre del Azure PostgreSQL Flexible Server"
  type        = string
}

variable "admin_user" { type = string }

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "db_name" { type = string }

variable "postgres_version" {
  type    = string
  default = "15"
}

variable "sku_name" {
  description = "SKU del Flexible Server (elige uno barato para lab)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "storage_mb" {
  description = "Storage en MB"
  type        = number
  default     = 32768
}

# Flexible Server requiere backup (no existe 0 días). Mínimo típico: 7 días.
variable "backup_retention_days" {
  type    = number
  default = 7
}

variable "firewall_rules" {
  description = "Reglas firewall para permitir conexión (temporal en lab)"
  type = list(object({
    name     = string
    start_ip = string
    end_ip   = string
  }))
  default = [
    {
      name     = "allow-azure-services"
      start_ip = "0.0.0.0"
      end_ip   = "0.0.0.0"
    }
  ]
}
