# 🛡️ Hybrid AI Security Platform

Enterprise-grade hybrid AI platform spanning on-premises K3d and Azure AKS, demonstrating cloud-native security patterns, OWASP LLM Top 10 coverage, Zero Trust IAM, and AI guardrails — with 12 validated security tests and 37 documented screenshots.

## 👤 Author

**Stéphane (Z3ROX)** — Lead SecOps / Cloud Security Architect
- 20+ years telecommunications & cloud infrastructure
- Certifications: CCSP, AWS SA, ISO 27001 LI, CompTIA Security+

## ✅ Platform Status: 12/12 TESTS PASSED

| # | Test | Status | Key Evidence |
|---|------|--------|--------------|
| 1 | OpenWebUI + Ollama (Mistral 7B) | ✅ | Chat working, model connected |
| 2 | Hybrid Connectivity (ngrok) | ✅ | AKS → K3d tunnel, POST /api/chat |
| 3 | RAG Pipeline (Qdrant) | ✅ | Document ingestion + context-aware Q&A |
| 4 | Azure Arc | ✅ | K3d connected, 3 nodes, 24 cores |
| 5 | Azure Policy | ✅ | 14 policies evaluated on Arc cluster |
| 6 | Kyverno Policies | ✅ | 6 ClusterPolicies in Audit mode |
| 7 | Falco Runtime Security | ✅ | OWASP-LLM10 custom rules, model theft detection |
| 8 | Trivy Vulnerability Scanning | ✅ | 8 Critical, 73 High, 206 Medium CVEs |
| 9 | Monitoring (Grafana) | ✅ | 20+ dashboards, Prometheus + Loki |
| 10 | Azure Defender for Cloud | ✅ | 5 resources assessed, 3 recommendations |
| 11 | Keycloak SSO + RBAC | ✅ | OIDC, groups, model access control |
| 12 | LLM Guard (Guardrails) | ✅ | Prompt injection **blocked** 🛡️ |

> 📄 Full demo documentation: [`docs/demo/DEMO-TEST.md`](docs/demo/DEMO-TEST.md) — 37 screenshots

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────┐
│                  AZURE CLOUD                         │
│  ┌──────────┐  ┌────────────┐  ┌─────────────────┐  │
│  │   AKS    │  │ Azure Arc  │  │ Defender for    │  │
│  │ OpenWebUI│  │ (Hybrid)   │  │ Cloud           │  │
│  └──────────┘  └────────────┘  └─────────────────┘  │
│  ┌──────────────────────────────────────────────┐    │
│  │ Azure Policy │ Key Vault │ PostgreSQL Flex    │    │
│  └──────────────────────────────────────────────┘    │
└───────────────────────┬─────────────────────────────┘
                        │ ngrok tunnel + Azure Arc
                        ▼
┌─────────────────────────────────────────────────────┐
│              K3D LOCAL CLUSTER (3 nodes)             │
│                                                      │
│  ┌─── AI Inference ─────────────────────────────┐   │
│  │ OpenWebUI → LLM Guard → RAG → Ollama(Mistral)│   │
│  │ Qdrant (Vector DB) │ Guardrails API           │   │
│  └───────────────────────────────────────────────┘   │
│                                                      │
│  ┌─── IAM / Zero Trust ────────────────────────┐    │
│  │ Keycloak (OIDC/SSO) │ RBAC │ Groups          │   │
│  │ Realm: ai-platform │ Group: ai-security-team  │   │
│  └───────────────────────────────────────────────┘   │
│                                                      │
│  ┌─── Security ─────────────────────────────────┐   │
│  │ Falco (DaemonSet) │ Kyverno │ Trivy Operator │   │
│  │ OWASP-LLM10 rules │ 6 policies │ CVE scans   │   │
│  └───────────────────────────────────────────────┘   │
│                                                      │
│  ┌─── Observability ────────────────────────────┐   │
│  │ Prometheus │ Grafana │ Loki │ Promtail        │   │
│  │ Alertmanager │ Node Exporter │ kube-state     │   │
│  └───────────────────────────────────────────────┘   │
│                                                      │
│  ┌─── Networking & GitOps ──────────────────────┐   │
│  │ Traefik (Ingress) │ ngrok │ ArgoCD            │   │
│  └───────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

