#!/bin/bash
# =============================================================================
# STOP ALL AZURE RESOURCES
# =============================================================================
# Stoppe AKS et PostgreSQL pour économiser les coûts
# Coût après stop: ~$0.04/jour (disks seulement)
# =============================================================================

set -e

# Configuration
RESOURCE_GROUP="rg-ai-platform-dev"
AKS_NAME="aks-ai-platform"
POSTGRES_NAME="psql-ai-platform-91vaoc"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           STOPPING ALL AZURE RESOURCES 💤                     ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Check if logged in
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure. Running 'az login'..."
    az login --use-device-code
fi

# Stop AKS
echo "🛑 Stopping AKS cluster..."
az aks stop \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_NAME" \
    --no-wait
echo "✅ AKS stop initiated"

# Stop PostgreSQL
echo ""
echo "🛑 Stopping PostgreSQL..."
az postgres flexible-server stop \
    --resource-group "$RESOURCE_GROUP" \
    --name "$POSTGRES_NAME"
echo "✅ PostgreSQL stopped"

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           ALL RESOURCES STOPPED! 💤                           ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "💰 Coût cette nuit: ~\$0.04 (disks seulement)"
echo ""
echo "📋 Pour relancer demain:"
echo "   ./scripts/azure-start-all.sh"
echo ""
