#!/bin/bash
# =============================================================================
# START ALL AZURE RESOURCES
# =============================================================================
# Démarre AKS et PostgreSQL
# Temps de démarrage: ~3-5 minutes
# =============================================================================

set -e

# Configuration
RESOURCE_GROUP="rg-ai-platform-dev"
AKS_NAME="aks-ai-platform"
POSTGRES_NAME="psql-ai-platform-91vaoc"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           STARTING ALL AZURE RESOURCES ☀️                      ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Check if logged in
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure. Running 'az login'..."
    az login --use-device-code
fi

# Start PostgreSQL first (AKS apps might need it)
echo "🚀 Starting PostgreSQL..."
az postgres flexible-server start \
    --resource-group "$RESOURCE_GROUP" \
    --name "$POSTGRES_NAME"
echo "✅ PostgreSQL started"

# Start AKS
echo ""
echo "🚀 Starting AKS cluster (this takes 2-3 minutes)..."
az aks start \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_NAME"
echo "✅ AKS started"

# Get credentials
echo ""
echo "🔑 Getting AKS credentials..."
az aks get-credentials \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_NAME" \
    --overwrite-existing

# Verify
echo ""
echo "🔍 Verifying AKS connection..."
kubectl get nodes

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           ALL RESOURCES STARTED! ☀️                            ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Contextes kubectl disponibles:"
kubectl config get-contexts
echo ""
echo "💡 Switch entre clusters:"
echo "   kubectl config use-context aks-ai-platform           # Azure"
echo "   kubectl config use-context k3d-ai-security-platform  # Local"
echo ""
echo "💰 Pour stopper ce soir:"
echo "   ./scripts/azure-stop-all.sh"
echo ""
