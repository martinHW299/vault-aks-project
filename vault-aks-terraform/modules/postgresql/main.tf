# modules/postgresql/main.tf
# Azure Database for PostgreSQL Flexible Server (RG: rg-bci-app)

resource "azurerm_postgresql_flexible_server" "this" {
  name                = var.server_name
  resource_group_name = var.resource_group_name
  location            = var.location

  administrator_login    = var.admin_user
  administrator_password = var.admin_password

  version    = var.postgres_version
  sku_name   = var.sku_name
  storage_mb = var.storage_mb

  public_network_access_enabled = true

  backup_retention_days        = var.backup_retention_days
  geo_redundant_backup_enabled = false

  lifecycle {
    ignore_changes = [
      # Evita intentos de rotar/cambiar zona de un servidor ya creado.
      # Azure no permite cambiar `zone` libremente (solo con HA standby AZ).
      zone,
    ]
  }
}

resource "azurerm_postgresql_flexible_server_database" "vault" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.this.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "this" {
  for_each = { for r in var.firewall_rules : r.name => r }

  name             = each.value.name
  server_id        = azurerm_postgresql_flexible_server.this.id
  start_ip_address = each.value.start_ip
  end_ip_address   = each.value.end_ip
}
