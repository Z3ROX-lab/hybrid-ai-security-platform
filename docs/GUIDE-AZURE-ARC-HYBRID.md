# 🔗 Guide Azure Arc - Connexion Hybride Kubernetes

## Vue d'ensemble

Ce guide documente la mise en place d'une architecture hybride Kubernetes utilisant **Azure Arc** pour gérer un cluster on-premises (K3d) depuis Azure Portal, aux côtés d'un cluster AKS natif.

## 🎯 Objectif

Avoir une **vue unifiée** de tous nos clusters Kubernetes dans Azure Portal, qu'ils soient :
- Dans le cloud Azure (AKS)
- On-premises / local (K3d via Azure Arc)

---

## 📐 Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                     │
│                              AZURE CLOUD                                            │
│                                                                                     │
│  ┌─────────────────────────────────────────────────────────────────────────────┐   │
│  │                         AZURE PORTAL                                         │   │
│  │                    (Gestion unifiée)                                         │   │
│  │                                                                              │   │
│  │   ┌─────────────────┐              ┌─────────────────┐                      │   │
│  │   │  Azure Policy   │              │  Azure Monitor  │                      │   │
│  │   │  (Governance)   │              │  (Optionnel)    │                      │   │
│  │   └────────┬────────┘              └────────┬────────┘                      │   │
│  │            │                                │                               │   │
│  │            ▼                                ▼                               │   │
│  │   ┌─────────────────────────────────────────────────────────────────┐      │   │
│  │   │              RESOURCE GROUP: rg-ai-platform-dev                  │      │   │
│  │   │                                                                  │      │   │
│  │   │  ┌──────────────────┐         ┌──────────────────┐              │      │   │
│  │   │  │  aks-ai-platform │         │ k3d-ai-security- │              │      │   │
│  │   │  │                  │         │ platform         │              │      │   │
│  │   │  │  Type: AKS       │         │ Type: Azure Arc  │              │      │   │
│  │   │  │  (Natif Azure)   │         │ (Connected)      │              │      │   │
│  │   │  └──────────────────┘         └────────┬─────────┘              │      │   │
│  │   │                                        │                        │      │   │
│  │   │  ┌──────────────────┐                  │                        │      │   │
│  │   │  │ Services Managés │                  │                        │      │   │
│  │   │  │ • PostgreSQL     │                  │                        │      │   │
│  │   │  │ • Key Vault      │                  │ HTTPS (443)            │      │   │
│  │   │  │ • Log Analytics  │                  │ (Outbound only)        │      │   │
│  │   │  └──────────────────┘                  │                        │      │   │
│  │   └────────────────────────────────────────┼────────────────────────┘      │   │
│  │                                            │                               │   │
│  └────────────────────────────────────────────┼───────────────────────────────┘   │
│                                               │                                    │
└───────────────────────────────────────────────┼────────────────────────────────────┘
                                                │
                                                │ Internet (HTTPS)
                                                │ Pas de VPN requis !
                                                │
┌───────────────────────────────────────────────┼────────────────────────────────────┐
│                                               │                                    │
│                           ON-PREMISES (Ton laptop)                                 │
│                                               │                                    │
│  ┌────────────────────────────────────────────┼───────────────────────────────┐   │
│  │                                            ▼                               │   │
│  │                    K3D CLUSTER: ai-security-platform                       │   │
│  │                                                                            │   │
│  │   ┌──────────────────────────────────────────────────────────────────┐    │   │
│  │   │  NAMESPACE: azure-arc                                             │    │   │
│  │   │                                                                   │    │   │
│  │   │  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐   │    │   │
│  │   │  │ arc-agent       │  │ arc-controller  │  │ azure-policy    │   │    │   │
│  │   │  │ (Connexion)     │  │ (Management)    │  │ (Governance)    │   │    │   │
│  │   │  └─────────────────┘  └─────────────────┘  └─────────────────┘   │    │   │
│  │   └──────────────────────────────────────────────────────────────────┘    │   │
│  │                                                                            │   │
│  │   ┌──────────────────────────────────────────────────────────────────┐    │   │
│  │   │  TES WORKLOADS                                                    │    │   │
│  │   │                                                                   │    │   │
│  │   │  • Open WebUI        • Keycloak         • Prometheus             │    │   │
│  │   │  • Ollama + Mistral  • Kyverno          • Grafana                │    │   │
│  │   │  • RAG API           • Falco            • Loki                   │    │   │
│  │   │  • LLM Guard         • Trivy            • PostgreSQL (CNPG)      │    │   │
│  │   └──────────────────────────────────────────────────────────────────┘    │   │
│  │                                                                            │   │
│  │   Nodes: 3 (1 server + 2 agents)                                          │   │
│  │   Version: K3s 1.29.0                                                      │   │
│  │                                                                            │   │
│  └────────────────────────────────────────────────────────────────────────────┘   │
│                                                                                    │
└────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Comment ça marche ?

