# azure_function/variables.tf
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "function_app_prefix" {
  description = "Prefix for the Azure Function App name (will be made globally unique with random suffix)"
  type        = string
  default     = "vmss-shutdown-fn"
  
  validation {
    condition     = length(var.function_app_prefix) <= 50 && can(regex("^[a-zA-Z0-9-]+$", var.function_app_prefix))
    error_message = "Function app prefix must be 50 characters or less and contain only letters, numbers, and hyphens."
  }
}

variable "storage_account_prefix" {
  description = "Prefix for the storage account name (will be made globally unique with random suffix)"
  type        = string
  default     = "funcstorvmss"
  
  validation {
    condition     = length(var.storage_account_prefix) <= 16 && can(regex("^[a-z0-9]+$", var.storage_account_prefix))
    error_message = "Storage account prefix must be 16 characters or less and contain only lowercase letters and numbers."
  }
}

variable "app_service_plan_prefix" {
  description = "Prefix for the App Service Plan name (will be made globally unique with random suffix)"
  type        = string
  default     = "vmss-fn-plan"
  
  validation {
    condition     = length(var.app_service_plan_prefix) <= 50 && can(regex("^[a-zA-Z0-9-]+$", var.app_service_plan_prefix))
    error_message = "App Service Plan prefix must be 50 characters or less and contain only letters, numbers, and hyphens."
  }
}
