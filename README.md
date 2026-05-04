# BCI Infra — Vault en AKS con PostgreSQL

## Arquitectura

```
┌─────────────────────────────┐    ┌─────────────────────────────┐
│      rg-bci-infra           │    │       rg-bci-app            │
│                             │    │                             │
│  ┌─────────────────────┐    │    │  ┌──────────────────────┐   │
│  │   AKS Cluster       │    │    │  │  Azure PostgreSQL    │   │
│  │   aks-bci-infra     │    │    │  │  psql-bci-vault      │   │
│  │                     │    │    │  │  (Flexible Server)   │   │
│  │  namespace:bci-infra│◄───┼────┼──│  db: vault           │   │
│  │  ├── Pod: vault-0   │    │    │  └──────────────────────┘   │
│  │  └── Svc: vault-ui  │    │    │                             │
│  └─────────────────────┘    │    │                             │
│         VNet / Subnet       │    │                             │
└─────────────────────────────┘    └─────────────────────────────┘
```

## Pre-requisitos

```bash
# Instalar herramientas
brew install terraform azure-cli kubectl helm   # macOS
# o usa el Azure Cloud Shell (ya tiene todo instalado)

# Login en Azure
az login
az account show   # verificar que estás en la suscripción correcta
```

## Paso 1 — Configurar variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tus valores reales
# ⚠️ El postgres_server_name debe ser globalmente único en Azure
```

## Paso 2 — Aplicar Terraform

```bash
terraform init
terraform plan    # revisar qué se va a crear
terraform apply   # escribir "yes" para confirmar
```

⏱️ El apply tarda aproximadamente **10-15 minutos** (AKS tarda más).

## Paso 3 — Conectarse al cluster

```bash
az aks get-credentials --resource-group rg-bci-infra --name aks-bci-infra
kubectl get pods -n bci-infra   # debe mostrar vault-0
```

## Paso 4 — Inicializar Vault (solo la primera vez)

```bash
kubectl exec -it vault-0 -n bci-infra -- vault operator init -key-shares=1 -key-threshold=1
```

Guarda la salida. Verás algo así:
```
Unseal Key 1: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
Initial Root Token: hvs.XXXXXXXXXXXXXXXXXXXXXXXX
```

## Paso 5 — Unseal Vault

```bash
kubectl exec -it vault-0 -n bci-infra -- vault operator unseal <UNSEAL_KEY>
```

## Paso 6 — Obtener VAULT_ADDR

```bash
kubectl get svc vault-ui -n bci-infra
# Copia la EXTERNAL-IP
```

```
NAME       TYPE           EXTERNAL-IP       PORT(S)
vault-ui   LoadBalancer   20.XX.XX.XX       8200:XXXXX/TCP
```

## Entregables

| Variable      | Valor                                  |
|---------------|----------------------------------------|
| `VAULT_ADDR`  | `http://<EXTERNAL-IP>:8200`            |
| `VAULT_TOKEN` | `hvs.XXXX` (Initial Root Token)        |

## Verificar que todo funciona

```bash
export VAULT_ADDR="http://<EXTERNAL-IP>:8200"
export VAULT_TOKEN="hvs.XXXX"

curl $VAULT_ADDR/v1/sys/health
# Debe retornar: {"initialized":true,"sealed":false,...}
```

## Nomenclatura BCI

| Contexto              | Namespace      |
|-----------------------|----------------|
| Infraestructura base  | `bci-infra`    |
| Corredora (ejemplo)   | `bci-cit-...`  |

## .gitignore recomendado

```
.terraform/
terraform.tfstate
terraform.tfstate.backup
terraform.tfvars        # ⚠️ contiene passwords
.terraform.lock.hcl
```
