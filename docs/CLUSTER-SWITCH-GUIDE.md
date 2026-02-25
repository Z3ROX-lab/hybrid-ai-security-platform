# 🔄 Guide de Switch entre Clusters Kubernetes

## Vue d'ensemble

Tu as 2 clusters Kubernetes :

| Cluster | Contexte | Utilisation |
|---------|----------|-------------|
| **K3d** (local) | `k3d-ai-security-platform` | Workloads sensibles, LLM, RAG |
| **AKS** (Azure) | `aks-ai-platform` | Workloads publics, services managés |

## Commandes essentielles

### Voir tous les contextes disponibles

```bash
kubectl config get-contexts
```

Résultat :
```
CURRENT   NAME                       CLUSTER
          aks-ai-platform            aks-ai-platform
*         k3d-ai-security-platform   k3d-ai-security-platform  ← * = actuel
```

### Voir le contexte actuel

```bash
kubectl config current-context
```

### Switcher vers K3d (local)

```bash
kubectl config use-context k3d-ai-security-platform
```

### Switcher vers AKS (Azure)

```bash
kubectl config use-context aks-ai-platform
```

## Alias pratiques (optionnel)

Ajoute ces alias dans ton `~/.bashrc` ou `~/.zshrc` :

```bash
# Alias pour switcher rapidement
alias k3d-switch='kubectl config use-context k3d-ai-security-platform'
alias aks-switch='kubectl config use-context aks-ai-platform'

# Alias pour voir le contexte actuel
alias kctx='kubectl config current-context'

# Alias pour lister les contextes
alias kctx-list='kubectl config get-contexts'
```

Puis recharge :
```bash
source ~/.bashrc
```

Utilisation :
```bash
k3d-switch   # Passe sur K3d
aks-switch   # Passe sur AKS
kctx         # Affiche le contexte actuel
```

## Vérification rapide

Après un switch, vérifie toujours :

```bash
# Quel cluster ?
kubectl config current-context

# Quels nodes ?
kubectl get nodes
```

**K3d affiche :**
```
NAME                              STATUS   ROLES                  AGE
k3d-ai-security-platform-server   Ready    control-plane,master   ...
k3d-ai-security-platform-agent-0  Ready    <none>                 ...
k3d-ai-security-platform-agent-1  Ready    <none>                 ...
```

**AKS affiche :**
```
NAME                              STATUS   ROLES    AGE
aks-default-20631142-vmss000000   Ready    <none>   ...
```

## Si tu perds un contexte

### Régénérer le contexte K3d

```bash
# Vérifie que K3d tourne
k3d cluster list

# Régénère le kubeconfig
k3d kubeconfig merge ai-security-platform --kubeconfig-merge-default
```

### Régénérer le contexte AKS

```bash
# Re-télécharge les credentials
az aks get-credentials --resource-group rg-ai-platform-dev --name aks-ai-platform
```

## Résumé visuel

```
┌─────────────────────────────────────────────────────────────────────┐
│                         TON LAPTOP                                  │
│                                                                     │
│   ~/.kube/config                                                    │
│   ┌─────────────────────────────────────────────────────────┐      │
│   │  contexts:                                               │      │
│   │    - k3d-ai-security-platform  ←──┐                     │      │
│   │    - aks-ai-platform           ←──┼── kubectl utilise   │      │
│   │                                    │   le contexte       │      │
│   │  current-context: xxx          ←──┘   marqué *          │      │
│   └─────────────────────────────────────────────────────────┘      │
│                                                                     │
│   kubectl config use-context k3d-ai-security-platform               │
│          │                                                          │
│          ▼                                                          │
│   ┌─────────────┐                      ┌─────────────┐             │
│   │   K3D       │                      │   AKS       │             │
│   │  (local)    │                      │  (Azure)    │             │
│   │  Port 6443  │                      │  Internet   │             │
│   └─────────────┘                      └─────────────┘             │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Cheatsheet

| Action | Commande |
|--------|----------|
| Lister contextes | `kubectl config get-contexts` |
| Contexte actuel | `kubectl config current-context` |
| Switch K3d | `kubectl config use-context k3d-ai-security-platform` |
| Switch AKS | `kubectl config use-context aks-ai-platform` |
| Vérifier nodes | `kubectl get nodes` |
| Régénérer K3d | `k3d kubeconfig merge ai-security-platform --kubeconfig-merge-default` |
| Régénérer AKS | `az aks get-credentials --resource-group rg-ai-platform-dev --name aks-ai-platform` |

---

*💡 Conseil : Toujours vérifier `kubectl config current-context` avant de lancer des commandes !*
