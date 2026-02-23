# =============================================================================
# OUTPUTS
# =============================================================================

# -----------------------------------------------------------------------------
# RESOURCE GROUP
# -----------------------------------------------------------------------------

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# -----------------------------------------------------------------------------
# NETWORKING
# -----------------------------------------------------------------------------

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "subnet_aks_id" {
  description = "ID of the AKS subnet"
  value       = azurerm_subnet.aks.id
}

output "subnet_data_id" {
  description = "ID of the data subnet"
  value       = azurerm_subnet.data.id
}

# -----------------------------------------------------------------------------
# AKS
# -----------------------------------------------------------------------------

output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "aks_kube_config_raw" {
  description = "Raw kubeconfig for AKS"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "aks_host" {
  description = "AKS API server host"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  sensitive   = true
}

output "aks_get_credentials_command" {
  description = "Command to get AKS credentials"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}"
}

# -----------------------------------------------------------------------------
# POSTGRESQL
# -----------------------------------------------------------------------------

output "postgresql_server_name" {
  description = "Name of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.name
}

output "postgresql_fqdn" {
  description = "FQDN of the PostgreSQL server"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "postgresql_admin_username" {
  description = "PostgreSQL admin username"
  value       = azurerm_postgresql_flexible_server.main.administrator_login
}

output "postgresql_databases" {
  description = "List of created databases"
  value       = [for db in azurerm_postgresql_flexible_server_database.databases : db.name]
}

# -----------------------------------------------------------------------------
# KEY VAULT
# -----------------------------------------------------------------------------

output "keyvault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "keyvault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "keyvault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

# -----------------------------------------------------------------------------
# MONITORING
# -----------------------------------------------------------------------------

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.name
}

# -----------------------------------------------------------------------------
# QUICK START COMMANDS
# -----------------------------------------------------------------------------

output "next_steps" {
  description = "Next steps after deployment"
  value       = <<-EOT

    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                    DEPLOYMENT SUCCESSFUL! 🎉                               ║
    ╚═══════════════════════════════════════════════════════════════════════════╝

    📦 Resources Created:
    ────────────────────
    • Resource Group: ${azurerm_resource_group.main.name}
    • VNet: ${azurerm_virtual_network.main.name}
    • AKS: ${azurerm_kubernetes_cluster.main.name}
    • PostgreSQL: ${azurerm_postgresql_flexible_server.main.fqdn}
    • Key Vault: ${azurerm_key_vault.main.name}
    • Log Analytics: ${azurerm_log_analytics_workspace.main.name}

    🚀 Next Steps:
    ────────────────

    1. Get AKS credentials:
       az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}

    2. Verify connection:
       kubectl get nodes

    3. Install ArgoCD on AKS:
       kubectl create namespace argocd
       kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

    4. Connect K3d to Azure Arc:
       ./scripts/connect-arc.sh

    5. Install Tailscale for hybrid connectivity:
       ./scripts/setup-tailscale-aks.sh

    💰 Cost Saving Commands:
    ─────────────────────────

    Stop AKS (saves ~$1/hour):
       az aks stop --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}

    Start AKS:
       az aks start --resource-group ${azurerm_resource_group.main.name} --name ${azurerm_kubernetes_cluster.main.name}

    🔑 Secrets:
    ───────────
    PostgreSQL password stored in Key Vault: ${azurerm_key_vault.main.name}
    Secret name: postgres-admin-password

    Retrieve password:
       az keyvault secret show --vault-name ${azurerm_key_vault.main.name} --name postgres-admin-password --query value -o tsv

  EOT
}
