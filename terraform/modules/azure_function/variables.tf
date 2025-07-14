# azure_function/variables.tf
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "function_app_name" {
  description = "Name of the Azure Function App"
  type        = string
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

variable "app_service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
}
