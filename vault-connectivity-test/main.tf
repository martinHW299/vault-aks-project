resource "kubernetes_namespace" "test" {
  metadata {
    name = "bci-cit-test"
  }
}

resource "kubernetes_pod" "ms_test" {
  metadata {
    name      = "ms-test"
    namespace = kubernetes_namespace.test.metadata[0].name
    labels = {
      app = "ms-test"
    }
  }

  spec {
    container {
      name  = "curl"
      image = "curlimages/curl"

      command = ["sleep", "3600"]
    }
  }
}
