variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "workspace_name" {
  description = "Log Analytics Workspace name"
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "user_timezone" {
  description = "User's timezone for auto-shutdown configuration"
  type        = string
  default     = "UTC"
}

variable "aks_name" {
  description = "AKS Cluster name"
  type        = string
  default     = "aks-azmon"
}

variable "grafana_name" {
  description = "Managed Grafana name"
  type        = string
  default     = "managed-gf"
}

variable "prom_name" {
  description = "Managed Prometheus name"
  type        = string
  default     = "managed-pm"
}


variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
  default     = "vmss_subnet"
}


variable "vmss_name" {
  description = "Name of the Virtual Machine Scale Set"
  type        = string
  default     = "vmss-win"  # Short name to avoid any naming issues
}



variable "admin_username" {
  description = "Common admin username for all VMs and VMSS"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Common admin password for all VMs and VMSS"
  type        = string
  sensitive   = true
  # No default - will be provided via terraform.tfvars
}



# Ubuntu VM Configuration
variable "ubuntu_vm_name" {
  description = "Name of the Ubuntu Virtual Machine"
  type        = string
  default     = "vm-ubuntu-lab"
}

variable "ubuntu_vm_size" {
  description = "Size of the Ubuntu VM"
  type        = string
  default     = "Standard_B2s"
}


# Windows VM Configuration
variable "windows_vm_name" {
  description = "Name of the Windows Virtual Machine"
  type        = string
  default     = "vm-windows-lab"
}

variable "windows_vm_size" {
  description = "Size of the Windows VM"
  type        = string
  default     = "Standard_B2s"
}

# Red Hat VM Configuration
variable "redhat_vm_name" {
  description = "Name of the Red Hat Virtual Machine"
  type        = string
  default     = "vm-redhat-lab"
}

variable "redhat_vm_size" {
  description = "Size of the Red Hat VM"
  type        = string
  default     = "Standard_B2s"
}

# Azure Function Configuration
variable "function_app_prefix" {
  description = "Prefix for the Azure Function App name for VMSS shutdown (will be made globally unique with random suffix)"
  type        = string
  default     = "vmss-shutdown-fn"
  
  validation {
    condition     = length(var.function_app_prefix) <= 50 && can(regex("^[a-zA-Z0-9-]+$", var.function_app_prefix))
    error_message = "Function app prefix must be 50 characters or less and contain only letters, numbers, and hyphens."
  }
}

variable "storage_account_prefix" {
  description = "Prefix for the storage account name for Azure Function (will be made globally unique with random suffix)"
  type        = string
  default     = "funcstorvmss"
  
  validation {
    condition     = length(var.storage_account_prefix) <= 16 && can(regex("^[a-z0-9]+$", var.storage_account_prefix))
    error_message = "Storage account prefix must be 16 characters or less and contain only lowercase letters and numbers."
  }
}

variable "app_service_plan_prefix" {
  description = "Prefix for the App Service Plan name for Azure Function (will be made globally unique with random suffix)"
  type        = string
  default     = "vmss-fn-plan"
  
  validation {
    condition     = length(var.app_service_plan_prefix) <= 50 && can(regex("^[a-zA-Z0-9-]+$", var.app_service_plan_prefix))
    error_message = "App Service Plan prefix must be 50 characters or less and contain only letters, numbers, and hyphens."
  }
}


