# 🧩 .NET Microservices Sample — Full DevOps Pipeline

> A production-grade e-commerce microservices application built with **.NET**, containerized with **Docker**, orchestrated with **Kubernetes/Helm**, deployed via **CI/CD pipelines** (Jenkins & Azure DevOps), and managed with **ArgoCD GitOps** on **OpenShift / KinD / AKS**.

## 🗂 Project Overview

This project implements a complete **e-commerce platform** using the microservices pattern. Each business domain (products, orders, basket, payments, discounts, identity) is an independent service with its own database, communicating asynchronously via RabbitMQ and synchronously via gRPC.

The project demonstrates a **full DevOps lifecycle**:

1. Local development with Docker Compose
2. Container orchestration with Kubernetes (KinD, OpenShift, AKS)
3. Package management with Helm
4. Automated CI/CD with Jenkins and Azure DevOps
5. GitOps continuous delivery with ArgoCD

---

## 🏗 Architecture

```
                        ┌──────────────────────────────────────────────┐
                        │              Clients (Browser)                │
                        └──────────┬───────────────────┬───────────────┘
                                   │                   │
                        ┌──────────▼──────┐   ┌───────▼──────────┐
                        │  Web Frontend   │   │  Admin Frontend  │
                        │  (ASP.NET MVC)  │   │  (ASP.NET MVC)   │
                        └──────────┬──────┘   └───────┬──────────┘
                                   │                   │
                        ┌──────────▼──────┐   ┌───────▼──────────┐
                        │  API Gateway    │   │  API Gateway     │
                        │  (Web / Ocelot) │   │  (Admin / Ocelot)│
                        └──────────┬──────┘   └───────┬──────────┘
                                   │                   │
          ┌────────────────────────┼───────────────────┼──────────────────────┐
          │                        │                   │                      │
  ┌───────▼──────┐  ┌──────────────▼──┐  ┌────────────▼───┐  ┌──────────────▼──┐
  │   Product    │  │    Basket       │  │    Ordering    │  │    Payment      │
  │   Service    │  │    Service      │  │    Service     │  │    Service      │
  │  (SQL Server)│  │   (Redis)       │  │  (MongoDB)     │  │  (SQL Server)   │
  └──────────────┘  └─────────┬───────┘  └────────────────┘  └─────────────────┘
                               │  gRPC
                        ┌──────▼──────┐        ┌──────────────────┐
                        │  Discount   │        │ Identity Service │
                        │  Service    │        │ (Duende / OIDC)  │
                        │ (SQL Server)│        │  (SQL Server)    │
                        └─────────────┘        └──────────────────┘
                               │
                  ┌────────────▼──────────────┐
                  │      RabbitMQ             │
                  │  (Publish/Subscribe)      │
                  └───────────────────────────┘
```

**Communication patterns:**
- **Sync (gRPC):** Basket → Discount (price lookup at checkout)
- **Async (RabbitMQ):** Basket publishes `CheckoutEvent` → Order, Payment, Product consume it

---

## 🔬 Microservices Breakdown

### 🔐 Identity Service
- **Technology:** Duende IdentityServer 6.2.3 + ASP.NET Identity
- **Database:** SQL Server
- **Features:** OpenID Connect, JWT token issuance, local account login
- **Port (local):** `7018` / NodePort: `31720`

### 🛒 Product Service
- **Technology:** ASP.NET Web API
- **Database:** SQL Server
- **Features:** CRUD operations, JWT authentication, RabbitMQ consumer, Swagger UI
- **Port (local):** `11002` / NodePort: `31114`

### 📦 Basket Service
- **Technology:** ASP.NET Web API
- **Database:** Redis (in-memory cache)
- **Features:** CRUD, JWT auth, gRPC call to Discount, RabbitMQ publisher, Swagger UI
- **Port (local):** `6002` / NodePort: `31602`

### 💸 Discount Service
- **Technology:** ASP.NET gRPC Server
- **Database:** SQL Server
- **Features:** Protobuf messages, gRPC endpoints for coupon management
- **Port (local):** `8003` / NodePort: `31600`

