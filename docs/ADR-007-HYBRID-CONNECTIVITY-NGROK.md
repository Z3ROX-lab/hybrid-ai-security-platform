# ADR-007: Choix de ngrok pour la connectivité hybride AKS ↔ K3d

## Statut
**Accepté** - 26/02/2026

## Contexte

La plateforme Hybrid AI Security nécessite une connexion entre :
- **AKS (Azure)** : héberge OpenWebUI (interface utilisateur)
- **K3d (On-premises/WSL2)** : héberge Ollama avec Mistral 7B (inférence LLM)

L'objectif est de permettre à OpenWebUI sur AKS d'envoyer des requêtes à Ollama sur K3d de manière sécurisée et fiable.

### Contraintes techniques

| Contrainte | Description |
|------------|-------------|
| NAT/Firewall | K3d est derrière un NAT résidentiel sans IP publique |
| Latence | Acceptable pour du LLM (<500ms overhead) |
| Sécurité | Chiffrement requis, authentification souhaitée |
| Coût | Budget minimal (projet portfolio) |
| Complexité | Solution maintenable par une personne |

## Options considérées

### Option 1 : VPN Site-to-Site (Azure VPN Gateway)
- Coût : ~$27/mois
- Nécessite IP publique fixe
- Overkill pour un seul service

### Option 2 : Tailscale (Mesh VPN)
- ❌ Mode userspace dans K8s : le trafic TCP ne passe pas
- ❌ tailscale ping fonctionne, wget/curl timeout

### Option 3 : Cloudflare Tunnel
- Plus complexe à configurer (~30 min)
- Nécessite domaine Cloudflare

### Option 4 : ngrok ✅
- Fonctionne immédiatement (2 min)
- Gratuit (plan Free suffisant)
- HTTPS automatique

## Décision

**Option 4 : ngrok** - Seule solution fonctionnelle après tests exhaustifs de Tailscale.

## Implémentation
```bash
# Côté On-premises
kubectl port-forward svc/ollama -n ai-inference 11434:11434 &
./ngrok http 11434
```
```yaml
# Côté AKS (values.yaml)
ollamaUrls:
  - "https://xxx.ngrok-free.dev"
```

## Références
- Tests effectués le 26/02/2026
- [ngrok Documentation](https://ngrok.com/docs)
