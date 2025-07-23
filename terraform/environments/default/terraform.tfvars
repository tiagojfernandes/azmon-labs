# Default environment variables
# Core Configuration
resource_group_name = "rg-azmon-lab"
location            = "East US"
workspace_name      = "azmon-workspace"
subscription_id     = ""
user_timezone       = "1900"
aks_name            = "aks-azmon"
grafana_name        = "managed-gf"
prom_name           = "managed-pm"

# Network Configuration
subnet_name = "vmss_subnet"

# Unified Admin Configuration for all VMs and VMSS
admin_username = "azureuser"
admin_password = ""  # Will be set by init-lab.sh script

# VMSS Configuration
vmss_name = "vmss-win"

# Ubuntu VM Configuration
ubuntu_vm_name = "vm-ubuntu-lab"
ubuntu_vm_size = "Standard_B2s"

# Windows VM Configuration
windows_vm_name = "vm-windows-lab"
windows_vm_size = "Standard_B2s"

# Red Hat VM Configuration
redhat_vm_name = "vm-redhat-lab"
redhat_vm_size = "Standard_B2s"

