# 🌐 Hybrid AI Security Platform

Enterprise-grade hybrid AI platform spanning on-premises K3d and Azure AKS, demonstrating cloud-native security patterns, multi-cluster management, and secure hybrid connectivity.

## 🎯 Project Goals

- **Hybrid Architecture**: On-prem K3d (GPU inference) + Azure AKS (web interface) with secure tunnel
- **Learn Azure**: AKS, VNet, PostgreSQL Flexible, Key Vault, Azure Arc, Azure Policy
- **Zero/Low Cost**: Maximize free tiers, stop AKS when not in use (~$28/month)
- **Portfolio**: Demonstrate enterprise hybrid cloud and AI security expertise

## ✅ Current Status: FULLY OPERATIONAL

| Component | Status | Description |
|-----------|--------|-------------|
| ✅ AKS Cluster | Running | OpenWebUI deployed via ArgoCD |
| ✅ K3d Cluster | Running | Ollama + Mistral 7B + Embeddings |
| ✅ Azure Arc | Connected | K3d visible in Azure Portal |
| ✅ Azure Policy | Enforced | 7 policies on Arc cluster |
| ✅ Hybrid Connectivity | **Working** | ngrok tunnel (AKS → K3d) |
| ✅ RAG | **Working** | Document upload and Q&A |

## 👤 Author

**Stéphane (Z3ROX)** - Lead SecOps/Cloud Security Architect
- 20+ years telecommunications & cloud infrastructure
- Certifications: CCSP, AWS SA, ISO 27001 LI, CompTIA Security+

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           HYBRID AI SECURITY PLATFORM                                │
│                                                                                     │
│  ┌─────────────────────────────────┐         ┌─────────────────────────────────┐   │
│  │        AZURE CLOUD (AKS)        │         │    ON-PREMISES (WSL2/K3d)       │   │
│  │                                 │         │                                 │   │
│  │   ┌─────────────────────────┐   │         │   ┌─────────────────────────┐   │   │
│  │   │      OpenWebUI          │   │         │   │       Ollama            │   │   │
│  │   │   (Web Interface)       │   │         │   │    (LLM Inference)      │   │   │
│  │   │                         │   │  ngrok  │   │                         │   │   │
│  │   │   OLLAMA_BASE_URL: ─────┼───┼─────────┼──▶│   Mistral 7B (4.4GB)    │   │   │
│  │   │   https://xxx.ngrok.dev │   │  HTTPS  │   │   nomic-embed-text      │   │   │
│  │   │                         │   │  tunnel │   │                         │   │   │
│  │   └─────────────────────────┘   │         │   └─────────────────────────┘   │   │
│  │                                 │         │                                 │   │
│  │   ┌─────────────────────────┐   │         │   ┌─────────────────────────┐   │   │
│  │   │   PostgreSQL Flexible   │   │         │   │      Azure Arc          │   │   │
│  │   │   (openwebui, langfuse) │   │         │   │   (Connected to Azure)  │   │   │
│  │   └─────────────────────────┘   │         │   │   • Azure Policy ✓      │   │   │
│  │                                 │         │   │   • 3 nodes, 24 cores   │   │   │
│  │   ┌─────────────────────────┐   │         │   └─────────────────────────┘   │   │
│  │   │      Key Vault          │   │         │                                 │   │
│  │   │   (Secrets management)  │   │         │   ┌─────────────────────────┐   │   │
│  │   └─────────────────────────┘   │         │   │   Security Stack        │   │   │
│  │                                 │         │   │   • Kyverno (policies)  │   │   │
│  │   ┌─────────────────────────┐   │         │   │   • Falco (runtime)     │   │   │
│  │   │      ArgoCD             │   │         │   │   • Trivy (scanning)    │   │   │
│  │   │   (GitOps deployment)   │   │         │   │   • Prometheus/Grafana  │   │   │
│  │   └─────────────────────────┘   │         │   └─────────────────────────┘   │   │
│  │                                 │         │                                 │   │
│  │   ~$28/month                    │         │   Local GPU (free!)             │   │
│  └─────────────────────────────────┘         └─────────────────────────────────┘   │
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │  AZURE PORTAL - Unified Management                                          │   │
│  │  • 2 clusters visible (K3d via Arc + AKS native)                            │   │
│  │  • Azure Policy enforced on both clusters                                   │   │
│  │  • Centralized resource view in rg-ai-platform-dev                          │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## 📸 Screenshots

