# modules/postgresql/outputs.tf

output "server_fqdn" {
  description = "FQDN del servidor PostgreSQL (para la connection string de Vault)"
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "server_name" {
  value = azurerm_postgresql_flexible_server.this.name
}

output "database_name" {
  value = azurerm_postgresql_flexible_server_database.vault.name
}
