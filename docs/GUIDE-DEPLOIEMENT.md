# 🚀 Guide de Déploiement Hybride Azure

## Vue d'ensemble

Ce guide te permet de déployer une architecture hybride connectant ton cluster K3d on-prem à Azure avec AKS, PostgreSQL managé, et Azure Arc.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ARCHITECTURE CIBLE                                    │
│                                                                             │
│  ┌─────────────────────────────┐    ┌─────────────────────────────┐        │
│  │  K3D (On-Prem)              │    │  AKS (Azure)                │        │
│  │                             │    │                             │        │
│  │  • Open WebUI               │    │  • Open WebUI (public)      │        │
│  │  • Ollama + Mistral         │    │  • PostgreSQL Flexible ☁️   │        │
│  │  • RAG API + LLM Guard      │    │  • Key Vault ☁️             │        │
│  │  • PostgreSQL (CNPG)        │    │  • Azure Monitor ☁️         │        │
│  │  • Keycloak                 │    │                             │        │
│  │                             │    │                             │        │
│  │  + Azure Arc agents         │    │  Natif Azure                │        │
│  └─────────────────────────────┘    └─────────────────────────────┘        │
│                │                                │                          │
│                └──────────── Tailscale ─────────┘                          │
│                                                                             │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  AZURE PORTAL - Vue unifiée des 2 clusters                          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 💰 Coûts estimés

| Ressource | Coût/mois | Notes |
|-----------|-----------|-------|
| AKS (1x B2s) | ~$30 | Stoppable pour économiser |
| PostgreSQL (B1ms) | ~$15 | |
| Key Vault | ~$1 | |
| Log Analytics | $0 | 5GB gratuit |
| Azure Arc | $0 | Gratuit |
| VNet, NSG | $0 | Gratuit |
| **TOTAL** | **~$46/mois** | Ou ~$15-20 si tu stoppes AKS |

> 💡 **$200 de crédits gratuits** pendant 30 jours avec un nouveau compte Azure !

---

## Prérequis

### Logiciels requis

```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# kubectl (si pas déjà installé)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Helm (si pas déjà installé)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Compte Azure

1. Va sur https://azure.microsoft.com/fr-fr/free/
2. Crée un compte (ou connecte-toi avec GitHub)
3. Active les $200 de crédits gratuits
4. Configure une alerte budget (voir section suivante)

---

## Phase 1 : Préparation Azure

### 1.1 Créer une alerte budget

**Important pour éviter les mauvaises surprises !**

1. Va dans Azure Portal → Recherche "Budgets"
2. Clique **+ Add**
3. Configure :
   - **Name** : `ai-platform-budget`
   - **Reset period** : Monthly
   - **Amount** : $50
4. Clique **Next**, puis :
   - **Type** : Actual
   - **% of budget** : 80
   - **Email** : ton@email.com
5. Clique **Create**

### 1.2 Connexion Azure CLI

```bash
# Connexion (ouvre le navigateur)
az login

# OU si WSL ne peut pas ouvrir le navigateur :
az login --use-device-code

# Vérifie la connexion
az account show
```

---

## Phase 2 : Déploiement Infrastructure Azure (Terraform)

### 2.1 Cloner le repo

```bash
cd ~/projects  # ou ton dossier de travail
git clone https://github.com/Z3ROX-lab/hybrid-ai-security-platform.git
cd hybrid-ai-security-platform
```

### 2.2 Configurer Terraform

```bash
cd terraform/azure

# Copier le fichier de variables
cp terraform.tfvars.example terraform.tfvars

# (Optionnel) Éditer les variables si besoin
# nano terraform.tfvars
```

### 2.3 Déployer l'infrastructure

```bash
# Initialiser Terraform
terraform init

# Voir ce qui va être créé
terraform plan

# Déployer (confirme avec "yes")
terraform apply
```

⏱️ **Durée : ~10-15 minutes** (AKS prend du temps)

### 2.4 Ressources créées

| Ressource | Nom | Description |
|-----------|-----|-------------|
| Resource Group | `rg-ai-platform-dev` | Conteneur de toutes les ressources |
| VNet | `vnet-ai-platform` | Réseau virtuel (10.0.0.0/16) |
| Subnet AKS | `snet-aks` | 10.0.1.0/24 |
| Subnet Data | `snet-data` | 10.0.2.0/24 (PostgreSQL) |
| Subnet Endpoints | `snet-endpoints` | 10.0.3.0/24 |
| NSG | `nsg-aks` | Firewall rules |
| AKS | `aks-ai-platform` | Cluster Kubernetes |
| PostgreSQL | `psql-ai-platform-xxx` | Base de données managée |
| Key Vault | `kv-ai-platform-xxx` | Secrets |
| Log Analytics | `law-ai-platform-xxx` | Monitoring |

### 2.5 Récupérer les credentials AKS

```bash
# Commande fournie par Terraform output
az aks get-credentials --resource-group rg-ai-platform-dev --name aks-ai-platform

# Vérifier la connexion
kubectl get nodes
```

---

## Phase 3 : ArgoCD sur AKS

### 3.1 Installer ArgoCD

```bash
# Créer le namespace
kubectl create namespace argocd

# Installer ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Attendre que ce soit prêt
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

