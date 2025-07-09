# azure_function/main.tf
resource "azurerm_storage_account" "function_storage" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  tags = {
    Environment = "Lab"
    Purpose     = "Azure Function Storage"
  }
}

resource "azurerm_service_plan" "function_plan" {
  name                = var.app_service_plan_name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name           = "Y1"
  
  tags = {
    Environment = "Lab"
    Purpose     = "Azure Function Plan"
  }
}

resource "azurerm_linux_function_app" "vmss_shutdown_func" {
  name                = var.function_app_name
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.function_plan.id
  
  storage_account_name       = azurerm_storage_account.function_storage.name
  storage_account_access_key = azurerm_storage_account.function_storage.primary_access_key
  
  functions_extension_version = "~4"
  https_only                 = true

  site_config {
    application_stack {
      python_version = "3.9"
    }
  }

  identity {
    type = "SystemAssigned"
  }
  
  app_settings = {
    "FUNCTIONS_WORKER_RUNTIME" = "python"
    "WEBSITE_RUN_FROM_PACKAGE" = "1"
    "AZURE_SUBSCRIPTION_ID"   = data.azurerm_client_config.current.subscription_id
    # RG_NAME and VMSS_NAME will be set via the deployment script
  }

  tags = {
    Environment = "Lab"
    Purpose     = "VMSS Auto-Shutdown Function"
  }
}

# Grant the function app permissions to manage the VMSS
resource "azurerm_role_assignment" "function_contributor" {
  principal_id         = azurerm_linux_function_app.vmss_shutdown_func.identity[0].principal_id
  role_definition_name = "Virtual Machine Contributor"
  scope                = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
}

data "azurerm_client_config" "current" {}