### 📋 Order Service
- **Technology:** ASP.NET Web API
- **Database:** MongoDB
- **Features:** CRUD, JWT auth, RabbitMQ consumer (CheckoutEvent), Swagger UI
- **Port (local):** `7002` / NodePort: `31705`

### 💳 Payment Service
- **Technology:** ASP.NET Web API (Clean Architecture)
- **Database:** SQL Server
- **Features:** Clean Architecture layers, JWT auth, RabbitMQ consumer, Swagger UI
- **Port (local):** `10002` / NodePort: `31104`

### 🌐 API Gateway (Web)
- **Technology:** Ocelot API Gateway
- **Features:** Route aggregation, JWT Bearer validation, request forwarding to backend services
- **Port (local):** `10023` / NodePort: `30023`

### 🛠 API Gateway (Admin)
- **Technology:** Ocelot API Gateway
- **Features:** Same as Web gateway, routes to admin-facing service endpoints
- **Port (local):** `11023` / NodePort: `31023`

### 🖥 Web Frontend
- **Technology:** ASP.NET MVC
- **Features:** OpenID Connect authentication, product browsing, basket & order management
- **Port (local):** `44328` / NodePort: `31443`

### 👩‍💼 Admin Frontend
- **Technology:** ASP.NET MVC
- **Features:** Admin dashboard, product/order management, OpenID Connect auth
- **Port (local):** `7298` / NodePort: `31298`

---

## 🛠 Technology Stack

| Layer | Technology |
|---|---|
| **Language / Framework** | C# / .NET 7 |
| **API Style** | REST (Web API) + gRPC (Discount) |
| **Identity** | Duende IdentityServer 6, ASP.NET Identity, OpenID Connect, JWT |
| **Databases** | SQL Server 2019, MongoDB, Redis |
| **Message Broker** | RabbitMQ 3 (Publish/Subscribe, Topic Exchange) |
| **API Gateway** | Ocelot |
| **Containerization** | Docker, Docker Compose |
| **Orchestration** | Kubernetes (KinD, OpenShift Local, AKS) |
| **Package Manager** | Helm 3 |
| **GitOps** | ArgoCD 3.3.8 |
| **CI/CD** | Jenkins (Declarative Pipeline) + Azure DevOps |
| **Container Registry** | Local Docker, Azure Container Registry (ACR) |

---

## 📁 Repository Structure

```
.
├── src/
│   ├── Identity/
│   │   └── IdentityService/               # Duende IdentityServer
│   ├── ApiGateways/
│   │   ├── ApiGateway.Admin/              # Ocelot Admin Gateway
│   │   └── ApiGatewayForWeb/              # Ocelot Web Gateway
│   ├── Services/
│   │   ├── Baskets/BasketService/
│   │   ├── Discounts/DiscountService/
│   │   ├── Orders/OrderService/
│   │   ├── Payments/
│   │   └── Products/ProductService/
│   └── Web/
│       ├── Microservices.Web.Frontend/
│       └── Microservices.Admin.Frontend/
├── k8s/                                   # Raw Kubernetes manifests
│   ├── configmap.yaml
│   ├── identityservice.yaml
│   ├── mongo.yaml / redis.yaml / rabbitmq.yaml / sqldata.yaml
│   ├── Productservice / Orderservice / Basketservice / ...
│   └── local-pvc.yaml
├── helm/
│   └── microservices/
│       ├── Chart.yaml
│       ├── values.yaml                    # All configurable values
│       └── templates/
│           ├── services.yaml              # All Deployments + Services
│           ├── databases.yaml
│           ├── configmap.yaml
│           ├── secrets.yaml
│           └── pvc.yaml
├── aks/                                   # Azure Kubernetes Service manifests
├── Jenkinsfile                            # Jenkins declarative pipeline
├── Azure-pipelines.yml                    # Azure DevOps pipeline
├── Install-argocd.sh                      # ArgoCD bootstrap script
├── docker-compose.yml
├── docker-compose.override.yml
├── kind-config.yaml                       # KinD cluster config
└── .env                                   # Environment variables
```

