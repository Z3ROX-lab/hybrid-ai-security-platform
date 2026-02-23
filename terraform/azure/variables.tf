# =============================================================================
# GENERAL
# =============================================================================

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "ai-platform"
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "francecentral"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    project     = "hybrid-ai-security-platform"
    environment = "dev"
    managed_by  = "terraform"
    owner       = "z3rox"
  }
}

# =============================================================================
# NETWORKING
# =============================================================================

variable "vnet_address_space" {
  description = "VNet address space"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_aks_prefix" {
  description = "AKS subnet address prefix"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_data_prefix" {
  description = "Data subnet address prefix (PostgreSQL)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "subnet_endpoints_prefix" {
  description = "Private endpoints subnet address prefix"
  type        = string
  default     = "10.0.3.0/24"
}

# =============================================================================
# AKS
# =============================================================================

variable "aks_kubernetes_version" {
  description = "Kubernetes version for AKS"
  type        = string
  default     = "1.29"
}

variable "aks_sku_tier" {
  description = "AKS SKU tier (Free or Standard)"
  type        = string
  default     = "Free"
}

variable "aks_default_node_pool_vm_size" {
  description = "VM size for default node pool"
  type        = string
  default     = "Standard_B2s_v2" # Économique: 2 vCPU, 4GB RAM, ~$30/month
}

variable "aks_default_node_pool_count" {
  description = "Number of nodes in default pool"
  type        = number
  default     = 1
}

variable "aks_default_node_pool_min_count" {
  description = "Minimum nodes for autoscaling (0 to disable)"
  type        = number
  default     = 0
}

variable "aks_default_node_pool_max_count" {
  description = "Maximum nodes for autoscaling"
  type        = number
  default     = 3
}

variable "aks_enable_autoscaling" {
  description = "Enable cluster autoscaler"
  type        = bool
  default     = false # Disable to save money in dev
}

# =============================================================================
# POSTGRESQL
# =============================================================================

variable "postgresql_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
}

variable "postgresql_sku_name" {
  description = "PostgreSQL SKU"
  type        = string
  default     = "B_Standard_B1ms" # Économique: ~$15/month
}

variable "postgresql_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 32768 # 32GB minimum
}

variable "postgresql_admin_username" {
  description = "PostgreSQL admin username"
  type        = string
  default     = "pgadmin"
}

variable "postgresql_databases" {
  description = "List of databases to create"
  type        = list(string)
  default     = ["langfuse", "openwebui"]
}

# =============================================================================
# KEY VAULT
# =============================================================================

variable "keyvault_sku_name" {
  description = "Key Vault SKU"
  type        = string
  default     = "standard"
}

variable "keyvault_soft_delete_retention_days" {
  description = "Soft delete retention days"
  type        = number
  default     = 7 # Minimum for dev, faster cleanup
}

# =============================================================================
# MONITORING
# =============================================================================

variable "log_analytics_retention_days" {
  description = "Log Analytics retention in days"
  type        = number
  default     = 30
}

variable "enable_container_insights" {
  description = "Enable Container Insights on AKS"
  type        = bool
  default     = true
}

# =============================================================================
# AZURE ARC (for K3d connection)
# =============================================================================

variable "arc_cluster_name" {
  description = "Name for the Arc-connected K3d cluster"
  type        = string
  default     = "k3d-ai-platform"
}
