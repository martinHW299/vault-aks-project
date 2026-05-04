# modules/vault/main.tf

# ─── Namespace bci-infra ─────────────────────────────────────────────────────
resource "kubernetes_namespace" "bci_infra" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "bci/component"                = "infra"
    }
  }
}

# ─── Secret con credenciales de PostgreSQL ───────────────────────────────────
resource "kubernetes_secret" "vault_postgres" {
  metadata {
    name      = "vault-postgres-credentials"
    namespace = kubernetes_namespace.bci_infra.metadata[0].name
  }

  data = {
    connection_url = "postgres://${var.postgres_user}:${var.postgres_password}@${var.postgres_host}:5432/${var.postgres_db}?sslmode=require"
  }

  type = "Opaque"
}

# ─── Vault vía Helm ──────────────────────────────────────────────────────────
resource "helm_release" "vault" {
  name       = var.release_name
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "0.27.0"
  namespace  = kubernetes_namespace.bci_infra.metadata[0].name

  set {
    name  = "ui.enabled"
    value = "true"
  }

  set {
    name  = "ui.serviceType"
    value = "LoadBalancer"
  }

  set {
    name  = "server.standalone.enabled"
    value = "true"
  }

  # Configuración de Vault apuntando a PostgreSQL como storage backend
  set {
    name = "server.standalone.config"
    value = <<-EOT
      ui = true

      listener "tcp" {
        tls_disable = 1
        address     = "[::]:8200"
      }

      storage "postgresql" {
        connection_url = "postgres://${var.postgres_user}:${var.postgres_password}@${var.postgres_host}:5432/${var.postgres_db}?sslmode=require"
        ha_enabled     = "false"
      }
    EOT
  }

  # Esperar a que el pod esté listo
  wait    = true
  timeout = 300
}
