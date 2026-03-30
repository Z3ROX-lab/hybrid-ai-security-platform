#!/bin/bash
# =============================================================================
# AKS STOP SCRIPT
# =============================================================================
# Stops the AKS cluster to save money
# When stopped, you only pay for storage (~$1/month vs ~$30/month running)
# =============================================================================

set -e

# Configuration
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-ai-platform-dev}"
CLUSTER_NAME="${CLUSTER_NAME:-aks-ai-platform}"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    STOPPING AKS CLUSTER                       ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "📦 Resource Group: $RESOURCE_GROUP"
echo "☸️  Cluster: $CLUSTER_NAME"
echo ""

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure. Running 'az login'..."
    az login
fi

# Check cluster state
echo "🔍 Checking cluster state..."
STATE=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --query "powerState.code" -o tsv 2>/dev/null || echo "Unknown")

if [ "$STATE" == "Stopped" ]; then
    echo "✅ Cluster is already stopped!"
    exit 0
fi

# Confirm
echo "⚠️  This will stop the AKS cluster."
echo "   While stopped, you save ~\$1/hour on compute costs."
echo "   Storage costs (~\$1/month) still apply."
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelled."
    exit 1
fi

# Stop cluster
echo ""
echo "🛑 Stopping AKS cluster (this takes 2-3 minutes)..."
az aks stop \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CLUSTER_NAME" \
    --no-wait

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    AKS CLUSTER STOPPING 💤                    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "The cluster is stopping in the background."
echo "This saves approximately \$1/hour in compute costs."
echo ""
echo "💡 To start the cluster again:"
echo "   ./scripts/aks-start.sh"
echo ""