---

## 🚀 Quick Start — Docker Compose

### Prerequisites
- Docker Desktop (Windows/macOS) or Docker Engine (Linux)
- Docker Compose v2+

### Steps

**1. Clone the repository**
```bash
git clone https://github.com/mina-john-emil/.NET-Microservices-Sample-mina.git
cd .NET-Microservices-Sample-mina
```

**2. Configure your IP (optional)**

Edit `.env` and set your machine's IP or use the default:
```env
EXTERNAL_DNS_NAME_OR_IP=host.docker.internal
# or for Linux:
# EXTERNAL_DNS_NAME_OR_IP=172.20.144.1
```

**3. Build and start all services**
```bash
docker-compose up --build
```

This starts **15 containers**: all microservices + MongoDB + Redis + SQL Server + RabbitMQ + Portainer.

---

## ☸️ Kubernetes Deployment (Local / KinD)

### Prerequisites
- KinD (Kubernetes in Docker)
- kubectl
- Docker

### 1. Create KinD cluster

```bash
kind create cluster --name dev-cluster --config kind-config.yaml
```

### 2. Build and load Docker images

```bash
docker compose build

# Load images into KinD node
docker images | grep microservices | awk '{print $1":"$2}' | while read img; do
  kind load docker-image "$img" --name dev-cluster
done
```

### 3. Apply manifests

```bash
kubectl apply -f k8s/
```

Or use Helm (see below).

### 4. Configure service URLs

Update the ConfigMap with your VM's actual IP:
```bash
kubectl patch configmap microservices-config \
  --type merge \
  -p '{
    "data": {
      "Identity__Uri": "http://<your-ip>:31720",
      "MicroServiceAddress__AdminApiGateway__Uri": "http://<your-ip>:31023",
      "MicroserviceAddress__ApiGatewayForWeb__Uri": "http://<your-ip>:30023"
    }
  }'

kubectl set env deployment/identityservice-deployment \
  WebFrontend__Uri="http://<your-ip>:31443" \
  AdminFrontend__Uri="http://<your-ip>:31298"
```

### 5. Open firewall ports

```bash
firewall-cmd --permanent --add-port=31443/tcp   # Web Frontend
firewall-cmd --permanent --add-port=31298/tcp   # Admin Frontend
firewall-cmd --permanent --add-port=31720/tcp   # Identity Service
firewall-cmd --permanent --add-port=31672/tcp   # RabbitMQ UI
firewall-cmd --permanent --add-port=31023/tcp   # Admin API Gateway
firewall-cmd --permanent --add-port=30023/tcp   # Web API Gateway
firewall-cmd --reload
```

### 6. Verify pods are running

```bash
kubectl get pods -n default
```

Expected output: **14 pods**, all `Running` with `1/1` ready.

---

## ⛵ Helm Deployment

### Install

```bash
helm install microservices helm/microservices/
```

### Upgrade

```bash
helm upgrade microservices helm/microservices/
```

### Uninstall

```bash
helm uninstall microservices
```

### Key `values.yaml` settings

```yaml
global:
  registry: microservices       # Docker image prefix
  imageTag: latest              # Change to deploy a specific build
  vmIP: "192.168.150.135"       # Your machine's IP

nodePorts:
  identity: 31720
  webfrontend: 31443
  adminfrontend: 31298
  apigatewayadmin: 31023
  apigatewayforweb: 30023
  productservice: 31114
  basketservice: 31602
  orderservice: 31705
  paymentservice: 31104
  rabbitmqUI: 31672
```

---

## 🔄 CI/CD Pipelines

### Jenkins Pipeline

The `Jenkinsfile` defines a **declarative pipeline** with 9 stages:

