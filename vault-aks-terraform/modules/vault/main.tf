# modules/vault/main.tf

# ─── Secret con credenciales de PostgreSQL ───────────────────────────────────
resource "kubernetes_secret" "vault_postgres" {
  metadata {
    name      = "vault-postgres-credentials"
    namespace = var.namespace
  }

  data = {
    connection_url = "postgres://${var.postgres_user}:${var.postgres_password}@${var.postgres_host}:5432/${var.postgres_db}?sslmode=disable"
  }

  type = "Opaque"
}

# ─── Vault Deployment ────────────────────────────────────────────────────────
resource "kubernetes_deployment" "vault" {
  metadata {
    name      = "vault"
    namespace = var.namespace
    labels = {
      app = "vault-server"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "vault-server"
      }
    }

    template {
      metadata {
        labels = {
          app = "vault-server"
        }
      }

      spec {
        container {
          name  = "vault"
          image = "hashicorp/vault:1.15"

          port {
            container_port = 8200
            name           = "api"
          }

          env {
            name  = "VAULT_LOCAL_CONFIG"
            value = <<-EOT
              ui = true

              listener "tcp" {
                tls_disable = 1
                address     = "0.0.0.0:8200"
              }

              storage "postgresql" {
                connection_url = "postgres://${var.postgres_user}:${var.postgres_password}@${var.postgres_host}:5432/${var.postgres_db}?sslmode=disable"
                ha_enabled     = "false"
              }

              api_addr = "http://vault-server-service.${var.namespace}:8200"
            EOT
          }

          env {
            name  = "VAULT_ADDR"
            value = "http://vault-server-service.${var.namespace}:8200"
          }

          args = ["server"]

          security_context {
            capabilities {
              add = ["IPC_LOCK"]
            }
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
      }
    }
  }

  wait_for_rollout = false
}

# ─── Vault Service (LoadBalancer para acceso externo) ────────────────────────
# resource "kubernetes_service" "vault" {
#   metadata {
#     name      = "vault-ui"
#     namespace = var.namespace
#     labels = {
#       app = "vault-server"
#     }
#   }

#   spec {
#     selector = {
#       app = "vault-server"
#     }

#     port {
#       port        = 8200
#       target_port = 8200
#       name        = "api"
#     }

#     type = "LoadBalancer"
#   }
# }
