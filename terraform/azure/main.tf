# =============================================================================
# HYBRID AI SECURITY PLATFORM - AZURE INFRASTRUCTURE
# =============================================================================
#
# This Terraform configuration creates:
# - Resource Group
# - Virtual Network with subnets
# - AKS Cluster (Free tier, minimal nodes)
# - PostgreSQL Flexible Server
# - Key Vault
# - Log Analytics Workspace
#
# Estimated cost: ~$46/month (or ~$15-20/month if you stop AKS at night)
#
# =============================================================================

# -----------------------------------------------------------------------------
# DATA SOURCES
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

# -----------------------------------------------------------------------------
# RANDOM SUFFIX (for globally unique names)
# -----------------------------------------------------------------------------

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# -----------------------------------------------------------------------------
# RESOURCE GROUP
# -----------------------------------------------------------------------------

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}

# -----------------------------------------------------------------------------
# VIRTUAL NETWORK
# -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# Subnet for AKS
resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_aks_prefix]
}

# Subnet for Data (PostgreSQL with delegation)
resource "azurerm_subnet" "data" {
  name                 = "snet-data"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_data_prefix]

  delegation {
    name = "postgresql-delegation"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action"
      ]
    }
  }
}

# Subnet for Private Endpoints
resource "azurerm_subnet" "endpoints" {
  name                 = "snet-endpoints"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_endpoints_prefix]
}

# -----------------------------------------------------------------------------
# NETWORK SECURITY GROUPS
# -----------------------------------------------------------------------------

resource "azurerm_network_security_group" "aks" {
  name                = "nsg-aks"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  # Allow HTTPS inbound (for Ingress)
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow HTTP inbound (for redirect to HTTPS)
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# -----------------------------------------------------------------------------
# LOG ANALYTICS WORKSPACE (Free tier: 5GB/month)
# -----------------------------------------------------------------------------

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.project_name}-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_days
  tags                = var.tags
}

# -----------------------------------------------------------------------------
# AKS CLUSTER
# -----------------------------------------------------------------------------

resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${var.project_name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = var.project_name
  #kubernetes_version  = var.aks_kubernetes_version

  # Free tier control plane
  sku_tier = var.aks_sku_tier

  default_node_pool {
    name                = "default"
    node_count          = var.aks_enable_autoscaling ? null : var.aks_default_node_pool_count
    min_count           = var.aks_enable_autoscaling ? var.aks_default_node_pool_min_count : null
    max_count           = var.aks_enable_autoscaling ? var.aks_default_node_pool_max_count : null
    vm_size             = var.aks_default_node_pool_vm_size
    vnet_subnet_id      = azurerm_subnet.aks.id
    enable_auto_scaling = var.aks_enable_autoscaling

    # Cost optimization: use spot instances for dev (optional)
    # priority        = "Spot"
    # eviction_policy = "Delete"
    # spot_max_price  = -1

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    network_policy    = "calico"
    load_balancer_sku = "standard"
    outbound_type     = "loadBalancer"
  }

  # Azure Monitor (Container Insights)
  dynamic "oms_agent" {
    for_each = var.enable_container_insights ? [1] : []
    content {
      log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
    }
  }

  # Key Vault Secrets Provider
  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  tags = var.tags
}

# -----------------------------------------------------------------------------
# PRIVATE DNS ZONE FOR POSTGRESQL
# -----------------------------------------------------------------------------

resource "azurerm_private_dns_zone" "postgres" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "postgres-vnet-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

# -----------------------------------------------------------------------------
# POSTGRESQL FLEXIBLE SERVER
# -----------------------------------------------------------------------------

resource "random_password" "postgres" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-${var.project_name}-${random_string.suffix.result}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = var.postgresql_version
  delegated_subnet_id    = azurerm_subnet.data.id
  private_dns_zone_id    = azurerm_private_dns_zone.postgres.id

  administrator_login    = var.postgresql_admin_username
  administrator_password = random_password.postgres.result

  storage_mb            = var.postgresql_storage_mb
  sku_name              = var.postgresql_sku_name
  backup_retention_days = 7

  public_network_access_enabled = false

  # Disable HA for cost savings in dev
  # high_availability {
  #   mode = "ZoneRedundant"
  # }

  tags = var.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

# Create databases
resource "azurerm_postgresql_flexible_server_database" "databases" {
  for_each  = toset(var.postgresql_databases)
  name      = each.value
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# -----------------------------------------------------------------------------
# KEY VAULT
# -----------------------------------------------------------------------------

resource "azurerm_key_vault" "main" {
  name                       = "kv-${var.project_name}-${random_string.suffix.result}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.keyvault_sku_name
  soft_delete_retention_days = var.keyvault_soft_delete_retention_days
  purge_protection_enabled   = false # Allow purge for dev environment

  # Access policy for current user (Terraform executor)
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge", "Recover"
    ]
    key_permissions = [
      "Get", "List", "Create", "Delete", "Purge", "Recover"
    ]
  }

  # Access policy for AKS managed identity
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].object_id

    secret_permissions = [
      "Get", "List"
    ]
  }

  tags = var.tags
}

# Store PostgreSQL password in Key Vault
resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-admin-password"
  value        = random_password.postgres.result
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "postgres_connection_string" {
  name         = "postgres-connection-string"
  value        = "postgresql://${var.postgresql_admin_username}:${random_password.postgres.result}@${azurerm_postgresql_flexible_server.main.fqdn}:5432/langfuse?sslmode=require"
  key_vault_id = azurerm_key_vault.main.id
}

# -----------------------------------------------------------------------------
# ROLE ASSIGNMENTS
# -----------------------------------------------------------------------------

# AKS needs to pull images from ACR (if you add one later)
# resource "azurerm_role_assignment" "aks_acr" {
#   principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
#   role_definition_name             = "AcrPull"
#   scope                            = azurerm_container_registry.main.id
#   skip_service_principal_aad_check = true
# }

# AKS can read Key Vault secrets
resource "azurerm_role_assignment" "aks_keyvault" {
  principal_id                     = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].object_id
  role_definition_name             = "Key Vault Secrets User"
  scope                            = azurerm_key_vault.main.id
  skip_service_principal_aad_check = true
}