### 3.2 Récupérer le mot de passe admin

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo  # Nouvelle ligne
```

### 3.3 Accéder à ArgoCD (port-forward)

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Puis ouvre https://localhost:8080 (accepte le certificat auto-signé)
- **Username** : admin
- **Password** : (celui récupéré ci-dessus)

---

## Phase 4 : Connecter K3d à Azure Arc

### 4.1 Prérequis

```bash
# S'assurer que kubectl pointe vers K3d
kubectl config use-context k3d-ai-platform

# Vérifier
kubectl config current-context
# Doit afficher: k3d-ai-platform
```

### 4.2 Installer les extensions Azure CLI

```bash
az extension add --name connectedk8s --upgrade
az extension add --name k8s-extension --upgrade
az extension add --name k8s-configuration --upgrade
```

### 4.3 Enregistrer les providers

```bash
az provider register --namespace Microsoft.Kubernetes --wait
az provider register --namespace Microsoft.KubernetesConfiguration --wait
az provider register --namespace Microsoft.ExtendedLocation --wait
```

### 4.4 Connecter K3d à Azure Arc

```bash
az connectedk8s connect \
  --name k3d-ai-platform \
  --resource-group rg-ai-platform-dev \
  --location francecentral
```

### 4.5 Vérifier la connexion

```bash
# Voir les pods Arc
kubectl get pods -n azure-arc

# Voir dans Azure
az connectedk8s show --name k3d-ai-platform --resource-group rg-ai-platform-dev
```

---

## Phase 5 : Extensions Azure Arc (Optionnel)

### 5.1 Azure Policy (Gratuit)

```bash
az k8s-extension create \
  --name azurepolicy \
  --cluster-name k3d-ai-platform \
  --resource-group rg-ai-platform-dev \
  --cluster-type connectedClusters \
  --extension-type Microsoft.PolicyInsights
```

### 5.2 Azure Monitor (5GB gratuit/mois)

```bash
# Récupérer l'ID du Log Analytics
LAW_ID=$(az monitor log-analytics workspace show \
  --resource-group rg-ai-platform-dev \
  --workspace-name law-ai-platform-* \
  --query id -o tsv)

# Installer Container Insights
az k8s-extension create \
  --name azuremonitor-containers \
  --cluster-name k3d-ai-platform \
  --resource-group rg-ai-platform-dev \
  --cluster-type connectedClusters \
  --extension-type Microsoft.AzureMonitor.Containers \
  --configuration-settings "logAnalyticsWorkspaceResourceID=$LAW_ID"
```

### 5.3 Defender (Basic gratuit)

```bash
az k8s-extension create \
  --name microsoft.azuredefender.kubernetes \
  --cluster-name k3d-ai-platform \
  --resource-group rg-ai-platform-dev \
  --cluster-type connectedClusters \
  --extension-type microsoft.azuredefender.kubernetes
```

---

## 💰 Gestion des coûts

### Stopper AKS (économise ~$1/heure)

```bash
# Stopper
az aks stop --resource-group rg-ai-platform-dev --name aks-ai-platform

# Vérifier l'état
az aks show --resource-group rg-ai-platform-dev --name aks-ai-platform --query "powerState.code"
```

### Démarrer AKS

```bash
# Démarrer
az aks start --resource-group rg-ai-platform-dev --name aks-ai-platform

# Récupérer les credentials
az aks get-credentials --resource-group rg-ai-platform-dev --name aks-ai-platform
```

### Voir les coûts actuels

```bash
# Dans Azure Portal : Cost Management → Cost analysis
# Ou via CLI :
az consumption usage list --query "[].{Name:name, Cost:pretaxCost}" -o table
```

---

## 🧹 Nettoyage complet

### Supprimer toute l'infrastructure Azure

```bash
cd terraform/azure

# Détruire toutes les ressources
terraform destroy

# Confirmer avec "yes"
```

### Déconnecter K3d d'Azure Arc

```bash
az connectedk8s delete --name k3d-ai-platform --resource-group rg-ai-platform-dev
```

### Supprimer le Resource Group (si Terraform échoue)

```bash
az group delete --name rg-ai-platform-dev --yes --no-wait
```

---

## 📋 Commandes utiles

### Contexte kubectl

```bash
# Voir tous les contextes
kubectl config get-contexts

# Passer à K3d
kubectl config use-context k3d-ai-platform

# Passer à AKS
kubectl config use-context aks-ai-platform
```

### Secrets PostgreSQL

```bash
# Récupérer le mot de passe PostgreSQL depuis Key Vault
az keyvault secret show \
  --vault-name $(terraform output -raw keyvault_name) \
  --name postgres-admin-password \
  --query value -o tsv
```

### Logs et debugging

```bash
# Logs d'un pod
kubectl logs -f <pod-name> -n <namespace>

# Décrire une ressource
kubectl describe pod <pod-name> -n <namespace>

# Events récents
kubectl get events --sort-by='.lastTimestamp' -A
```

---

## 📚 Ressources

- [Azure Arc Documentation](https://docs.microsoft.com/en-us/azure/azure-arc/)
- [AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)

---

## ✅ Checklist rapide

```
□ Compte Azure créé avec $200 crédits
□ Budget alert configuré ($50)
□ Azure CLI installé et connecté
□ Terraform init + apply réussi
□ AKS accessible (kubectl get nodes)
□ ArgoCD installé sur AKS
□ K3d connecté à Azure Arc
□ Extensions Arc activées (Policy, Monitor, Defender)
```

---

*Document créé le 23/02/2026 - Projet hybrid-ai-security-platform*