| Stage | Description | Avg Time |
|---|---|---|
| Declarative: Checkout SCM | Pipeline initialization | ~1s |
| Checkout | Shallow clone from GitHub | ~2s |
| Build Images | `docker build` for all 10 services | ~43s |
| Test | Unit and component tests | ~10s |
| Initialize KinD Cluster | Create/verify `dev-cluster` | ~26s |
| Load Images | `kind load docker-image` for all images | ~36s |
| Deploy | `helm upgrade --install` | ~1m 9s |
| Verify | `kubectl rollout status` for all deployments | ~237ms |
| Declarative Post Actions | Cleanup dangling Docker images | ~609ms |

**Total average run time: ~3 minutes 38 seconds**

#### Setup Jenkins

1. Install Jenkins on your VM/server
2. Install plugins: Git, Pipeline, Docker Pipeline
3. Create a new Pipeline job pointing to this repository
4. The `Jenkinsfile` is auto-detected

> 📝 See `how-apply-jenkins.md` in the repository for detailed Jenkins configuration steps.

#### Pipeline Notes

- Firewall must allow outbound HTTPS to GitHub; the pipeline tests connectivity before cloning
- Clone uses `shallow: true` (depth=1) for faster checkout
- All services are built with `--network=host` for reliable connectivity in restricted environments
- KinD cluster is created if it doesn't exist; existing clusters are reused

---

### Azure DevOps Pipeline

The `Azure-pipelines.yml` defines equivalent stages running on a **self-hosted agent** (same VM):

| Job | Stage | Duration |
|---|---|---|
| Checkout from GitHub | Checkout | 7s |
| Build all microservice images | Build Images | 3m 19s |
| Run unit & component tests | Test | 27s |
| Create or verify KinD cluster | Initialize KinD | 45s |
| Load Docker images into KinD node | Load Images | 1m 17s |
| Deploy via Helm | Deploy | 9m 38s |
| Verify all pods are running | Verify | 5s |
| Prune dangling Docker images | Cleanup | 5s |

**Trigger:** Auto-triggers on every push to `main` branch.

#### Pipeline Configuration

```yaml
trigger:
  branches:
    include:
      - main

pool:
  name: Default   # Self-hosted agent

variables:
  VM_IP: '192.168.150.135'
  KIND_CLUSTER: 'dev-cluster'
  HELM_RELEASE: 'microservices'
  HELM_CHART: 'helm/microservices/'
```

---

## 🔁 GitOps with ArgoCD

ArgoCD is used for **continuous delivery** — it watches the Git repository and automatically syncs changes to the Kubernetes cluster.

### Install ArgoCD

```bash
bash Install-argocd.sh
```

This script:
1. Creates the `argocd` namespace
2. Installs ArgoCD from the stable manifest
3. Waits for all ArgoCD pods to be ready
4. Exposes the server as a NodePort on port `30443`
5. Prints the initial admin password

### Access ArgoCD UI

```
URL:      https://<your-ip>:30443
Username: admin
Password: (printed by install script)
```

### ArgoCD Application Status

The application is configured to **auto-sync** from the `main` branch. Once synced:

- **App Health:** Healthy ✅
- **Sync Status:** Synced ✅ (45 resources synced)
- **Resources:** All Deployments, Services, ConfigMaps, Secrets, PVCs tracked in the tree view

---

## 🐂 OpenShift Deployment

The project has been successfully deployed to **OpenShift Local (CRC)** in the `microservices` namespace.

### Routes Created (all Accepted ✅)

| Route | Service | URL |
|---|---|---|
| `admin-route` | adminfrontend-nodeport-srv | `http://admin-route-microservices.apps-crc.testing` |
| `apigw-admin-route` | apigatewayadmin-nodeport-srv | `http://apigw-admin-route-microservices.apps-crc.testing` |
| `apigw-web-route` | apigatewayforweb-nodeport-srv | `http://apigw-web-route-microservices.apps-crc.testing` |
| `basket-route` | basketservice-nodeport-srv | `http://basket-route-microservices.apps-crc.testing` |
| `identity-route` | identityservice-nodeport-srv | `http://identity-route-microservices.apps-crc.testing` |
| `order-route` | orderservice-nodeport-srv | `http://order-route-microservices.apps-crc.testing` |
| `payment-route` | paymentservice-nodeport-srv | `http://payment-route-microservices.apps-crc.testing` |
| `product-route` | productservice-nodeport-srv | `http://product-route-microservices.apps-crc.testing` |
| `rabbitmq-route` | rabbitmq-nodeport-srv | `http://rabbitmq-route-microservices.apps-crc.testing` |
| `web-route` | webfrontend-nodeport-srv | `http://web-route-microservices.apps-crc.testing` |

