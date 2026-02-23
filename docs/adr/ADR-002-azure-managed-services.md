# ADR-002: Services Managés Azure pour Architecture Hybride

## Status

**Accepted**

## Date

2026-02-23

## Context

Dans le cadre de notre architecture hybride AI Security Platform, nous devons choisir quels services Azure utiliser pour compléter notre cluster K3d on-premises. L'objectif est d'apprendre les services managés Azure tout en maintenant une architecture sécurisée et économique.

### Contraintes

- **Budget limité** : $200 de crédits gratuits pour 30 jours
- **Objectif d'apprentissage** : Maîtriser AKS, les services managés, et l'hybride
- **Sécurité** : Respecter les bonnes pratiques enterprise
- **Homelab** : Doit pouvoir être stoppé/démarré facilement

## Decision

Nous avons sélectionné les services Azure suivants pour notre architecture hybride :

### Services Compute

| Service | Choix | Justification |
|---------|-------|---------------|
| **AKS** | ✅ Retenu | Service Kubernetes managé, control plane gratuit |
| Azure Container Apps | ❌ Rejeté | Moins de contrôle, pas d'apprentissage K8s |
| Azure Container Instances | ❌ Rejeté | Pas adapté pour workloads complexes |
| Azure VMs | ❌ Rejeté | Gestion manuelle, pas cloud-native |

**Configuration AKS choisie :**
- SKU Tier: Free (control plane gratuit)
- Node Pool: 1x Standard_B2s_v2 (2 vCPU, 4GB RAM)
- Network Plugin: Azure CNI (meilleure intégration VNet)
- Network Policy: Calico (compatible avec notre K3d)
- Container Insights: Activé (monitoring intégré)

### Services Data

| Service | Choix | Justification |
|---------|-------|---------------|
| **PostgreSQL Flexible Server** | ✅ Retenu | Managé, backup auto, scaling facile |
| Azure SQL | ❌ Rejeté | Plus cher, pas compatible PostgreSQL |
| CosmosDB | ❌ Rejeté | Overkill pour notre use case |
| PostgreSQL Single Server | ❌ Rejeté | Deprecated par Microsoft |

**Configuration PostgreSQL choisie :**
- SKU: B_Standard_B1ms (1 vCPU, 2GB RAM, ~$15/mois)
- Version: 15
- Storage: 32GB
- Backup: 7 jours
- Réseau: Private endpoint (VNet integration)
- Databases: `langfuse`, `openwebui`

### Services Sécurité

| Service | Choix | Justification |
|---------|-------|---------------|
| **Key Vault** | ✅ Retenu | Gestion secrets, intégration AKS native |
| **Azure Arc** | ✅ Retenu | Gestion unifiée K3d + AKS |
| **Defender for Cloud** | ✅ Basic (gratuit) | Secure Score, recommandations |
| **Azure Policy** | ✅ Retenu (gratuit) | Governance multi-cluster |
| Managed HSM | ❌ Rejeté | Trop cher pour homelab |
| WAF/Front Door | ❌ Rejeté | Coût élevé (~$35+/mois) |

**Configuration Key Vault choisie :**
- SKU: Standard
- Soft Delete: 7 jours (minimum pour dev)
- Purge Protection: Désactivé (permet cleanup facile)
- Access: Via Managed Identity AKS

### Services Réseau

| Service | Choix | Justification |
|---------|-------|---------------|
| **VNet** | ✅ Retenu | Isolation réseau, gratuit |
| **NSG** | ✅ Retenu | Firewall L4, gratuit |
| **Private DNS Zone** | ✅ Retenu | Résolution PostgreSQL private |
| **Tailscale** | ✅ Retenu | Connectivité hybride gratuite |
| VPN Gateway | ❌ Rejeté | ~$140/mois, trop cher |
| ExpressRoute | ❌ Rejeté | Enterprise only, très cher |
| Azure Firewall | ❌ Rejeté | ~$900/mois, overkill |

**Configuration réseau choisie :**
```
VNet: 10.0.0.0/16
├── snet-aks:       10.0.1.0/24  (AKS nodes)
├── snet-data:      10.0.2.0/24  (PostgreSQL, delegated)
└── snet-endpoints: 10.0.3.0/24  (Private endpoints)

AKS Service CIDR: 172.16.0.0/16 (évite conflit avec VNet)
AKS DNS Service IP: 172.16.0.10
```

### Services Monitoring

| Service | Choix | Justification |
|---------|-------|---------------|
| **Log Analytics** | ✅ Retenu | 5GB gratuit/mois |
| **Container Insights** | ✅ Retenu | Intégré à AKS |
| **Azure Monitor** | ✅ Retenu | Métriques natives |
| Application Insights | ❌ Différé | À ajouter si besoin APM |

### Services Identity

