#!/bin/bash
# =============================================================================
# TAILSCALE SETUP FOR AKS
# =============================================================================
# Installs Tailscale operator on AKS for secure mesh connectivity with K3d
# =============================================================================

set -e

# Configuration
TAILSCALE_NAMESPACE="tailscale"

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              TAILSCALE SETUP FOR AKS                          ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Check prerequisites
echo "🔍 Checking prerequisites..."

if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found. Please install kubectl."
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo "❌ helm not found. Please install helm."
    exit 1
fi

# Verify we're connected to AKS
CURRENT_CONTEXT=$(kubectl config current-context)
echo "📍 Current kubectl context: $CURRENT_CONTEXT"

if [[ ! "$CURRENT_CONTEXT" =~ "aks" ]]; then
    echo "⚠️  Warning: Current context doesn't look like AKS."
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Cancelled."
        exit 1
    fi
fi

# Create namespace
echo ""
echo "📦 Creating tailscale namespace..."
kubectl create namespace $TAILSCALE_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Add Tailscale Helm repo
echo ""
echo "📦 Adding Tailscale Helm repository..."
helm repo add tailscale https://pkgs.tailscale.com/helmcharts
helm repo update

# Check for auth key
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "🔑 TAILSCALE AUTH KEY REQUIRED"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "You need a Tailscale auth key to connect this cluster."
echo ""
echo "1. Go to: https://login.tailscale.com/admin/settings/keys"
echo "2. Generate an auth key (reusable, with tags if desired)"
echo "3. Enter it below"
echo ""

read -p "Tailscale Auth Key: " -s TAILSCALE_AUTH_KEY
echo ""

if [ -z "$TAILSCALE_AUTH_KEY" ]; then
    echo "❌ No auth key provided. Exiting."
    exit 1
fi

# Create secret with auth key
echo ""
echo "🔐 Creating Tailscale secret..."
kubectl create secret generic tailscale-auth \
    --namespace $TAILSCALE_NAMESPACE \
    --from-literal=TS_AUTHKEY="$TAILSCALE_AUTH_KEY" \
    --dry-run=client -o yaml | kubectl apply -f -

# Install Tailscale operator
echo ""
echo "📦 Installing Tailscale operator..."
helm upgrade --install tailscale-operator tailscale/tailscale-operator \
    --namespace $TAILSCALE_NAMESPACE \
    --set oauth.clientId="" \
    --set oauth.clientSecret="" \
    --wait

# Create a subnet router to expose cluster services
echo ""
echo "🌐 Creating subnet router..."
cat <<EOF | kubectl apply -f -
apiVersion: tailscale.com/v1alpha1
kind: Connector
metadata:
  name: aks-subnet-router
  namespace: $TAILSCALE_NAMESPACE
spec:
  hostname: aks-subnet-router
  subnetRouter:
    advertiseRoutes:
      - "10.0.0.0/16"  # Azure VNet CIDR
  tags:
    - tag:k8s
EOF

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║              TAILSCALE SETUP COMPLETE! 🎉                     ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Next steps:"
echo ""
echo "1. Approve the subnet routes in Tailscale admin:"
echo "   https://login.tailscale.com/admin/machines"
echo ""
echo "2. On your K3d cluster, install Tailscale similarly"
echo "   or just install Tailscale on the host machine"
echo ""
echo "3. Test connectivity:"
echo "   From K3d host: ping <aks-pod-ip>"
echo "   From AKS: ping <k3d-service-ip>"
echo ""
echo "4. Update Open WebUI to point to K3d Ollama:"
echo "   OLLAMA_BASE_URL=http://100.x.x.x:11434"
echo "   (use 'tailscale ip' on K3d host to get the IP)"
echo ""