### Flux de communication

```
┌─────────────────┐                              ┌─────────────────┐
│   Azure Portal  │                              │   K3d Cluster   │
│                 │                              │                 │
│  • Voir status  │◄────── HTTPS (443) ─────────│  arc-agent      │
│  • Policies     │        Outbound only         │  (dans le       │
│  • Monitoring   │        Pas d'inbound !       │   cluster)      │
│                 │                              │                 │
└─────────────────┘                              └─────────────────┘

L'agent Arc DANS le cluster initie la connexion vers Azure.
→ Pas besoin d'ouvrir de ports entrants !
→ Pas besoin de VPN !
→ Fonctionne derrière un NAT/firewall !
```

### Ce que fait l'agent Arc

| Fonction | Description |
|----------|-------------|
| **Heartbeat** | Envoie le status du cluster toutes les 5 min |
| **Inventory** | Liste des nodes, pods, services |
| **Policy sync** | Télécharge et applique les Azure Policies |
| **Metrics** | Envoie les métriques (si Monitor activé) |
| **GitOps** | Peut déployer depuis Git (si configuré) |

### Sécurité

```
┌─────────────────────────────────────────────────────────────────┐
│  SÉCURITÉ DE LA CONNEXION ARC                                   │
│                                                                 │
│  ✅ Communication sortante uniquement (HTTPS 443)               │
│  ✅ Authentification par certificat (Managed Identity)          │
│  ✅ Pas d'accès entrant à ton réseau                           │
│  ✅ Azure ne peut PAS exécuter de commandes dans ton cluster   │
│  ✅ Données chiffrées en transit (TLS 1.2+)                    │
│                                                                 │
│  Azure Arc = "Pull model" (le cluster tire les infos)          │
│  PAS un "Push model" (Azure ne pousse rien)                    │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📋 Ce qu'on a déployé

### 1. Infrastructure Azure (Terraform)

| Ressource | Nom | Usage |
|-----------|-----|-------|
| Resource Group | `rg-ai-platform-dev` | Conteneur |
| VNet | `vnet-ai-platform` | Réseau (10.0.0.0/16) |
| AKS | `aks-ai-platform` | Cluster Azure natif |
| PostgreSQL | `psql-ai-platform-91vaoc` | Base de données managée |
| Key Vault | `kv-ai-platform-91vaoc` | Secrets |
| Log Analytics | `law-ai-platform-91vaoc` | Logs/Monitoring |
| NSG | `nsg-aks` | Firewall |
| Private DNS | `privatelink.postgres...` | DNS privé PostgreSQL |

### 2. Azure Arc (CLI)

| Ressource | Nom | Usage |
|-----------|-----|-------|
| Connected Cluster | `k3d-ai-security-platform` | K3d visible dans Azure |
| Extension | `azurepolicy` | Governance centralisée |

### 3. Applications (kubectl)

| App | Cluster | Namespace |
|-----|---------|-----------|
| ArgoCD | AKS | `argocd` |
| Arc agents | K3d | `azure-arc` |
| Azure Policy | K3d | `kube-system` |

---

## 🛠️ Commandes utilisées

### Prérequis

```bash
# Installer Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Se connecter
az login --use-device-code

# Installer les extensions Arc
az extension add --name connectedk8s --upgrade
az extension add --name k8s-extension --upgrade

# Enregistrer les providers
az provider register --namespace Microsoft.Kubernetes --wait
az provider register --namespace Microsoft.KubernetesConfiguration --wait
```

### Déploiement Terraform

```bash
cd terraform/azure
terraform init
terraform plan
terraform apply
```

### Connexion Arc

```bash
# S'assurer d'être sur le bon contexte
kubectl config use-context k3d-ai-security-platform

# Connecter le cluster à Azure Arc
az connectedk8s connect \
  --name k3d-ai-security-platform \
  --resource-group rg-ai-platform-dev \
  --location francecentral

# Vérifier la connexion
kubectl get pods -n azure-arc
```

### Azure Policy

```bash
# Activer Azure Policy sur le cluster Arc
az k8s-extension create \
  --name azurepolicy \
  --cluster-name k3d-ai-security-platform \
  --resource-group rg-ai-platform-dev \
  --cluster-type connectedClusters \
  --extension-type Microsoft.PolicyInsights

# Vérifier
kubectl get pods -n kube-system | grep azure-policy
```

---

## 💰 Coûts

### Ce qui est GRATUIT

| Service | Coût |
|---------|------|
| Azure Arc | $0 |
| Azure Policy | $0 |
| Connexion Arc-enabled Kubernetes | $0 |

### Ce qui est PAYANT

| Service | Coût | Notes |
|---------|------|-------|
| AKS node (B2s_v2) | ~$30/mois | Stoppable |
| PostgreSQL (B1ms) | ~$15/mois | Stoppable |
| Key Vault | ~$1/mois | |
| Log Analytics | $0 | 5GB gratuit |

### Optimisation

```bash
# Stopper le soir (économise ~$1.50/heure)
./scripts/azure-stop-all.sh