| Service | Choix | Justification |
|---------|-------|---------------|
| **Entra ID** | ✅ Retenu (gratuit) | Identity provider Azure |
| **Managed Identity** | ✅ Retenu | Auth AKS → Key Vault |
| Keycloak (on-prem) | ✅ Conservé | Master IdP, fédéré avec Entra |

## Architecture Résultante

```
┌─────────────────────────────────────────────────────────────────────────────────────────┐
│                              HYBRID AI SECURITY PLATFORM                                 │
│                                                                                         │
│  ┌─────────────────────────────────────┐    ┌─────────────────────────────────────┐    │
│  │  ON-PREMISES (K3d)                  │    │  AZURE                              │    │
│  │                                     │    │                                     │    │
│  │  ┌─────────────────────────────┐    │    │  ┌─────────────────────────────┐    │    │
│  │  │ AI WORKLOADS                │    │    │  │ AKS CLUSTER                 │    │    │
│  │  │ • Ollama + Mistral          │    │    │  │ • 1x Standard_B2s_v2        │    │    │
│  │  │ • RAG API                   │    │    │  │ • Azure CNI + Calico        │    │    │
│  │  │ • LLM Guard                 │    │    │  │ • Container Insights        │    │    │
│  │  │ • Open WebUI (internal)     │    │    │  │                             │    │    │
│  │  │ • Qdrant                    │    │    │  │ Workloads:                  │    │    │
│  │  └─────────────────────────────┘    │    │  │ • Open WebUI (public)       │    │    │
│  │                                     │    │  │ • Langfuse                  │    │    │
│  │  ┌─────────────────────────────┐    │    │  └─────────────────────────────┘    │    │
│  │  │ DATA (Sensitive C3-C4)      │    │    │                                     │    │
│  │  │ • PostgreSQL (CNPG)         │    │    │  ┌─────────────────────────────┐    │    │
│  │  │ • Documents RAG privés      │    │    │  │ MANAGED SERVICES            │    │    │
│  │  └─────────────────────────────┘    │    │  │ • PostgreSQL Flexible ☁️    │    │    │
│  │                                     │    │  │ • Key Vault ☁️              │    │    │
│  │  ┌─────────────────────────────┐    │    │  │ • Log Analytics ☁️          │    │    │
│  │  │ SECURITY                    │    │    │  └─────────────────────────────┘    │    │
│  │  │ • Keycloak (Master IdP)     │    │    │                                     │    │
│  │  │ • Falco                     │    │    │  ┌─────────────────────────────┐    │    │
│  │  │ • Kyverno                   │    │    │  │ SECURITY                    │    │    │
│  │  │ • Sealed Secrets            │    │    │  │ • Defender for Cloud ☁️     │    │    │
│  │  └─────────────────────────────┘    │    │  │ • Azure Policy ☁️           │    │    │
│  │                                     │    │  │ • Entra ID ☁️               │    │    │
│  │  ┌─────────────────────────────┐    │    │  └─────────────────────────────┘    │    │
│  │  │ OBSERVABILITY               │    │    │                                     │    │
│  │  │ • Prometheus                │    │    │  ┌─────────────────────────────┐    │    │
│  │  │ • Grafana                   │    │    │  │ NETWORKING                  │    │    │
│  │  │ • Loki                      │    │    │  │ • VNet 10.0.0.0/16          │    │    │
│  │  └─────────────────────────────┘    │    │  │ • NSG (HTTP/HTTPS)          │    │    │
│  │                                     │    │  │ • Private DNS Zone          │    │    │
│  │  ┌─────────────────────────────┐    │    │  └─────────────────────────────┘    │    │
│  │  │ AZURE ARC AGENTS            │    │    │                                     │    │
│  │  │ • Policy sync               │    │    │                                     │    │
│  │  │ • Monitor metrics           │    │    │                                     │    │
│  │  │ • Defender scanning         │    │    │                                     │    │
│  │  └─────────────────────────────┘    │    │                                     │    │
│  │                                     │    │                                     │    │
│  └─────────────────────────────────────┘    └─────────────────────────────────────┘    │
│                    │                                        │                          │
│                    │            TAILSCALE MESH              │                          │
│                    └────────────────────────────────────────┘                          │
│                                                                                         │
│  ┌─────────────────────────────────────────────────────────────────────────────────┐   │
│  │  AZURE PORTAL - UNIFIED MANAGEMENT                                               │   │
│  │  • 2 clusters visibles (K3d via Arc + AKS natif)                                │   │
│  │  • Policies unifiées                                                             │   │
│  │  • Métriques centralisées                                                        │   │
│  │  • Secure Score global                                                           │   │
│  └─────────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────┘
```

## Flux de Données

### Authentification

```
User → Open WebUI (AKS) → Keycloak (K3d) ←→ Entra ID (Azure)
                              ↓
                    OIDC Federation
```

### Requêtes LLM

```
User → Open WebUI (AKS) → Tailscale → Ollama (K3d)
                              ↓
              LLM Guard → RAG API → Qdrant
```

