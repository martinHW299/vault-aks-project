# modules/postgresql/main.tf
# PostgreSQL como pod dentro del AKS — namespace bci-infra

resource "kubernetes_persistent_volume_claim" "postgres" {
  metadata {
    name      = "postgresql-pvc"
    namespace = var.namespace
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }

  wait_until_bound = false
}

resource "kubernetes_stateful_set" "postgres" {
  metadata {
    name      = "postgresql"
    namespace = var.namespace
    labels = {
      app = "postgresql"
    }
  }

  spec {
    service_name = "postgresql"
    replicas     = 1

    selector {
      match_labels = {
        app = "postgresql"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgresql"
        }
      }

      spec {
        container {
          name  = "postgresql"
          image = "postgres:15"

          port {
            container_port = 5432
          }

          env {
            name  = "POSTGRES_DB"
            value = var.db_name
          }
          env {
            name  = "POSTGRES_USER"
            value = var.admin_user
          }
          env {
            name  = "POSTGRES_PASSWORD"
            value = var.admin_password
          }
          env {
            name  = "PGDATA"
            value = "/var/lib/postgresql/data/pgdata"
          }

          volume_mount {
            name       = "postgresql-storage"
            mount_path = "/var/lib/postgresql/data"
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

        volume {
          name = "postgresql-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres.metadata[0].name
          }
        }
      }
    }
  }

  wait_for_rollout = false
}

resource "kubernetes_service" "postgres" {
  metadata {
    name      = "postgresql"
    namespace = var.namespace
    labels = {
      app = "postgresql"
    }
  }

  spec {
    selector = {
      app = "postgresql"
    }

    port {
      port        = 5432
      target_port = 5432
    }

    type = "ClusterIP"
  }
}

# ─── Job que crea la tabla vault_kv_store automáticamente ────────────────────
resource "kubernetes_job" "vault_db_init" {
  metadata {
    name      = "vault-db-init"
    namespace = var.namespace
  }

  spec {
    template {
      metadata {}
      spec {
        restart_policy = "OnFailure"

        container {
          name    = "vault-db-init"
          image   = "postgres:15"

          env {
            name  = "PGPASSWORD"
            value = var.admin_password
          }

          command = [
            "psql",
            "--host=postgresql",
            "--username=${var.admin_user}",
            "--dbname=${var.db_name}",
            "--command=CREATE TABLE IF NOT EXISTS vault_kv_store (parent_path TEXT COLLATE \"C\" NOT NULL, path TEXT COLLATE \"C\", key TEXT COLLATE \"C\", value BYTEA, CONSTRAINT pkey PRIMARY KEY (path, key)); CREATE INDEX IF NOT EXISTS parent_path_idx ON vault_kv_store (parent_path);"
          ]
        }
      }
    }

    # Reintentar hasta 5 veces por si PostgreSQL no está listo aún
    backoff_limit = 5
  }

  wait_for_completion = true

  timeouts {
    create = "3m"
  }

  depends_on = [
    kubernetes_stateful_set.postgres,
    kubernetes_service.postgres
  ]
}
