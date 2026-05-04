# ─────────────────────────────────────────────────────────────────────────────
# RESOURCE GROUPS
# ─────────────────────────────────────────────────────────────────────────────

# RG 1 — Infraestructura (AKS, VNet)
resource "azurerm_resource_group" "infra" {
  name     = var.rg_infra_name
  location = var.location

  tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }
}

# RG 2 — Aplicación (PostgreSQL, IPs públicas)
resource "azurerm_resource_group" "app" {
  name     = var.rg_app_name
  location = var.location

  tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# AKS MODULE  (vive en rg-bci-infra)
# ─────────────────────────────────────────────────────────────────────────────
module "aks" {
  source = "./modules/aks"

  resource_group_name = azurerm_resource_group.infra.name
  location            = azurerm_resource_group.infra.location
  cluster_name        = var.aks_cluster_name
  node_count          = var.aks_node_count
  node_size           = var.aks_node_size
  kubernetes_version  = var.kubernetes_version
  project             = var.project
  environment         = var.environment
}

# ─────────────────────────────────────────────────────────────────────────────
# POSTGRESQL MODULE  (vive en rg-bci-app)
# ─────────────────────────────────────────────────────────────────────────────
module "postgresql" {
  source = "./modules/postgresql"

  resource_group_name      = azurerm_resource_group.app.name
  location                 = azurerm_resource_group.app.location
  server_name              = var.postgres_server_name
  admin_user               = var.postgres_admin_user
  admin_password           = var.postgres_admin_password
  sku_name                 = var.postgres_sku
  db_name                  = var.postgres_db_name
  project                  = var.project
  environment              = var.environment

  # VNet info para crear la subnet delegada de Postgres dentro de la VNet de AKS
  aks_subnet_id            = module.aks.node_subnet_id
  vnet_id                  = module.aks.vnet_id
  vnet_name                = module.aks.vnet_name
  vnet_resource_group_name = azurerm_resource_group.infra.name
}

# ─────────────────────────────────────────────────────────────────────────────
# VAULT MODULE  (pod en AKS, namespace bci-infra)
# ─────────────────────────────────────────────────────────────────────────────
module "vault" {
  source = "./modules/vault"

  namespace          = var.vault_namespace
  release_name       = var.vault_release_name
  postgres_host      = module.postgresql.server_fqdn
  postgres_user      = var.postgres_admin_user
  postgres_password  = var.postgres_admin_password
  postgres_db        = var.postgres_db_name

  depends_on = [module.aks, module.postgresql]
}
