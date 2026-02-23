#!/bin/bash
# =============================================================================
# AZURE ARC CONNECTION SCRIPT
# =============================================================================
# Connects your on-premises K3d cluster to Azure Arc
# This enables unified management through Azure Portal
# =============================================================================

set -e

# Configuration
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-ai-platform-dev}"
CLUSTER_NAME="${ARC_CLUSTER_NAME:-k3d-ai-platform}"
LOCATION="${LOCATION:-francecentral}"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              CONNECTING K3D TO AZURE ARC                      ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "📦 Resource Group: $RESOURCE_GROUP"
echo "☸️  Arc Cluster Name: $CLUSTER_NAME"
echo "📍 Location: $LOCATION"
echo ""

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure. Running 'az login'..."
    az login
fi

# Check current kubectl context
echo "🔍 Current kubectl context:"
CURRENT_CONTEXT=$(kubectl config current-context)
echo "   $CURRENT_CONTEXT"
echo ""

if [[ ! "$CURRENT_CONTEXT" =~ "k3d" ]]; then
    echo "⚠️  Warning: Current context doesn't look like K3d."
    echo "   Make sure you're pointing to your K3d cluster!"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Cancelled. Switch to K3d context first:"
        echo "   kubectl config use-context k3d-ai-platform"
        exit 1
    fi
fi

# Register providers (first time only)
echo "📝 Registering Azure providers..."
az provider register --namespace Microsoft.Kubernetes --wait
az provider register --namespace Microsoft.KubernetesConfiguration --wait
az provider register --namespace Microsoft.ExtendedLocation --wait

# Install/update connectedk8s extension
echo ""
echo "📦 Installing Azure CLI extensions..."
az extension add --name connectedk8s --upgrade --yes
az extension add --name k8s-extension --upgrade --yes
az extension add --name k8s-configuration --upgrade --yes

# Check if already connected
echo ""
echo "🔍 Checking if cluster is already connected..."
if az connectedk8s show --name "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP" &> /dev/null; then
    echo "✅ Cluster is already connected to Azure Arc!"
    az connectedk8s show --name "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP" -o table
else
    # Connect to Arc
    echo ""
    echo "🔗 Connecting cluster to Azure Arc..."
    az connectedk8s connect \
        --name "$CLUSTER_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --tags "project=hybrid-ai-security-platform" "environment=homelab"
    
    echo ""
    echo "✅ Cluster connected to Azure Arc!"
fi

# Verify connection
echo ""
echo "🔍 Verifying Arc agents..."
kubectl get pods -n azure-arc

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              AZURE ARC CONNECTION SUCCESSFUL! 🎉              ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "Your K3d cluster is now visible in Azure Portal!"
echo ""
echo "🌐 View in Portal:"
echo "   https://portal.azure.com/#view/Microsoft_Azure_ArcCenterUX/ArcCenterMenuBlade/~/kubernetes"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. Enable Azure Policy:"
echo "   ./scripts/enable-arc-policy.sh"
echo ""
echo "2. Enable Azure Monitor:"
echo "   ./scripts/enable-arc-monitor.sh"
echo ""
echo "3. Enable Defender for Cloud:"
echo "   ./scripts/enable-arc-defender.sh"
echo ""
