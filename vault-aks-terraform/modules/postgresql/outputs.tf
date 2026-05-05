# modules/postgresql/outputs.tf

output "postgres_host" {
  description = "FQDN del Azure PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "postgres_db" {
  value = azurerm_postgresql_flexible_server_database.vault.name
}

output "postgres_user" {
  value = var.admin_user
}