### OpenWebUI with Mistral 7B
![OpenWebUI Models](docs/screenshots/openwebui-models.png)
*OpenWebUI running on AKS, connected to Mistral 7B on K3d via ngrok*

### RAG Document Analysis
![RAG Document](docs/screenshots/rag-document.png)
*Document upload and AI-powered analysis working end-to-end*

### ngrok Traffic Dashboard
![ngrok Dashboard](docs/screenshots/ngrok-dashboard.png)
*Real-time API traffic monitoring between AKS and K3d*

### Azure Arc - K3d Connected
![Azure Arc](docs/screenshots/azure-arc-k3d.png)
*On-premises K3d cluster visible and managed from Azure Portal*

### Azure Policy Compliance
![Azure Policy](docs/screenshots/azure-policy.png)
*Azure Policy enforced on Arc-connected K3d cluster*

## 📊 Cost Estimation

| Resource | SKU | Cost/Month | Notes |
|----------|-----|------------|-------|
| AKS Control Plane | Free | $0 | Free tier |
| AKS Node (1x B2s) | Standard_B2s | ~$15 | Stop when not in use |
| PostgreSQL Flexible | B_Standard_B1ms | ~$12 | Minimum viable |
| Key Vault | Standard | ~$1 | Per transaction |
| VNet, NSGs | - | $0 | Free |
| Azure Arc | - | $0 | Free |
| ngrok | Free tier | $0 | URL changes on restart |
| **Total (optimized)** | | **~$28/month** | Stop AKS at night |

> 💡 **$200 free credits** = 7+ months of usage!

## 🚀 Quick Start

### Prerequisites

- Azure account with free credits
- Azure CLI, Terraform, kubectl installed
- Existing K3d cluster with Ollama
- ngrok account (free)

### Phase 1: Deploy Azure Infrastructure

```bash
# Login to Azure
az login

# Deploy infrastructure
cd terraform
terraform init
terraform plan
terraform apply

# Get AKS credentials
az aks get-credentials --resource-group rg-ai-platform-dev --name aks-ai-platform
```

### Phase 2: Connect K3d to Azure Arc

```bash
# Connect K3d cluster to Azure Arc
az connectedk8s connect --name k3d-ai-security-platform \
  --resource-group rg-ai-platform-dev

# Enable Azure Policy extension
az k8s-extension create --name azurepolicy \
  --cluster-name k3d-ai-security-platform \
  --resource-group rg-ai-platform-dev \
  --cluster-type connectedClusters \
  --extension-type Microsoft.PolicyInsights
```

### Phase 3: Deploy Applications (GitOps)

```bash
# Install ArgoCD on AKS
helm install argocd argo/argo-cd -n argocd --create-namespace

# Deploy root application (App of Apps)
kubectl apply -f argocd/root-app.yaml
```

### Phase 4: Setup Hybrid Connectivity (ngrok)

```bash
# On WSL2 - Start port-forward to Ollama
kubectl config use-context k3d-ai-security-platform
kubectl port-forward svc/ollama -n ai-inference 11434:11434 &

# Start ngrok tunnel
./ngrok http 11434

# Copy the URL and update OpenWebUI values.yaml
# ollamaUrls: ["https://xxx.ngrok-free.dev"]
```

## 💰 Cost Optimization Scripts

