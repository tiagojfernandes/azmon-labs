#!/bin/bash

# Function to register a provider if not already registered
register_provider() {
  local provider_namespace=$1
  local registration_status

  # Check the current registration status of the provider
  registration_status=$(az provider show --namespace "$provider_namespace" --query "registrationState" -o tsv)

  if [ "$registration_status" != "Registered" ]; then
    echo "Registering $provider_namespace provider..."
    az provider register --namespace "$provider_namespace"

    # Wait until the provider is registered
    while [ "$(az provider show --namespace "$provider_namespace" --query "registrationState" -o tsv)" != "Registered" ]; do
      echo "Waiting for $provider_namespace provider registration..."
      sleep 5
    done
    echo "$provider_namespace provider registered successfully."
  else
    echo "$provider_namespace provider is already registered."
  fi
}

# Function to prompt and validate non-empty input
prompt_input() {
  local prompt_msg=$1
  local var_name=$2
  while [ -z "${!var_name}" ]; do
    read -p "$prompt_msg: " $var_name
  done
}

# Register required providers
register_provider "Microsoft.Insights"
register_provider "Microsoft.OperationalInsights"
register_provider "Microsoft.SecurityInsights"
register_provider "Microsoft.Monitor"
register_provider "Microsoft.Dashboard"

# Use the function to prompt for required inputs
prompt_input "Enter the name for the Azure resource group" RESOURCE_GROUP
prompt_input "Enter the Azure location (e.g., East US)" LOCATION
prompt_input "Enter the name for the Log Analytics Workspace" WORKSPACE_NAME
prompt_input "Enter the AKS cluster name" AKS_NAME
prompt_input "Enter the Managed Prometheus workspace name" PROMETHEUS_NAME
prompt_input "Enter the Managed Grafana name" GRAFANA_NAME

# Get Azure Subscription ID from Azure Cloud Shell environment
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Check if subscription_id was retrieved successfully
if [ -z "$SUBSCRIPTION_ID" ]; then
    echo "Error: Could not retrieve Azure subscription ID."
    exit 1
fi

# Create terraform.tfvars with user inputs
cat <<EOF > terraform.tfvars
resource_group_name = "$RESOURCE_GROUP"
location            = "$LOCATION"
workspace_name      = "$WORKSPACE_NAME"
aks_name            = "$AKS_NAME"
prometheus_name     = "$PROMETHEUS_NAME"
grafana_name        = "$GRAFANA_NAME"
EOF

# Create provider.tf with subscription_id
cat <<EOF > provider.tf
provider "azurerm" {
  features {}
  subscription_id = "$SUBSCRIPTION_ID"
}
EOF

# Define Terraform main configuration
cat <<EOF > main.tf
# Resource group creation
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Log Analytics Workspace creation
resource "azurerm_log_analytics_workspace" "law" {
  name                = var.workspace_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Azure Monitor Workspace (Managed Prometheus) creation
resource "azurerm_monitor_workspace" "prometheus" {
  name                = var.prometheus_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Managed Grafana creation
resource "azurerm_dashboard_grafana" "grafana" {
  name                = var.grafana_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  grafana_major_version = 10
  sku            = "Standard"
  public_network_access_enabled = true
  identity {
    type = "SystemAssigned"
  }
  azure_monitor_workspace_integrations {
    resource_id = azurerm_monitor_workspace.prometheus.id
  }
}

# Add required role assignment over resource group containing the Azure Monitor Workspace
resource "azurerm_role_assignment" "grafanarole" {
  scope = azurerm_resource_group.rg.id
  role_definition_name = "Monitoring Reader"
  principal_id = azurerm_dashboard_grafana.grafana.identity[0].principal_id
}

# Add role assignment to Grafana so an admin user can log in
resource "azurerm_role_assignment" "grafana-admin" {
  scope                = azurerm_dashboard_grafana.grafana.id
  role_definition_name = "Grafana Admin"
  principal_id         = var.adminGroupObjectIds[0]
}

# Output the grafana url for usability
output "grafana_url" {
  value = azurerm_dashboard_grafana.grafana.endpoint
}

# AKS Cluster creation with monitoring enabled
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "akslab"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_DS2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  monitor_metrics {
    annotations_allowed = null
    labels_allowed      = null
  }
}


EOF

# Define variables for the Terraform configuration
cat <<EOF > variables.tf
variable "adminGroupObjectIds" {
  type        = list(string)
  description = "A list of Object IDs of Azure Active Directory Groups which should have Admin Role on the Cluster"
  default     = ["ddaf1c7b-cf0d-49a1-9345-ebf87efd401f"]
}

variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resource deployment"
  type        = string
}

variable "workspace_name" {
  description = "Name of the Log Analytics Workspace"
  type        = string
}

variable "aks_name" {
  description = "Name of the AKS Cluster"
  type        = string
}

variable "prometheus_name" {
  description = "Name of the Managed Prometheus workspace"
  type        = string
}

variable "grafana_name" {
  description = "Name of the Managed Grafana instance"
  type        = string
}
EOF

# Run Terraform commands
terraform init
terraform apply -auto-approve
