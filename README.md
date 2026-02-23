# 🌐 Hybrid AI Security Platform

Enterprise-grade hybrid AI platform spanning on-premises K3d and Azure AKS, demonstrating cloud-native security patterns and multi-cluster management.

## 🎯 Project Goals

- **Learn Azure**: AKS, VNet, PostgreSQL Flexible, Key Vault, Azure Arc
- **Hybrid Architecture**: On-prem K3d + Azure AKS with unified management
- **Zero/Low Cost**: Maximize free tiers, stop AKS when not in use
- **Portfolio**: Demonstrate enterprise hybrid cloud expertise

## 👤 Author

**Stéphane (Z3ROX)** - Lead SecOps/Cloud Security Architect

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                           HYBRID AI SECURITY PLATFORM                                │
│                                                                                     │
│  ┌─────────────────────────────────┐    ┌─────────────────────────────────┐        │
│  │  K3D (On-Prem)                  │    │  AKS (Azure)                    │        │
│  │  Sensitive Data (C3-C4)         │    │  Public Data (C1-C2)            │        │
│  │                                 │    │                                 │        │
│  │  • Open WebUI (internal)        │    │  • Open WebUI (public)          │        │
│  │  • Ollama + Mistral             │    │  • (Optional: Azure OpenAI)     │        │
│  │  • RAG API + LLM Guard          │    │  • Qdrant                       │        │
│  │  • PostgreSQL (CNPG)            │    │  • PostgreSQL Flexible ☁️       │        │
│  │  • Keycloak (master IdP)        │    │  • Key Vault ☁️                 │        │
│  │  • Prometheus/Grafana/Loki      │    │  • Azure Monitor ☁️             │        │
│  │  • Falco/Kyverno                │    │  • Defender for Cloud ☁️        │        │
│  │                                 │    │                                 │        │
│  │  ┌───────────────────────────┐  │    │  ┌───────────────────────────┐  │        │
│  │  │ Azure Arc Agent           │  │    │  │ Azure Native Integration  │  │        │
│  │  │ • Policy ✓                │  │    │  │ • Policy ✓                │  │        │
│  │  │ • Monitor ✓               │  │    │  │ • Monitor ✓               │  │        │
│  │  │ • Defender ✓              │  │    │  │ • Defender ✓              │  │        │
│  │  └───────────────────────────┘  │    │  └───────────────────────────┘  │        │
│  │                                 │    │                                 │        │
│  │  Deployed by: ArgoCD (master)   │    │  Deployed by: ArgoCD (slave)    │        │
│  └─────────────────────────────────┘    └─────────────────────────────────┘        │
│                    │                                    │                          │
│                    └──────────── Tailscale ─────────────┘                          │
│                                  (mesh VPN)                                         │
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │  AZURE PORTAL - Unified View                                                │   │
│  │  • 2 clusters visible (K3d via Arc + AKS native)                            │   │
│  │  • Policies enforced on both                                                │   │
│  │  • Centralized metrics and logs                                             │   │
│  │  • Global Secure Score                                                       │   │
│  └─────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## 📊 Cost Estimation

| Resource | SKU | Cost/Month | Notes |
|----------|-----|------------|-------|
| AKS Control Plane | Free | $0 | Free tier |
| AKS Node (1x B2s) | Standard_B2s | ~$30 | Stop when not in use! |
| PostgreSQL Flexible | B_Standard_B1ms | ~$15 | Minimum viable |
| Key Vault | Standard | ~$1 | Per transaction |
| VNet, NSGs | - | $0 | Free |
| Azure Arc | - | $0 | Free |
| Azure Monitor | 5GB/month | $0 | Free tier |
| Defender Basic | - | $0 | Free tier |
| **Total (24/7)** | | **~$46/month** | |
| **Total (optimized)** | | **~$15-20/month** | Stop AKS at night |

> 💡 **$200 free credits** = 4-12 months depending on usage!

## 🚀 Quick Start

### Prerequisites

- Azure account with $200 free credits
- Azure CLI installed
- Terraform installed
- kubectl installed
- Existing K3d cluster (from ai-security-platform repo)

### Phase 1: Deploy Azure Infrastructure