```bash
# Stop AKS when not in use (saves ~$0.50/hour)
./scripts/azure-stop-all.sh

# Start AKS when needed
./scripts/azure-start-all.sh
```

## 📁 Repository Structure

```
hybrid-ai-security-platform/
├── terraform/                    # Azure infrastructure (IaC)
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── modules/
│       ├── aks/                  # AKS cluster
│       ├── postgresql/           # PostgreSQL Flexible
│       ├── keyvault/             # Key Vault
│       └── networking/           # VNet, Subnets, NSGs
│
├── argocd/                       # GitOps configuration
│   ├── root-app.yaml             # App of Apps
│   └── applications/
│       ├── openwebui/            # OpenWebUI Helm values
│       └── tailscale-proxy/      # (deprecated, using ngrok)
│
├── scripts/
│   ├── azure-start-all.sh        # Start AKS + PostgreSQL
│   ├── azure-stop-all.sh         # Stop to save costs
│   └── start-hybrid.sh           # Start ngrok connectivity
│
└── docs/
    ├── ADR-007-HYBRID-CONNECTIVITY-NGROK.md
    ├── GUIDE-NGROK-ARCHITECTURE.md
    ├── GUIDE-AZURE-POLICY.md
    ├── GUIDE-GITOPS-ARGOCD.md
    ├── GUIDE-AZURE-INFRASTRUCTURE.md
    └── screenshots/
```

## 📝 Architecture Decision Records (ADR)

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-001](docs/ADR-001-SECRETS-MANAGEMENT.md) | Secrets Management (Key Vault + External Secrets) | ✅ Accepted |
| [ADR-002](docs/ADR-002-IAM-RBAC.md) | IAM and RBAC Strategy | ✅ Accepted |
| [ADR-003](docs/ADR-003-NETWORK-SECURITY.md) | Network Security Architecture | ✅ Accepted |
| [ADR-004](docs/ADR-004-DATA-ENCRYPTION.md) | Data Encryption at Rest and in Transit | ✅ Accepted |
| [ADR-005](docs/ADR-005-AI-GOVERNANCE.md) | AI Governance and LLM Security | ✅ Accepted |
| [ADR-006](docs/ADR-006-SUPPLY-CHAIN.md) | Supply Chain Security | ✅ Accepted |
| [ADR-007](docs/ADR-007-HYBRID-CONNECTIVITY-NGROK.md) | **Hybrid Connectivity with ngrok** | ✅ Accepted |

## 🛡️ Security Features

| Feature | On-Prem (K3d) | Azure (AKS) |
|---------|---------------|-------------|
| Policy Engine | Kyverno + Azure Policy (Arc) | Azure Policy |
| Runtime Security | Falco | Defender for Containers |
| Secrets | Sealed Secrets | Key Vault |
| Observability | Prometheus/Grafana/Loki | Azure Monitor |
| Container Scanning | Trivy Operator | Defender for Containers |
| Network | NetworkPolicies | NSGs + NetworkPolicies |

## 🎓 Skills Demonstrated

- **Azure**: AKS, VNet, PostgreSQL Flexible, Key Vault, Arc, Policy, Monitor
- **Terraform**: Multi-module IaC for Azure infrastructure
- **Kubernetes**: Multi-cluster management, Helm, GitOps with ArgoCD
- **AI/ML**: LLM deployment (Ollama/Mistral), RAG pipeline, embeddings
- **Security**: Hybrid security posture, OWASP LLM Top 10, policy enforcement
- **Networking**: Secure tunnels (ngrok), private endpoints, hybrid connectivity
- **DevOps**: GitOps, CI/CD, Infrastructure as Code

## 🔗 Related Repository

| Repository | Purpose |
|------------|---------|
| [ai-security-platform](https://github.com/Z3ROX-lab/ai-security-platform) | On-prem K3d with full AI security stack |
| **hybrid-ai-security-platform** | Azure extension + hybrid connectivity |

## 📄 License

MIT

---

*Last updated: February 26, 2026*
