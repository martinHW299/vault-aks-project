# Vault en AKS + ms-java (flujo correcto)

- MS Java (Spring Boot): `ms-java/` (endpoints `/vault/health` y `/vault/secret`)
- Dockerización: `ms-java/Dockerfile`
- Manifests K8s del MS: `k8s/ms-java/`
- Script bootstrap Vault (policy + AppRole + secreto demo): `scripts/vault-approle-bootstrap-test.sh`

> Nota: ACR es un recurso de Azure, **no** se crea con manifests de Kubernetes.

---

## Prerequisitos
- Azure CLI logueado: `az login`
- Acceso a AKS: `az aks get-credentials ...`
- Herramientas locales: `kubectl`, `docker`, `mvn`
- Vault en AKS desplegado y accesible

---

## 1) Infra base (Terraform)

### 1.1 Deploy infraestructura (si aplica en este repo)
```bash
cd vault-aks-terraform
terraform init
terraform apply
```

### 1.2 Conectarte al cluster
```bash
az aks get-credentials --resource-group <RG> --name <AKS_NAME> --overwrite-existing
kubectl get pods -n bci-infra
```

### 1.3 Inicializar/unseal Vault (si corresponde)
```bash
kubectl exec -it -n bci-infra deploy/vault -- vault status
```

Si **NO** está inicializado:
```bash
kubectl exec -it -n bci-infra deploy/vault -- vault operator init -key-shares=1 -key-threshold=1
```

Si está `sealed`:
```bash
kubectl exec -it -n bci-infra deploy/vault -- vault operator unseal <UNSEAL_KEY>
```

---

## 2) Microservicio Java (código) + build (local)
```bash
cd ms-java
mvn test
mvn package
```

---

## 3) Dockerizar (local)
```bash
cd ms-java
docker build -t ms-java:1.0.0 .
docker run --rm -p 8080:8080 ms-java:1.0.0
```

Endpoints (Postman):
- `GET http://localhost:8080/actuator/health`
- `GET http://localhost:8080/vault/health`
- `GET http://localhost:8080/vault/secret` (requiere Vault accesible + AppRole)

---

## 4) Configurar Vault para el MS (bootstrap AppRole + secreto demo)
```bash
export VAULT_TOKEN=<ROOT_TOKEN>
./scripts/vault-approle-bootstrap-test.sh
```

Guarda estos valores (los necesitarás para el MS):
- `vault_role_id = ...`
- `vault_secret_id = ...`

---

## 5) Probar el MS local contra Vault en AKS (sin desplegar el MS aún)
**Idea:** Tu MS corre local, pero Vault está en AKS. Se conecta vía `kubectl port-forward`.

### 5.1 Exponer Vault a tu máquina
```bash
kubectl -n bci-infra port-forward svc/vault-server-service 8200:8200
```

Verifica que Vault responde desde tu máquina:
```bash
curl -i http://127.0.0.1:8200/v1/sys/health
```

### 5.2 Levantar el MS con env vars
```bash
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_ROLE_ID=<role_id>
export VAULT_SECRET_ID=<secret_id>
export VAULT_SECRETS_PATH=secret/myapp/test

cd ms-java
mvn spring-boot:run
```

Postman:
- `GET http://localhost:8080/vault/secret`

---

## 6) ACR (Azure) + push imagen (CLI)
### 6.1 Crear ACR
```bash
az acr create -g <RG> -n <ACR_NAME_UNICO> --sku Basic
az acr login -n <ACR_NAME_UNICO>
```

### 6.2 Tag + push
```bash
ACR_LOGIN_SERVER="$(az acr show -n <ACR_NAME_UNICO> --query loginServer -o tsv)"
docker build -t "$ACR_LOGIN_SERVER/ms-java:1.0.0" ms-java
docker push "$ACR_LOGIN_SERVER/ms-java:1.0.0"
```

---

## 7) Deploy del MS en AKS (manifests Kubernetes)

Manifests incluidos:
- Namespace: `k8s/ms-java/00-namespace.yaml`
- Secret (ejemplo): `k8s/ms-java/10-secret-approle.example.yaml`
- Deployment: `k8s/ms-java/20-deployment.yaml` (reemplaza `<ACR_LOGIN_SERVER>`)
- Service: `k8s/ms-java/30-service.yaml`
- Service (LoadBalancer, opción rápida): `k8s/ms-java/31-service-loadbalancer.yaml`
- Ingress (ejemplo): `k8s/ms-java/40-ingress.example.yaml`

### 7.1 Crear namespace
```bash
kubectl apply -f k8s/ms-java/00-namespace.yaml
```

### 7.2 Crear Secret con AppRole (no commitear credenciales reales)
```bash
cp k8s/ms-java/10-secret-approle.example.yaml /tmp/10-secret-approle.yaml
# edita /tmp/10-secret-approle.yaml con VAULT_ROLE_ID / VAULT_SECRET_ID
kubectl apply -f /tmp/10-secret-approle.yaml
```

### 7.3 Aplicar deployment/service
1) Edita `k8s/ms-java/20-deployment.yaml` y reemplaza:
- `image: <ACR_LOGIN_SERVER>/ms-java:1.0.0`

2) Aplica:
```bash
kubectl apply -f k8s/ms-java/20-deployment.yaml
kubectl apply -f k8s/ms-java/30-service.yaml
```

### 7.4 (Opción A) Exponer el MS con Service LoadBalancer
**Tipo:** Manifest  
**Para qué:** Obtener una IP pública y acceder sin `port-forward`.

```bash
kubectl apply -f k8s/ms-java/31-service-loadbalancer.yaml
kubectl -n bci-cit-test get svc ms-java-lb -w
```

Cuando aparezca `EXTERNAL-IP`, prueba:
- `GET http://<EXTERNAL-IP>/actuator/health`
- `GET http://<EXTERNAL-IP>/vault/health`

### 7.4 Probar el MS desde tu máquina (port-forward al service del MS)
```bash
kubectl -n bci-cit-test get pods
kubectl -n bci-cit-test port-forward svc/ms-java 8080:80
curl -s http://127.0.0.1:8080/vault/secret
```
