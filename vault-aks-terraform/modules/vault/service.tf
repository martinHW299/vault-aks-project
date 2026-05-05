resource "kubernetes_service" "vault" {
  metadata {
    name      = "vault-server-service"
    namespace = var.namespace
  }

  spec {
    selector = {
      app = "vault-server"
    }

    port {
      name        = "http"
      port        = 8200
      target_port = 8200
      protocol    = "TCP"
    }

    type = "ClusterIP"
  }
}
