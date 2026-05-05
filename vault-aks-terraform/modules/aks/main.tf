# modules/aks/main.tf

# ─── VNet + Subnet ───────────────────────────────────────────────────────────
resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.project}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/8"]

  tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_subnet" "aks_nodes" {
  name                 = "snet-aks-nodes"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.240.0.0/16"]
}

# ─── AKS Cluster ─────────────────────────────────────────────────────────────
resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name           = "default"
    node_count     = var.node_count
    vm_size        = var.node_size
    vnet_subnet_id = azurerm_subnet.aks_nodes.id

    temporary_name_for_rotation = var.temporary_name_for_rotation
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  # Requerido — Azure habilita OIDC por defecto y no permite deshabilitarlo
  oidc_issuer_enabled = true

  tags = {
    project     = var.project
    environment = var.environment
    managed_by  = "terraform"
  }
}
