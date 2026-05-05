# ─────────────────────────────────────────────────────────────────────────────
# RESOURCE GROUPS
# ─────────────────────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "infra" {
  name     = var.rg_infra_name
  location = var.location

  tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_resource_group" "app" {
  name     = var.rg_app_name
  location = coalesce(var.app_location, var.location)

  tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# AKS  (vive en rg-bci-infra)
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

# Esperar 60 segundos para que el AKS esté completamente listo
resource "time_sleep" "wait_for_aks" {
  create_duration = "60s"
  depends_on      = [module.aks]
}

# ─────────────────────────────────────────────────────────────────────────────
# NAMESPACE bci-infra
# ─────────────────────────────────────────────────────────────────────────────
resource "kubernetes_namespace" "bci_infra" {
  metadata {
    name = var.vault_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "bci/component"                = "infra"
    }
  }

  depends_on = [time_sleep.wait_for_aks]
}

# ─────────────────────────────────────────────────────────────────────────────
# POSTGRESQL como pod en AKS  (namespace bci-infra)
# ─────────────────────────────────────────────────────────────────────────────
module "postgresql" {
  source = "./modules/postgresql"

  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location

  server_name    = var.postgres_server_name
  admin_user     = var.postgres_admin_user
  admin_password = var.postgres_admin_password
  db_name        = var.postgres_db_name

  # Lab: permite conexión desde "Azure services". Ajusta/retira en prod.
  firewall_rules = [
    {
      name     = "allow-azure-services"
      start_ip = "0.0.0.0"
      end_ip   = "0.0.0.0"
    }
  ]

  depends_on = [azurerm_resource_group.app]
}

# ─────────────────────────────────────────────────────────────────────────────
# VAULT como pod en AKS  (namespace bci-infra)
# ─────────────────────────────────────────────────────────────────────────────
module "vault" {
  source = "./modules/vault"

  namespace = kubernetes_namespace.bci_infra.metadata[0].name

  postgres_host     = module.postgresql.postgres_host
  postgres_user     = module.postgresql.postgres_user
  postgres_password = var.postgres_admin_password
  postgres_db       = module.postgresql.postgres_db

  depends_on = [module.aks, module.postgresql]
}
