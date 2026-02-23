# ADR-001: Hybrid Architecture with Azure Arc

## Status

**Accepted**

## Date

2026-02-21

## Context

We have an existing on-premises AI Security Platform running on K3d with comprehensive security coverage (OWASP LLM Top 10). We want to:

1. **Learn Azure**: Gain hands-on experience with AKS, VNet, managed services
2. **Demonstrate hybrid capabilities**: Show enterprise-grade multi-cluster management
3. **Minimize costs**: Use free tiers and optimize spending
4. **Maintain security posture**: Unified governance across both environments

## Decision

We will implement a **hybrid architecture** with:

### 1. Two Kubernetes Clusters

| Cluster | Location | Purpose | Data Classification |
|---------|----------|---------|---------------------|
| K3d | On-premises | Sensitive workloads | C3-C4 |
| AKS | Azure | Public workloads | C1-C2 |

### 2. Azure Arc for Unified Management

Azure Arc connects the on-prem K3d cluster to Azure control plane, enabling:
- Single pane of glass in Azure Portal
- Azure Policy enforcement on K3d
- Azure Monitor metrics and logs from K3d
- Defender for Cloud security posture

### 3. Tailscale for Connectivity

Instead of expensive Azure VPN Gateway (~$140/month), we use Tailscale:
- Zero-cost mesh VPN
- Easy setup on both clusters
- Secure WireGuard-based connectivity

### 4. Infrastructure as Code

| Layer | Tool | Target |
|-------|------|--------|
| Azure Infrastructure | Terraform | VNet, AKS, PostgreSQL, Key Vault |
| K3d Infrastructure | Terraform | Existing (ai-security-platform repo) |
| Applications (both) | ArgoCD | GitOps deployment |

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        HYBRID ARCHITECTURE                               │
│                                                                         │
│  ┌─────────────────────────────┐    ┌─────────────────────────────┐    │
│  │  K3D (On-Premises)          │    │  AKS (Azure)                │    │
│  │                             │    │                             │    │
│  │  Sensitive Workloads:       │    │  Public Workloads:          │    │
│  │  • Ollama + Mistral (LLM)   │    │  • Open WebUI (public)      │    │
│  │  • RAG with private docs    │    │  • Qdrant (public vectors)  │    │
│  │  • PostgreSQL (CNPG)        │    │  • PostgreSQL Flexible ☁️   │    │
│  │  • Keycloak (master IdP)    │    │  • Key Vault ☁️             │    │
│  │                             │    │                             │    │
│  │  Security Stack:            │    │  Azure Native Security:     │    │
│  │  • Falco                    │    │  • Defender for Cloud       │    │
│  │  • Kyverno                  │    │  • Azure Policy             │    │
│  │  • LLM Guard                │    │  • Azure Monitor            │    │
│  │                             │    │                             │    │
│  │  ┌───────────────────────┐  │    │  ┌───────────────────────┐  │    │
│  │  │ Azure Arc Agent       │  │    │  │ Native Integration    │  │    │
│  │  └───────────────────────┘  │    │  └───────────────────────┘  │    │
│  │                             │    │                             │    │
│  │  ArgoCD (master)            │    │  ArgoCD (syncs from Git)    │    │
│  └─────────────────────────────┘    └─────────────────────────────┘    │
│                │                                │                       │
│                └──────────── Tailscale ─────────┘                       │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐   │
│  │  AZURE PORTAL - Unified Management                               │   │
│  │  • Both clusters visible                                         │   │
│  │  • Unified policy enforcement                                    │   │
│  │  • Centralized monitoring                                        │   │
│  │  • Single Secure Score                                           │   │
│  └─────────────────────────────────────────────────────────────────┘   │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Cost Analysis

### Option A: Azure Arc Only (Zero Cost)

| Component | Cost |
|-----------|------|
| Azure Arc | $0 |
| Azure Policy (via Arc) | $0 |
| Azure Monitor (5GB free) | $0 |
| Defender Basic | $0 |
| **Total** | **$0/month** |

### Option B: Arc + Azure Resources (Chosen)

| Component | SKU | Cost/Month |
|-----------|-----|------------|
| AKS Control Plane | Free | $0 |
| AKS Node (1x B2s) | Standard_B2s | ~$30 |
| PostgreSQL Flexible | B_Standard_B1ms | ~$15 |
| Key Vault | Standard | ~$1 |
| VNet, NSGs | - | $0 |
| Azure Arc | - | $0 |
| Azure Monitor (5GB) | - | $0 |
| Tailscale | Free tier | $0 |
| **Total (24/7)** | | **~$46/month** |
| **Total (optimized)** | | **~$15-20/month** |

> 💡 Stop AKS at night to reduce costs by 60-70%

## Consequences

### Positive

1. **Learning**: Hands-on experience with Azure managed services
2. **Portfolio**: Demonstrates enterprise hybrid cloud skills
3. **Cost-effective**: Uses free tiers and can be optimized
4. **Unified management**: Single view of both clusters in Azure Portal
5. **Flexibility**: Can scale Azure resources as needed

### Negative

1. **Complexity**: Two clusters to manage instead of one
2. **Connectivity**: Requires Tailscale setup and maintenance
3. **Cost**: Non-zero cost for Azure resources (mitigated by free credits)
4. **Latency**: Cross-cluster communication adds latency

### Risks

| Risk | Mitigation |
|------|------------|
| Cost overrun | Stop AKS when not in use; set budget alerts |
| Connectivity issues | Tailscale is reliable; fallback to public endpoints |
| Credential sprawl | Centralize in Key Vault; federate with Keycloak |

## Alternatives Considered

### 1. Azure Arc Only (No AKS)

**Rejected because**: Doesn't provide hands-on AKS experience, which is a primary goal.

### 2. Full Azure (No K3d)

**Rejected because**: 
- Higher cost
- Loses on-prem experience
- Doesn't demonstrate hybrid architecture

### 3. AWS/GCP Instead of Azure

**Rejected because**: Azure Arc provides unique hybrid management capabilities not easily replicated in other clouds.

### 4. Azure VPN Gateway Instead of Tailscale

**Rejected because**: 
- $140/month is too expensive for a learning project
- Tailscale provides equivalent security with zero cost

## Implementation Plan

| Phase | Duration | Tasks |
|-------|----------|-------|
| 1 | Day 1 (3-4h) | Deploy Azure infrastructure with Terraform |
| 2 | Day 2 (2-3h) | Install ArgoCD, deploy apps on AKS |
| 3 | Day 3 (2-3h) | Connect K3d to Arc, setup Tailscale |
| 4 | Day 4 (2-3h) | Security config, documentation |

**Total**: ~10-15 hours over 1 weekend or 3-4 evenings

## References

- [Azure Arc documentation](https://docs.microsoft.com/en-us/azure/azure-arc/)
- [AKS documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Tailscale Kubernetes](https://tailscale.com/kb/1185/kubernetes/)
- [ai-security-platform repository](https://github.com/Z3ROX-lab/ai-security-platform)