```bash
# Login to Azure
az login

# Deploy infrastructure
cd terraform/azure
terraform init
terraform plan
terraform apply

# Get AKS credentials
az aks get-credentials --resource-group rg-ai-platform --name aks-ai-platform
```

### Phase 2: Connect K3d to Azure Arc

```bash
# Connect your K3d cluster to Azure Arc
./scripts/connect-arc.sh

# Verify in Azure Portal
az connectedk8s list -o table
```

### Phase 3: Deploy Applications

```bash
# Install ArgoCD on AKS
kubectl apply -k kubernetes/azure/argocd/

# Deploy applications
kubectl apply -f argocd/azure/applications/
```

### Phase 4: Connect Clusters (Tailscale)

```bash
# Install Tailscale on K3d
./scripts/setup-tailscale-k3d.sh

# Install Tailscale on AKS
./scripts/setup-tailscale-aks.sh
```

## 💰 Cost Optimization

```bash
# Stop AKS when not in use (saves ~$1/hour)
./scripts/aks-stop.sh

# Start AKS when needed
./scripts/aks-start.sh

# Check current costs
az consumption usage list --query "[].{Name:name, Cost:pretaxCost}" -o table
```

## 📁 Repository Structure

```
hybrid-ai-security-platform/
├── terraform/
│   └── azure/                    # Azure infrastructure
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── versions.tf
│       └── modules/
│           ├── networking/       # VNet, Subnets, NSGs
│           ├── aks/              # AKS cluster
│           ├── postgresql/       # PostgreSQL Flexible
│           ├── keyvault/         # Key Vault
│           └── monitoring/       # Log Analytics
│
├── kubernetes/
│   └── azure/                    # AKS manifests
│       ├── argocd/               # ArgoCD installation
│       ├── apps/                 # Applications
│       │   ├── open-webui/
│       │   ├── qdrant/
│       │   └── langfuse/
│       ├── observability/        # Monitoring
│       └── security/             # Security configs
│
├── argocd/
│   └── azure/                    # ArgoCD Applications
│       ├── applications/
│       └── projects/
│
├── scripts/
│   ├── aks-start.sh              # Start AKS
│   ├── aks-stop.sh               # Stop AKS (save money!)
│   ├── connect-arc.sh            # Connect K3d to Arc
│   └── setup-tailscale-*.sh      # Tailscale setup
│
└── docs/
    └── adr/                      # Architecture Decision Records
        └── ADR-001-hybrid-architecture.md
```

## 🔗 Related Repository

This project extends [ai-security-platform](https://github.com/Z3ROX-lab/ai-security-platform) with Azure hybrid capabilities.

| Repository | Purpose |
|------------|---------|
| `ai-security-platform` | On-prem K3d with full AI stack |
| `hybrid-ai-security-platform` | Azure extension + hybrid connectivity |

## 🛡️ Security Features

| Feature | On-Prem (K3d) | Azure (AKS) |
|---------|---------------|-------------|
| Policy Engine | Kyverno | Azure Policy |
| Runtime Security | Falco | Defender for Containers |
| Secrets | Sealed Secrets | Key Vault |
| Observability | Prometheus/Grafana/Loki | Azure Monitor |
| Identity | Keycloak | Entra ID (federated) |
| Network | NetworkPolicies | NSGs + NetworkPolicies |

## 📝 ADR (Architecture Decision Records)

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-001](docs/adr/ADR-001-hybrid-architecture.md) | Hybrid Architecture with Azure Arc | ✅ Accepted |
| [ADR-002](docs/adr/ADR-002-connectivity.md) | Tailscale for Hybrid Connectivity | ✅ Accepted |
| [ADR-003](docs/adr/ADR-003-cost-optimization.md) | Cost Optimization Strategy | ✅ Accepted |

## 🎓 Skills Demonstrated

- **Azure**: AKS, VNet, PostgreSQL Flexible, Key Vault, Arc, Policy, Monitor, Defender
- **Terraform**: Multi-module IaC for Azure
- **Kubernetes**: Multi-cluster management, GitOps
- **Security**: Hybrid security posture, unified governance
- **Networking**: VPN mesh, private endpoints, DNS

## 📄 License

MIT