---

## 🌍 Service Endpoints & Ports

### Docker Compose (local)

| Service | URL |
|---|---|
| Web Frontend | http://host.docker.internal:44328 |
| Admin Frontend | http://host.docker.internal:7298 |
| Identity Service | http://host.docker.internal:7018 |
| API Gateway (Web) | http://host.docker.internal:10023 |
| API Gateway (Admin) | http://host.docker.internal:11023 |
| Product API (Swagger) | http://host.docker.internal:11002/swagger/index.html |
| Order API (Swagger) | http://host.docker.internal:7002/swagger/index.html |
| Discount API (Swagger) | http://host.docker.internal:8003/swagger/index.html |
| Basket API (Swagger) | http://host.docker.internal:6002/swagger/index.html |
| Payment API (Swagger) | http://host.docker.internal:10002/swagger/index.html |
| RabbitMQ Dashboard | http://host.docker.internal:15672 (guest/guest) |

### Kubernetes NodePorts

| Service | NodePort |
|---|---|
| Web Frontend | `31443` |
| Admin Frontend | `31298` |
| Identity Service | `31720` |
| API Gateway (Web) | `30023` |
| API Gateway (Admin) | `31023` |
| Product Service | `31114` |
| Basket Service | `31602` |
| Order Service | `31705` |
| Payment Service | `31104` |
| RabbitMQ UI | `31672` |

---

## 📸 Screenshots

### All Pods Running (kubectl)
```
NAME                                          READY   STATUS    RESTARTS
adminfrontend-deployment-69fbff4955-8gqqz     1/1     Running   0
apigatewayadmin-deployment-78976498d5-pn4wj   1/1     Running   0
apigatewayforweb-deployment-7bccd484cc-42cs4  1/1     Running   0
basketservice-deployment-7df9999cb-ftvvz      1/1     Running   6
discountservice-deployment-66cc4bd98d-dghhj   1/1     Running   6
identityservice-deployment-56bf47ff6c-lv6b4   1/1     Running   6
mongo-deployment-0                            1/1     Running   0
orderservice-deployment-5d6b9f7977-rfl9q      1/1     Running   5
paymentservice-deployment-845788bcb-mnqk7     1/1     Running   0
productservice-deployment-f4795878-9s5mj      1/1     Running   6
rabbitmq-deployment-0                         1/1     Running   0
redis-deployment-0                            1/1     Running   0
sqldata-deployment-0                          1/1     Running   0
webfrontend-deployment-7d8f68c7b4-ggtw4       1/1     Running   0
```

### Jenkins Pipeline — Stage View
✅ All 9 stages passing | Avg run time: ~3m 38s

### Azure DevOps Pipeline — All Jobs Passing ✅
Checkout → Build Images → Test → Initialize KinD → Load Images → Deploy → Verify → Cleanup

### ArgoCD — Application Healthy & Synced
- 45 resources synced to `main` branch
- Auto-sync enabled
- All pods healthy on `dev-cluster-control-plane` node

### OpenShift — All Routes Accepted ✅
10 routes created in `microservices` project, all with `Accepted` status

### Running Application
- Web Frontend accessible at `http://<ip>:31443`
- Duende IdentityServer login page
- RabbitMQ Management UI
- Products page rendering correctly

---

## 👥 Author

**Mina John Emil** — [GitHub Profile](https://github.com/mina-john-emil)

---

## 📄 License

This project is open source. Feel free to use it for learning and reference purposes.