---

## 🛡️ OWASP LLM Top 10 Coverage

| OWASP LLM | Threat | Mitigation | Tool | Status |
|------------|--------|------------|------|--------|
| LLM01 | Prompt Injection | Input sanitization | LLM Guard | ✅ Blocked |
| LLM02 | Insecure Output | Output filtering | LLM Guard | ✅ Active |
| LLM03 | Training Data Poisoning | Image CVE scanning | Trivy | ✅ Scanning |
| LLM04 | Model DoS | Resource limits | Kyverno | ✅ Policies |
| LLM05 | Supply Chain | Container scanning | Trivy | ✅ 8C/73H/206M |
| LLM06 | Sensitive Info Disclosure | PII detection | LLM Guard | ✅ Active |
| LLM07 | Insecure Plugin Design | Network policies, RBAC | Kyverno | ✅ Policies |
| LLM08 | Excessive Agency | Least privilege, groups | Keycloak | ✅ Groups |
| LLM09 | Overreliance | Audit logging | Grafana, Loki | ✅ Dashboards |
| LLM10 | Model Theft | Runtime file access detection | Falco | ✅ Alerts |

---

## 🔐 Security Stack

| Layer | On-Prem (K3d) | Azure (AKS) |
|-------|---------------|-------------|
| **IAM** | Keycloak (OIDC/SSO) | Entra ID (planned) |
| **AI Guardrails** | LLM Guard + Guardrails API | — |
| **Policy Engine** | Kyverno + Azure Policy (Arc) | Azure Policy |
| **Runtime Security** | Falco (OWASP-LLM10 rules) | Defender for Containers |
| **Vulnerability Scanning** | Trivy Operator | Defender for Containers |
| **Secrets** | Sealed Secrets | Key Vault |
| **Observability** | Prometheus / Grafana / Loki | Azure Monitor |
| **Network** | Traefik + NetworkPolicies | NSGs + NetworkPolicies |
| **GitOps** | ArgoCD | ArgoCD |

---

## 📸 Key Screenshots

### LLM Guard — Prompt Injection Blocked
![LLM Guard Blocked](docs/demo/screenshots/llmguard-prompt-injection-blocked.png)
*LLM Guard intercepting a prompt injection attempt (OWASP LLM01)*

### Keycloak SSO — Zero Trust IAM
![Keycloak SSO](docs/demo/screenshots/keycloak-login-page.png)
*OIDC authentication via Keycloak realm AI-PLATFORM*

### Falco — Runtime Model Theft Detection
![Falco Dashboard](docs/demo/screenshots/grafana-falco-dashboard.png)
*Custom Grafana dashboard showing OWASP-LLM10 alerts from Falco*

### Trivy — Vulnerability Scanning
![Trivy Dashboard](docs/demo/screenshots/grafana-trivy-dashboard.png)
*8 Critical, 73 High, 206 Medium vulnerabilities tracked across AI images*

### RBAC — Group-Based Model Access
![RBAC Model Access](docs/demo/screenshots/openwebui-llmguard-private-group.png)
*LLM Guard Security Filter restricted to ai-security-team group*

### Azure Arc — Hybrid Management
![Azure Arc](docs/demo/screenshots/azure-arc-details.png)
*K3d cluster connected to Azure, 3 nodes, 24 cores*

> 📄 All 37 screenshots in [`docs/demo/DEMO-TEST.md`](docs/demo/DEMO-TEST.md)

---

## 🚀 Quick Start

### Prerequisites

- Azure account with free credits
- Azure CLI, Terraform, kubectl, Helm
- WSL2 with K3d cluster
- ngrok account (free)

### Phase 1: Azure Infrastructure

```bash
az login
cd terraform/azure
terraform init && terraform apply

az aks get-credentials --resource-group rg-ai-platform-dev --name aks-ai-platform
```

### Phase 2: K3d Cluster + Security Stack

