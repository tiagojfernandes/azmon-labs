# terraform/outputs.tf

output "resource_group_name" {
  description = "The name of the resource group"
  value       = module.resource_group.name
}

output "log_analytics_workspace_id" {
  description = "The full resource ID of the Log Analytics Workspace"
  value       = module.log_analytics.workspace_id
}

output "log_analytics_workspace_name" {
  description = "The name of the Log Analytics Workspace"
  value       = module.log_analytics.workspace_name
}

output "user_timezone" {
  description = "The user's timezone for auto-shutdown configuration"
  value       = var.user_timezone
}


# VM Names
output "ubuntu_vm_name" {
  description = "The name of the Ubuntu Virtual Machine"
  value       = module.vm_ubuntu.vm_name
}

output "windows_vm_name" {
  description = "The name of the Windows Virtual Machine"
  value       = module.vm_windows.vm_name
}

output "redhat_vm_name" {
  description = "The name of the Red Hat Virtual Machine"
  value       = module.vm_redhat.vm_name
}

output  "aks_name" {
  description = "AKS Cluster name"
  value       = var.aks_name
}

output  "grafana_name" {
  description = "Managed Grafana name"
  value       = var.grafana_name
}

output  "prom_name" {
  description = "Managed Prometheus name"
  value       = var.prom_name
}

# VM IP Addresses
output "redhat_vm_private_ip" {
  description = "The private (internal) IP address of the Red Hat Virtual Machine"
  value       = module.vm_redhat.private_ip_address
}

output "vmss_name" {
  description = "The name of the Windows Virtual Machine Scale Set"
  value       = module.vmss_windows.vmss_name
}

# Azure Function Outputs
output "function_app_name" {
  description = "Name of the Azure Function App for VMSS shutdown"
  value       = module.azure_function.function_app_name
}

output "function_app_id" {
  description = "ID of the Azure Function App"
  value       = module.azure_function.function_app_id
}

output "storage_account_name" {
  description = "Name of the storage account for Azure Function"
  value       = module.azure_function.storage_account_name
}



