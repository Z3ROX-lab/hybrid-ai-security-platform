#!/bin/bash
# =============================================================================
# ENABLE AZURE ARC EXTENSIONS
# =============================================================================
# Enables Azure Policy, Monitor, and Defender on Arc-connected cluster
# All of these are FREE or have free tiers!
# =============================================================================

set -e

# Configuration
RESOURCE_GROUP="${RESOURCE_GROUP:-rg-ai-platform-dev}"
CLUSTER_NAME="${ARC_CLUSTER_NAME:-k3d-ai-platform}"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║            ENABLING AZURE ARC EXTENSIONS                      ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "📦 Resource Group: $RESOURCE_GROUP"
echo "☸️  Arc Cluster: $CLUSTER_NAME"
echo ""

# Check if logged in
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure. Running 'az login'..."
    az login
fi

# Get Log Analytics Workspace ID
echo "🔍 Getting Log Analytics Workspace..."
LAW_ID=$(az monitor log-analytics workspace list \
    --resource-group "$RESOURCE_GROUP" \
    --query "[0].id" -o tsv 2>/dev/null || echo "")

if [ -z "$LAW_ID" ]; then
    echo "⚠️  No Log Analytics Workspace found in $RESOURCE_GROUP"
    echo "   Container Insights will create one automatically."
fi

# =============================================================================
# 1. AZURE POLICY (FREE)
# =============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "1️⃣  AZURE POLICY (FREE)"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if az k8s-extension show --name azurepolicy --cluster-name "$CLUSTER_NAME" \
    --resource-group "$RESOURCE_GROUP" --cluster-type connectedClusters &> /dev/null; then
    echo "✅ Azure Policy already installed"
else
    echo "📦 Installing Azure Policy extension..."
    az k8s-extension create \
        --name azurepolicy \
        --cluster-name "$CLUSTER_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --cluster-type connectedClusters \
        --extension-type Microsoft.PolicyInsights
    echo "✅ Azure Policy installed!"
fi

# =============================================================================
# 2. AZURE MONITOR / CONTAINER INSIGHTS (5GB FREE/MONTH)
# =============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "2️⃣  AZURE MONITOR (5GB FREE/MONTH)"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if az k8s-extension show --name azuremonitor-containers --cluster-name "$CLUSTER_NAME" \
    --resource-group "$RESOURCE_GROUP" --cluster-type connectedClusters &> /dev/null; then
    echo "✅ Azure Monitor already installed"
else
    echo "📦 Installing Azure Monitor extension..."
    
    MONITOR_ARGS=(
        --name azuremonitor-containers
        --cluster-name "$CLUSTER_NAME"
        --resource-group "$RESOURCE_GROUP"
        --cluster-type connectedClusters
        --extension-type Microsoft.AzureMonitor.Containers
    )
    
    # Add workspace if available
    if [ -n "$LAW_ID" ]; then
        MONITOR_ARGS+=(--configuration-settings "logAnalyticsWorkspaceResourceID=$LAW_ID")
    fi
    
    az k8s-extension create "${MONITOR_ARGS[@]}"
    echo "✅ Azure Monitor installed!"
fi

# =============================================================================
# 3. MICROSOFT DEFENDER (BASIC = FREE)
# =============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "3️⃣  MICROSOFT DEFENDER (BASIC = FREE)"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if az k8s-extension show --name microsoft.azuredefender.kubernetes --cluster-name "$CLUSTER_NAME" \
    --resource-group "$RESOURCE_GROUP" --cluster-type connectedClusters &> /dev/null; then
    echo "✅ Defender already installed"
else
    echo "📦 Installing Defender extension..."
    az k8s-extension create \
        --name microsoft.azuredefender.kubernetes \
        --cluster-name "$CLUSTER_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --cluster-type connectedClusters \
        --extension-type microsoft.azuredefender.kubernetes
    echo "✅ Defender installed!"
fi

# =============================================================================
# SUMMARY
# =============================================================================
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║            ALL EXTENSIONS INSTALLED! 🎉                       ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Installed extensions:"
az k8s-extension list \
    --cluster-name "$CLUSTER_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --cluster-type connectedClusters \
    -o table

echo ""
echo "🔍 Verify in Azure Portal:"
echo "   https://portal.azure.com/#view/Microsoft_Azure_ArcCenterUX/ArcCenterMenuBlade/~/kubernetes"
echo ""
echo "📊 What you can now do:"
echo "   • View cluster in Azure Portal"
echo "   • Apply Azure Policies to K3d"
echo "   • See metrics in Azure Monitor"
echo "   • Get security recommendations from Defender"
echo ""
