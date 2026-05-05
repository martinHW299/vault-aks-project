# BCI Infra — Vault en AKS con PostgreSQL

## Arquitectura

- AKS: `aks-bci-infra` (RG: `rg-bci-infra`)
- Namespace: `bci-infra`
- Vault: Pod (`deploy/vault`)
- Service: `vault-server-service`
- PostgreSQL: Azure Flexible Server (RG: `rg-bci-app`)

---

## Deploy

```bash
cd vault-aks-terraform
terraform init
terraform apply
```

## Paso 3 — Conectarse al cluster

```bash
az aks get-credentials \
  --resource-group rg-bci-infra \
  --name aks-bci-infra \
  --overwrite-existing

kubectl get pods -n bci-infra
```

## Paso 4 — Inicializar Vault (solo la primera vez)

```bash
kubectl exec -it -n bci-infra deploy/vault -- \
  vault operator init -key-shares=1 -key-threshold=1
```

Guarda la salida. Verás algo así:
```
Unseal Key 1: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Initial Root Token: hvs.XXXXXXXXXXXXXXXXXXXXXXXX
```

## Paso 5 — Unseal Vault

```bash
kubectl exec -it -n bci-infra deploy/vault -- \
  vault operator unseal <UNSEAL_KEY>
```

## Paso 6 — Obtener VAULT_ADDR

```bash
kubectl get svc vault-server-service -n bci-infra
```

## Entregables

| Variable      | Valor                                  |
|---------------|----------------------------------------|
| `VAULT_ADDR`  | `http://vault-server-service.bci-infra:8200` |
| `VAULT_TOKEN` | `hvs.XXXX` (Initial Root Token)        |

Nota: Azure PostgreSQL Flexible Server requiere backups (no existe retención 0); el módulo usa el mínimo típico de `7` días.

## Test (con otro microservicio)

```bash
cd ~/vault-connectivity-test

terraform init
terraform apply
```

namespace: bci-cit-test
pod: ms-test

```bash
kubectl exec -it -n bci-cit-test ms-test -- \
  curl -i http://vault-server-service.bci-infra:8200/v1/sys/health
```

## Resultado esperado

```
HTTP/1.1 200 OK
```

```JSON
{"initialized":true,"sealed":false}
```
