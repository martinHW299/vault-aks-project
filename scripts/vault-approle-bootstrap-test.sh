#!/usr/bin/env sh
set -eu

NAMESPACE="${NAMESPACE:-bci-infra}"
VAULT_DEPLOYMENT="${VAULT_DEPLOYMENT:-vault}"
VAULT_ADDR_IN_POD="${VAULT_ADDR_IN_POD:-http://vault-server-service.bci-infra:8200}"

PROFILE="${PROFILE:-test}"
SECRETS_PATH="${SECRETS_PATH:-secret/myapp/${PROFILE}}"

POLICY_NAME="${POLICY_NAME:-myapp-${PROFILE}}"
ROLE_NAME="${ROLE_NAME:-myapp-${PROFILE}}"

if [ -z "${VAULT_TOKEN:-}" ]; then
  echo "ERROR: set VAULT_TOKEN (root token) in your shell" >&2
  exit 1
fi

vault_exec() {
  kubectl exec -i -n "${NAMESPACE}" "deploy/${VAULT_DEPLOYMENT}" -- sh -lc "$1"
}

echo "Logging into Vault inside pod..."
vault_exec "export VAULT_ADDR='${VAULT_ADDR_IN_POD}'; printf %s '${VAULT_TOKEN}' | vault login -no-print - >/dev/null"

echo "Enabling KV v1 at 'secret/' (ignore if already enabled)..."
vault_exec "export VAULT_ADDR='${VAULT_ADDR_IN_POD}'; vault secrets enable -path=secret kv 2>/dev/null || true"

echo "Enabling AppRole auth (ignore if already enabled)..."
vault_exec "export VAULT_ADDR='${VAULT_ADDR_IN_POD}'; vault auth enable approle 2>/dev/null || true"

echo "Writing policy '${POLICY_NAME}' for path '${SECRETS_PATH}'..."
vault_exec "export VAULT_ADDR='${VAULT_ADDR_IN_POD}'; cat > /tmp/${POLICY_NAME}.hcl <<'HCL'
path \"${SECRETS_PATH}\" {
  capabilities = [\"read\"]
}
HCL
vault policy write '${POLICY_NAME}' /tmp/${POLICY_NAME}.hcl"

echo "Creating AppRole '${ROLE_NAME}'..."
vault_exec "export VAULT_ADDR='${VAULT_ADDR_IN_POD}'; vault write auth/approle/role/'${ROLE_NAME}' token_policies='${POLICY_NAME}' token_ttl=1h token_max_ttl=4h >/dev/null"

echo "Writing example secrets to '${SECRETS_PATH}'..."
vault_exec "export VAULT_ADDR='${VAULT_ADDR_IN_POD}'; vault write '${SECRETS_PATH}' DB_USER='demo' DB_PASS='demo' API_KEY='123' >/dev/null"

echo ""
echo "AppRole credentials (copy these into Terraform vars):"
ROLE_ID="$(vault_exec "export VAULT_ADDR='${VAULT_ADDR_IN_POD}'; vault read -field=role_id auth/approle/role/'${ROLE_NAME}'/role-id")"
SECRET_ID="$(vault_exec "export VAULT_ADDR='${VAULT_ADDR_IN_POD}'; vault write -f -field=secret_id auth/approle/role/'${ROLE_NAME}'/secret-id")"

echo "vault_role_id   = ${ROLE_ID}"
echo "vault_secret_id = ${SECRET_ID}"
