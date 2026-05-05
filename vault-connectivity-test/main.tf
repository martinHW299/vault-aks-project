resource "kubernetes_namespace" "test" {
  metadata {
    name = "bci-cit-test"
  }
}

resource "kubernetes_secret" "vault_approle" {
  metadata {
    name      = "vault-approle"
    namespace = kubernetes_namespace.test.metadata[0].name
  }

  type = "Opaque"

  data = {
    VAULT_ROLE_ID   = var.vault_role_id
    VAULT_SECRET_ID = var.vault_secret_id
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

      env {
        name  = "VAULT_ADDR"
        value = var.vault_addr
      }

      env {
        name  = "VAULT_PROFILE"
        value = var.vault_profile
      }

      env {
        name  = "VAULT_SECRETS_PATH"
        value = var.vault_secrets_path
      }

      env {
        name = "VAULT_ROLE_ID"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.vault_approle.metadata[0].name
            key  = "VAULT_ROLE_ID"
          }
        }
      }

      env {
        name = "VAULT_SECRET_ID"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.vault_approle.metadata[0].name
            key  = "VAULT_SECRET_ID"
          }
        }
      }

      command = [
        "sh",
        "-c",
        <<-EOT
          set -eu

          : "$${VAULT_ADDR:?missing}"
          : "$${VAULT_ROLE_ID:?missing}"
          : "$${VAULT_SECRET_ID:?missing}"

          if [ -z "$${VAULT_SECRETS_PATH:-}" ]; then
            : "$${VAULT_PROFILE:?missing (set VAULT_SECRETS_PATH or VAULT_PROFILE)}"
            VAULT_SECRETS_PATH="secret/myapp/$${VAULT_PROFILE}"
          fi

          echo "VAULT_ADDR=$${VAULT_ADDR}"
          echo "VAULT_PROFILE=$${VAULT_PROFILE:-}"
          echo "VAULT_SECRETS_PATH=$${VAULT_SECRETS_PATH}"

          login_payload="{\"role_id\":\"$${VAULT_ROLE_ID}\",\"secret_id\":\"$${VAULT_SECRET_ID}\"}"
          login_resp="$(curl -sS --fail --header 'Content-Type: application/json' --request POST --data "$${login_payload}" "$${VAULT_ADDR}/v1/auth/approle/login")"

          token="$(printf '%s' "$${login_resp}" | tr -d '\n' | sed -n 's/.*"client_token":"\([^"]*\)".*/\1/p')"
          if [ -z "$${token}" ]; then
            echo "ERROR: couldn't parse client_token from login response" >&2
            printf '%s\n' "$${login_resp}" >&2
            exit 1
          fi

          secrets_path="$${VAULT_SECRETS_PATH#/}"
          echo "Reading: $${VAULT_ADDR}/v1/$${secrets_path}"
          curl -sS --fail --header "X-Vault-Token: $${token}" "$${VAULT_ADDR}/v1/$${secrets_path}" | tee /tmp/vault-secret.json

          echo ""
          echo "OK: secret fetched and stored at /tmp/vault-secret.json"
          sleep 3600
        EOT
      ]
    }
  }
}
