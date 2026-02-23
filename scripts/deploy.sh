#!/bin/bash
# =============================================================================
# FULL DEPLOYMENT SCRIPT
# =============================================================================
# Deploys the complete hybrid AI platform infrastructure
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║        HYBRID AI SECURITY PLATFORM - FULL DEPLOYMENT          ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "This script will deploy:"
echo "  • Azure infrastructure (VNet, AKS, PostgreSQL, Key Vault)"
echo "  • ArgoCD on AKS"
echo "  • Connect K3d to Azure Arc"
echo ""
echo "Estimated time: 15-20 minutes"
echo "Estimated cost: ~\$46/month (stop AKS at night to save money)"
echo ""

read -p "Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelled."
    exit 1
fi

# =============================================================================
# STEP 1: Azure Login
# =============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "STEP 1: Azure Login"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if ! az account show &> /dev/null; then
    echo "🔐 Logging in to Azure..."
    az login
else
    echo "✅ Already logged in to Azure"
    az account show -o table
fi

# =============================================================================
# STEP 2: Terraform Init & Apply
# =============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "STEP 2: Deploying Azure Infrastructure (Terraform)"
echo "═══════════════════════════════════════════════════════════════"
echo ""

cd "$PROJECT_DIR/terraform/azure"

# Check for tfvars
if [ ! -f "terraform.tfvars" ]; then
    echo "⚠️  terraform.tfvars not found."
    echo "   Copying from terraform.tfvars.example..."
    cp terraform.tfvars.example terraform.tfvars
    echo "   Please review and edit terraform.tfvars if needed."
    read -p "Press Enter to continue..."
fi

echo "📦 Initializing Terraform..."
terraform init

echo ""
echo "📋 Planning infrastructure..."
terraform plan -out=tfplan

echo ""
read -p "Apply this plan? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelled."
    exit 1
fi

echo ""
echo "🚀 Applying infrastructure (this takes 5-10 minutes)..."
terraform apply tfplan

# =============================================================================
# STEP 3: Get AKS Credentials
# =============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "STEP 3: Getting AKS Credentials"
echo "═══════════════════════════════════════════════════════════════"
echo ""

RESOURCE_GROUP=$(terraform output -raw resource_group_name)
AKS_NAME=$(terraform output -raw aks_cluster_name)

echo "📦 Resource Group: $RESOURCE_GROUP"
echo "☸️  AKS Cluster: $AKS_NAME"

az aks get-credentials \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_NAME" \
    --overwrite-existing

echo ""
echo "🔍 Verifying AKS connection..."
kubectl get nodes

# =============================================================================
# STEP 4: Install ArgoCD on AKS
# =============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "STEP 4: Installing ArgoCD on AKS"
echo "═══════════════════════════════════════════════════════════════"
echo ""

echo "📦 Creating argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "📦 Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo ""
echo "⏳ Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

echo ""
echo "🔑 ArgoCD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""

# =============================================================================
# STEP 5: Deploy Root App
# =============================================================================
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "STEP 5: Deploying ArgoCD Root Application"
echo "═══════════════════════════════════════════════════════════════"
echo ""

kubectl apply -f "$PROJECT_DIR/argocd/azure/root-app.yaml"

echo "✅ Root app deployed. ArgoCD will sync other applications."

# =============================================================================
# SUMMARY
# =============================================================================
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              DEPLOYMENT COMPLETE! 🎉                          ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "📦 Resources created:"
echo "   • Resource Group: $RESOURCE_GROUP"
echo "   • AKS Cluster: $AKS_NAME"
echo "   • PostgreSQL: $(terraform output -raw postgresql_fqdn)"
echo "   • Key Vault: $(terraform output -raw keyvault_name)"
echo ""
echo "🔑 Credentials:"
echo "   • ArgoCD: admin / $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
echo "   • PostgreSQL password in Key Vault: postgres-admin-password"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. Connect K3d to Azure Arc:"
echo "   ./scripts/connect-arc.sh"
echo ""
echo "2. Enable Arc extensions (Policy, Monitor, Defender):"
echo "   ./scripts/enable-arc-extensions.sh"
echo ""
echo "3. Setup Tailscale for hybrid connectivity:"
echo "   ./scripts/setup-tailscale-aks.sh"
echo ""
echo "💰 Don't forget to stop AKS when not in use:"
echo "   ./scripts/aks-stop.sh"
echo ""
