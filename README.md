# Vault en AKS + test de conectividad

## Componentes
- AKS: `aks-bci-infra` (RG: `rg-bci-infra`)
- Namespace Vault: `bci-infra`
- Service Vault: `vault-server-service` (puerto `8200`)
- Test: `vault-connectivity-test` (namespace `bci-cit-test`, pod `ms-test`)

## 1) Deploy infraestructura (Vault)
```bash
cd vault-aks-terraform
terraform init
terraform apply
```

## 2) Conectarte al cluster
```bash
az aks get-credentials --resource-group rg-bci-infra --name aks-bci-infra --overwrite-existing
kubectl get pods -n bci-infra
```

## 3) Inicializar y/o unseal Vault
Estado:
```bash
kubectl exec -it -n bci-infra deploy/vault -- vault status
```

Si **NO** está inicializado:
```bash
kubectl exec -it -n bci-infra deploy/vault -- vault operator init -key-shares=1 -key-threshold=1
```
Guarda el `UNSEAL_KEY` y el `ROOT_TOKEN`.

Si aparece **"Vault is already initialized"**:
- No corras `init` de nuevo.
- Si está `sealed`, ejecuta:
```bash
kubectl exec -it -n bci-infra deploy/vault -- vault operator unseal <UNSEAL_KEY>
```

## 4) Test de conectividad desde otro namespace
Primero crea el AppRole + policy + secreto (KV v1) para el test:
```bash
export VAULT_TOKEN=<ROOT_TOKEN>
./scripts/vault-approle-bootstrap-test.sh
```

Luego configura Terraform con el `role_id` y `secret_id` generados:
```bash
cd vault-connectivity-test
cp terraform.tfvars.example terraform.tfvars
# edita terraform.tfvars y pega vault_role_id / vault_secret_id
```

```bash
cd vault-connectivity-test
terraform init
terraform apply
kubectl get pods -n bci-cit-test
```

Probar health:
```bash
kubectl exec -it -n bci-cit-test ms-test -- curl -i http://vault-server-service.bci-infra:8200/v1/sys/health
```

Esperado: `HTTP/1.1 200 OK` y `{"initialized":true,"sealed":false}`.