### Stockage Secrets

```
AKS Pod → Managed Identity → Key Vault → Secret
              (automatic)      (RBAC)
```

## Coûts

### Coûts Mensuels (24/7)

| Service | SKU | Coût/mois |
|---------|-----|-----------|
| AKS Control Plane | Free | $0 |
| AKS Node (B2s_v2) | Standard_B2s_v2 | ~$30 |
| PostgreSQL Flexible | B_Standard_B1ms | ~$15 |
| Key Vault | Standard | ~$1 |
| Log Analytics | 5GB free | $0 |
| VNet, NSG, DNS | - | $0 |
| Azure Arc | - | $0 |
| Defender Basic | - | $0 |
| Azure Policy | - | $0 |
| **TOTAL** | | **~$46/mois** |

### Optimisation des Coûts

```bash
# Stop AKS le soir (économise ~$1/heure)
az aks stop --resource-group rg-ai-platform-dev --name aks-ai-platform

# Start AKS le matin
az aks start --resource-group rg-ai-platform-dev --name aks-ai-platform
```

**Coût optimisé (4h/jour)** : ~$15-20/mois

### Utilisation des Crédits

| Scénario | Durée avec $200 |
|----------|-----------------|
| AKS 24/7 | ~4 mois |
| AKS 4h/jour | ~10-12 mois |
| Arc seul (pas d'AKS) | Illimité ($0) |

## Comparaison avec Alternatives Cloud

| Critère | Notre choix (Azure) | AWS Equivalent | GCP Equivalent |
|---------|---------------------|----------------|----------------|
| Kubernetes | AKS (Free tier) | EKS ($73/mois control plane) | GKE (Free tier) |
| PostgreSQL | Flexible Server | RDS PostgreSQL | Cloud SQL |
| Secrets | Key Vault | Secrets Manager | Secret Manager |
| Hybrid | Azure Arc | AWS Outposts (très cher) | Anthos (complexe) |
| Identity | Entra ID | IAM + Cognito | Cloud Identity |

**Justification du choix Azure :**
- Azure Arc est unique pour la gestion hybride
- AKS Free tier (pas de frais control plane)
- Intégration native avec Entra ID
- Terraform provider mature

## Conséquences

### Positives

1. **Apprentissage complet** : AKS, PostgreSQL managé, Key Vault, Arc
2. **Architecture enterprise** : Patterns réutilisables en production
3. **Coût maîtrisé** : Free tiers et optimisation possible
4. **Sécurité** : Private endpoints, Managed Identity, Defender
5. **Observabilité** : Container Insights + notre stack Prometheus/Grafana
6. **Portabilité** : Kubernetes standard, pas de lock-in

### Négatives

1. **Complexité initiale** : Plusieurs services à configurer
2. **Coût non-nul** : ~$46/mois si AKS tourne 24/7
3. **Dépendance Azure** : Arc et certains services sont Azure-specific
4. **Latence** : Communication K3d ↔ AKS via Tailscale

### Risques et Mitigations

| Risque | Probabilité | Impact | Mitigation |
|--------|-------------|--------|------------|
| Dépassement budget | Moyenne | Moyen | Budget alert à $50, stop AKS |
| Changement pricing Azure | Faible | Moyen | Terraform permet migration |
| Panne Tailscale | Faible | Moyen | Fallback sur endpoints publics |
| Complexité maintenance | Moyenne | Faible | Documentation, IaC |

## Évolutions Futures

### Phase 2 (après validation)

- [ ] Activer Defender for Containers (~$7/mois)
- [ ] Ajouter Application Gateway avec WAF
- [ ] Configurer Backup Vault pour PostgreSQL
- [ ] Implémenter GitOps avec Flux v2 sur AKS

### Phase 3 (production-ready)

- [ ] Upgrade AKS vers Standard tier (SLA)
- [ ] Multi-zone PostgreSQL (HA)
- [ ] Azure Front Door avec WAF
- [ ] Private AKS cluster

## Références

- [AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Azure Arc for Kubernetes](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/)
- [PostgreSQL Flexible Server](https://docs.microsoft.com/en-us/azure/postgresql/flexible-server/)
- [Key Vault Best Practices](https://docs.microsoft.com/en-us/azure/key-vault/general/best-practices)
- [Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/)

## Décision

Nous adoptons l'architecture hybride décrite ci-dessus avec :

- **AKS** pour les workloads publics
- **PostgreSQL Flexible** pour les données Azure
- **Key Vault** pour les secrets
- **Azure Arc** pour la gestion unifiée
- **Tailscale** pour la connectivité hybride

Cette architecture permet d'apprendre les services managés Azure tout en maintenant nos workloads sensibles on-premises, avec un coût optimisé pour un environnement homelab.

---

*Auteur : Stéphane (Z3ROX) - Lead SecOps/Cloud Security Architect*
*Reviewers : -* 
*Approuvé le : 2026-02-23*
