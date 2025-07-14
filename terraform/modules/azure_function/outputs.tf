# azure_function/outputs.tf
output "function_app_name" {
  description = "Name of the Azure Function App"
  value       = azurerm_linux_function_app.vmss_shutdown_func.name
}

output "function_app_id" {
  description = "ID of the Azure Function App"
  value       = azurerm_linux_function_app.vmss_shutdown_func.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.function_storage.name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.function_storage.id
}

output "function_app_principal_id" {
  description = "Principal ID of the Function App's managed identity"
  value       = azurerm_linux_function_app.vmss_shutdown_func.identity[0].principal_id
}
