# modules/postgresql/main.tf

# ─── Private DNS Zone (para conectividad privada con AKS) ────────────────────
resource "azurerm_private_dns_zone" "postgres" {
  name                = "${var.server_name}.private.postgres.database.azure.com"
  resource_group_name = var.resource_group_name

  tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "vnetlink-postgres"
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  resource_group_name   = var.resource_group_name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

# ─── Subnet delegada para PostgreSQL Flexible Server ────────────────────────
# Vive en la misma VNet que AKS pero con delegación propia
resource "azurerm_subnet" "postgres" {
  name                 = "snet-postgres"
  resource_group_name  = var.vnet_resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = ["10.241.0.0/24"]

  delegation {
    name = "postgres-delegation"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

# ─── PostgreSQL Flexible Server ──────────────────────────────────────────────
resource "azurerm_postgresql_flexible_server" "this" {
  name                   = var.server_name
  location               = var.location
  resource_group_name    = var.resource_group_name
  version                = "15"
  administrator_login    = var.admin_user
  administrator_password = var.admin_password
  sku_name               = var.sku_name
  storage_mb             = 32768

  private_dns_zone_id = azurerm_private_dns_zone.postgres.id
  delegated_subnet_id = azurerm_subnet.postgres.id

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# ─── Base de datos para Vault ────────────────────────────────────────────────
resource "azurerm_postgresql_flexible_server_database" "vault" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.this.id
  collation = "en_US.utf8"
  charset   = "UTF8"
}

# ─── Firewall: permitir acceso desde servicios Azure ─────────────────────────
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.this.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