# Relancer le matin
./scripts/azure-start-all.sh
```

---

## 🔍 Vérifications dans Azure Portal

### 1. Resource Group

```
Azure Portal → rg-ai-platform-dev
```

Tu vois toutes les ressources, dont :
- `aks-ai-platform` (Kubernetes service)
- `k3d-ai-security-platform` (Kubernetes - Azure Arc)

### 2. Cluster Arc

```
Azure Portal → k3d-ai-security-platform → Overview
```

| Info | Valeur attendue |
|------|-----------------|
| Status | Connected |
| Distribution | k3s |
| Kubernetes version | 1.29.0+k3s1 |
| Node count | 3 |

### 3. Extensions

```
Azure Portal → k3d-ai-security-platform → Extensions
```

| Extension | Status |
|-----------|--------|
| azurepolicy | Succeeded |

### 4. Policies

```
Azure Portal → k3d-ai-security-platform → Policies
```

Ici tu peux assigner des policies Kubernetes.

---

## 📊 Comparaison AKS vs Arc

| Critère | AKS (aks-ai-platform) | Arc (k3d-ai-security-platform) |
|---------|----------------------|--------------------------------|
| **Où ça tourne** | Azure | Ton laptop |
| **Control plane** | Managé par Azure | Toi (K3d) |
| **Coût compute** | ~$30/mois | $0 (ton laptop) |
| **Coût management** | Gratuit | Gratuit (Arc) |
| **Latence** | Cloud | Local |
| **Données sensibles** | ⚠️ Cloud | ✅ Reste local |
| **Disponibilité** | 24/7 (si payé) | Quand laptop allumé |

---

## 🔮 Prochaines étapes possibles

### 1. Assigner des Azure Policies

```
Azure Portal → Policy → Assign policy
Recherche: "Kubernetes"
```

Policies recommandées :
- "Kubernetes cluster should not allow privileged containers"
- "Kubernetes cluster pods should use specified labels"
- "Kubernetes clusters should not allow container privilege escalation"

### 2. Activer Azure Monitor (payant)

```bash
az k8s-extension create \
  --name azuremonitor-containers \
  --cluster-name k3d-ai-security-platform \
  --resource-group rg-ai-platform-dev \
  --cluster-type connectedClusters \
  --extension-type Microsoft.AzureMonitor.Containers
```

### 3. Activer GitOps via Arc

```bash
az k8s-configuration flux create \
  --name gitops-config \
  --cluster-name k3d-ai-security-platform \
  --resource-group rg-ai-platform-dev \
  --cluster-type connectedClusters \
  --url https://github.com/Z3ROX-lab/hybrid-ai-security-platform \
  --branch main \
  --kustomization name=infra path=./kubernetes
```

### 4. Tailscale pour connectivité apps

Si tu veux que les apps sur AKS communiquent avec K3d :
- Installer Tailscale sur les 2 clusters
- Créer un mesh VPN sécurisé

---

## ❓ FAQ

### Q: Si je stoppe AKS, Arc fonctionne toujours ?

**Oui !** Arc connecte K3d directement à Azure, pas via AKS. Ce sont 2 connexions indépendantes.

### Q: Arc a accès à mes données ?

**Non.** Arc envoie uniquement des métadonnées (status, métriques). Tes données applicatives restent dans ton cluster.

### Q: Puis-je déconnecter Arc ?

```bash
az connectedk8s delete \
  --name k3d-ai-security-platform \
  --resource-group rg-ai-platform-dev
```

### Q: Combien de clusters puis-je connecter ?

Illimité ! Tu peux connecter autant de clusters que tu veux, gratuitement.

---

## 📚 Ressources

- [Azure Arc for Kubernetes Documentation](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/)
- [Azure Policy for Kubernetes](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/policy-for-kubernetes)
- [Pricing - Azure Arc](https://azure.microsoft.com/en-us/pricing/details/azure-arc/)

---

## ✅ Checklist

```
[x] Compte Azure avec $200 crédits
[x] Budget alert configuré ($50)
[x] Infrastructure Terraform déployée
[x] AKS opérationnel
[x] ArgoCD installé sur AKS
[x] K3d connecté à Azure Arc
[x] Azure Policy extension installée
[x] Scripts start/stop créés
[x] Documentation complète
```

---

*Guide créé le 24/02/2026 - Projet hybrid-ai-security-platform*
*Auteur: Stéphane (Z3ROX) - Lead SecOps/Cloud Security Architect*
