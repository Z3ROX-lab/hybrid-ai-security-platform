#!/bin/bash
# =============================================================================
# AKS START SCRIPT
# =============================================================================
# Starts the AKS cluster and retrieves credentials
# =============================================================================

set -e

# Configuration
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-ai-platform-dev}"
CLUSTER_NAME="${CLUSTER_NAME:-aks-ai-platform}"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    STARTING AKS CLUSTER                       ║"
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

if [ "$STATE" == "Running" ]; then
    echo "✅ Cluster is already running!"
else
    echo "🚀 Starting AKS cluster (this takes 2-3 minutes)..."
    az aks start \
        --resource-group "$RESOURCE_GROUP" \
        --name "$CLUSTER_NAME"
    echo "✅ Cluster started!"
fi

# Get credentials
echo ""
echo "🔑 Getting cluster credentials..."
az aks get-credentials \
    --resource-group "$RESOURCE_GROUP" \
    --name "$CLUSTER_NAME" \
    --overwrite-existing

# Verify connection
echo ""
echo "🔍 Verifying connection..."
kubectl get nodes

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    AKS CLUSTER READY! 🎉                      ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "You can now use kubectl to interact with the cluster."
echo ""
echo "💡 Don't forget to stop the cluster when done to save money:"
echo "   ./scripts/aks-stop.sh"
echo ""