```bash
# Create K3d cluster
k3d cluster create ai-security-platform --servers 1 --agents 2

# Deploy via ArgoCD (GitOps)
kubectl apply -f argocd/root-app.yaml
```

### Phase 3: Connect to Azure Arc

```bash
az connectedk8s connect --name k3d-ai-security-platform \
  --resource-group rg-ai-platform-dev

az k8s-extension create --name azurepolicy \
  --cluster-name k3d-ai-security-platform \
  --resource-group rg-ai-platform-dev \
  --cluster-type connectedClusters \
  --extension-type Microsoft.PolicyInsights
```

### Phase 4: Hybrid Connectivity

```bash
# Port-forward Ollama
kubectl port-forward svc/ollama -n ai-inference 11434:11434 &

# Start ngrok tunnel
./ngrok http 11434
```

---

## 📊 Cost Estimation

| Resource | SKU | Cost/Month | Notes |
|----------|-----|------------|-------|
| AKS Control Plane | Free | $0 | Free tier |
| AKS Node (1x B2s) | Standard_B2s | ~$15 | Stop when not in use |
| PostgreSQL Flexible | B_Standard_B1ms | ~$12 | Minimum viable |
| Key Vault | Standard | ~$1 | Per transaction |
| VNet, NSGs, Arc | — | $0 | Free |
| ngrok | Free tier | $0 | URL changes on restart |
| **Total** | | **~$28/month** | Stop AKS at night |

```bash
# Cost optimization
./scripts/azure-stop-all.sh   # Stop AKS when not in use
./scripts/azure-start-all.sh  # Start when needed
```

---

## 📁 Repository Structure

```
hybrid-ai-security-platform/
├── terraform/azure/              # Azure infrastructure (IaC)
├── argocd/                       # GitOps — App of Apps
│   ├── root-app.yaml
│   └── applications/
│       └── openwebui/
├── scripts/                      # Start/stop, cost optimization
├── docs/
│   ├── demo/
│   │   ├── DEMO-TEST.md          # ⭐ 12/12 tests, 37 screenshots
│   │   └── screenshots/          # All evidence
│   ├── adr/                      # Architecture Decision Records
│   ├── images/                   # Guide screenshots
│   ├── GUIDE-AZURE-*.md          # Azure setup guides
│   ├── GUIDE-DEPLOIEMENT.md
│   └── GUIDE-GITOPS-ARGOCD.md
└── README.md
```

---

## 📝 Architecture Decision Records

| ADR | Title | Status |
|-----|-------|--------|
| [ADR-001](docs/adr/ADR-001-hybrid-architecture.md) | Hybrid Architecture | ✅ Accepted |
| [ADR-002](docs/adr/ADR-002-azure-managed-services.md) | Azure Managed Services | ✅ Accepted |
| [ADR-007](docs/ADR-007-HYBRID-CONNECTIVITY-NGROK.md) | Hybrid Connectivity (ngrok) | ✅ Accepted |

---

## 🎓 Skills Demonstrated

- **AI Security**: OWASP LLM Top 10 coverage, LLM Guard guardrails, prompt injection detection
- **Zero Trust IAM**: Keycloak OIDC/SSO, group-based RBAC, model access control
- **Azure**: AKS, Arc, Policy, Defender, Key Vault, PostgreSQL Flexible, VNet
- **Kubernetes Security**: Falco (runtime), Kyverno (policies), Trivy (CVE scanning)
- **Observability**: Prometheus, Grafana dashboards, Loki log aggregation
- **Terraform**: Multi-module IaC for Azure infrastructure
- **GitOps**: ArgoCD, declarative deployments, app-of-apps pattern
- **AI/ML**: Ollama/Mistral 7B, RAG pipeline with Qdrant, embeddings
- **Hybrid Networking**: ngrok tunnels, Traefik ingress, private endpoints

---

## 🔗 Related

| Repository | Purpose |
|------------|---------|
| [ai-security-platform](https://github.com/Z3ROX-lab/ai-security-platform) | On-prem K3d — full AI security stack |
| **hybrid-ai-security-platform** | Azure extension + hybrid connectivity |

---

## 📄 License

MIT

---

*Last updated: February 28, 2026*
