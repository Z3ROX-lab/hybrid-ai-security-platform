# Guide Architecture ngrok - Connectivité Hybride AKS ↔ K3d

## Architecture
```
AKS (OpenWebUI) → Internet HTTPS → ngrok Edge → ngrok agent (WSL2) → Ollama (K3d)
```

## Démarrage rapide
```bash
# 1. Port-forward Ollama
kubectl config use-context k3d-ai-security-platform
kubectl port-forward svc/ollama -n ai-inference 11434:11434 &

# 2. Démarrer ngrok
./ngrok http 11434

# 3. Copier l'URL dans OpenWebUI values.yaml
```

## Sécurisation
```bash
# Avec header personnalisé
./ngrok http 11434 --request-header-add="ngrok-skip-browser-warning: true"
```

## Monitoring

Dashboard local : http://localhost:4040

## Coûts

| Plan | Prix | URL |
|------|------|-----|
| Free | $0 | Aléatoire |
| Personal | $8/mois | Fixe |
