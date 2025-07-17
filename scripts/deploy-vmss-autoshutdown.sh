#!/bin/bash

# deploy-vmss-autoshutdown.sh
# Deploy VMSS shutdown function with Azure SDK handling

set -e

# Color codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}🚀 Deploying  VMSS Shutdown Function${NC}"

# Check if all required parameters are provided
if [ $# -eq 5 ]; then
    # Non-interactive mode with parameters
    UTC_SCHEDULE_HOUR="$1"
    FUNCTION_APP_NAME="$2"
    RESOURCE_GROUP="$3"
    VMSS_RESOURCE_GROUP="$4"
    VMSS_NAME="$5"
    
    echo -e "${CYAN}Running in non-interactive mode with provided parameters${NC}"
    echo -e "${CYAN}UTC Schedule Hour: ${YELLOW}$UTC_SCHEDULE_HOUR${NC}"
    echo -e "${CYAN}Function App: ${YELLOW}$FUNCTION_APP_NAME${NC}"
    echo -e "${CYAN}Resource Group: ${YELLOW}$RESOURCE_GROUP${NC}"
    echo -e "${CYAN}VMSS Resource Group: ${YELLOW}$VMSS_RESOURCE_GROUP${NC}"
    echo -e "${CYAN}VMSS Name: ${YELLOW}$VMSS_NAME${NC}"
    
elif [ $# -eq 1 ]; then
    # Legacy mode with UTC hour parameter but interactive input
    UTC_SCHEDULE_HOUR="$1"
    echo -e "${CYAN}Using provided UTC hour: ${YELLOW}$UTC_SCHEDULE_HOUR${NC}"
    
    # Get input interactively
    read -p "$(echo -e "${CYAN}Enter your Function App name: ${NC}")" FUNCTION_APP_NAME
    read -p "$(echo -e "${CYAN}Enter your Resource Group name: ${NC}")" RESOURCE_GROUP
    read -p "$(echo -e "${CYAN}Enter your VMSS Resource Group name: ${NC}")" VMSS_RESOURCE_GROUP
    read -p "$(echo -e "${CYAN}Enter your VMSS name: ${NC}")" VMSS_NAME
    
elif [ $# -eq 0 ]; then
    # Full interactive mode
    UTC_SCHEDULE_HOUR="19"  # Default to 19 (7 PM UTC)
    echo -e "${CYAN}Running in interactive mode (default schedule: 19:00 UTC)${NC}"
    
    # Get input interactively
    read -p "$(echo -e "${CYAN}Enter your Function App name: ${NC}")" FUNCTION_APP_NAME
    read -p "$(echo -e "${CYAN}Enter your Resource Group name: ${NC}")" RESOURCE_GROUP
    read -p "$(echo -e "${CYAN}Enter your VMSS Resource Group name: ${NC}")" VMSS_RESOURCE_GROUP
    read -p "$(echo -e "${CYAN}Enter your VMSS name: ${NC}")" VMSS_NAME
    
else
    echo -e "${RED}Invalid number of parameters${NC}"
    echo -e "${CYAN}Usage:${NC}"
    echo -e "${CYAN}  $0                                              # Interactive mode${NC}"
    echo -e "${CYAN}  $0 <UTC_HOUR>                                   # Interactive with custom hour${NC}"
    echo -e "${CYAN}  $0 <UTC_HOUR> <FUNCTION_APP> <RG> <VMSS_RG> <VMSS_NAME>  # Non-interactive${NC}"
    exit 1
fi

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
echo -e "${CYAN}Using subscription: ${SUBSCRIPTION_ID}${NC}"
echo -e "${CYAN}Function will run at: ${YELLOW}${UTC_SCHEDULE_HOUR}:00 UTC${NC}"

# Create function directory
echo -e "${CYAN}Creating  VMSS function...${NC}"
cd ~/azmon-labs/scripts
rm -rf vmss_shutdown
mkdir vmss_shutdown
cd vmss_shutdown

# Create  VMSS function with comprehensive error handling
cat > function_app.py << EOF
import azure.functions as func
import logging
import os
import sys
import traceback

# Set up detailed logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

@app.function_name("VMSSShutdown")
@app.timer_trigger(schedule="0 0 $UTC_SCHEDULE_HOUR * * *", arg_name="mytimer", run_on_startup=False)
def vmss_shutdown(mytimer: func.TimerRequest) -> None:
    """
     VMSS shutdown function with comprehensive error handling
    """
    # Fix: Handle Azure Functions v2 timer request properly
    from datetime import datetime
    
    # Use current UTC time since v2 model handles timing differently
    utc_timestamp = datetime.utcnow().isoformat()
    
    # Check if timer is past due (this should still work in v2)
    try:
        if mytimer.past_due:
            logger.info('The timer is past due!')
    except AttributeError:
        logger.info('Timer past_due check not available in this version')
    
    logger.info(' VMSS shutdown timer triggered at %s', utc_timestamp)
    logger.info(f'Python version: {sys.version}')
    logger.info(f'Python path: {sys.path}')
    
    # Get environment variables
    subscription_id = os.environ.get('AZURE_SUBSCRIPTION_ID')
    resource_group_name = os.environ.get('RG_NAME')
    vmss_name = os.environ.get('VMSS_NAME')
    
    logger.info(f"Configuration - Subscription: {subscription_id}")
    logger.info(f"Configuration - Resource Group: {resource_group_name}")
    logger.info(f"Configuration - VMSS Name: {vmss_name}")
    
    if not all([subscription_id, resource_group_name, vmss_name]):
        logger.error("Missing required environment variables")
        logger.error("Required: AZURE_SUBSCRIPTION_ID, RG_NAME, VMSS_NAME")
        return
    
    try:
        # Test Azure SDK imports step by step
        logger.info("Testing Azure SDK imports...")
        
        try:
            from azure.identity import DefaultAzureCredential
            logger.info("✅ Successfully imported DefaultAzureCredential")
        except ImportError as e:
            logger.error(f"❌ Failed to import DefaultAzureCredential: {e}")
            return
        except Exception as e:
            logger.error(f"❌ Unexpected error importing DefaultAzureCredential: {e}")
            return
        
        try:
            from azure.mgmt.compute import ComputeManagementClient
            logger.info("✅ Successfully imported ComputeManagementClient")
        except ImportError as e:
            logger.error(f"❌ Failed to import ComputeManagementClient: {e}")
            return
        except Exception as e:
            logger.error(f"❌ Unexpected error importing ComputeManagementClient: {e}")
            return
        
        # Initialize credentials
        logger.info("Initializing Azure credentials...")
        try:
            credential = DefaultAzureCredential()
            logger.info("✅ Credentials initialized successfully")
        except Exception as e:
            logger.error(f"❌ Failed to initialize credentials: {e}")
            logger.error(f"Error details: {traceback.format_exc()}")
            return
        
        # Create compute client
        logger.info("Creating Compute Management Client...")
        try:
            compute_client = ComputeManagementClient(credential, subscription_id)
            logger.info("✅ Compute client created successfully")
        except Exception as e:
            logger.error(f"❌ Failed to create compute client: {e}")
            logger.error(f"Error details: {traceback.format_exc()}")
            return
        
        # Test connection by getting VMSS info
        logger.info(f"Testing connection - Getting VMSS info for: {vmss_name}")
        try:
            vmss = compute_client.virtual_machine_scale_sets.get(
                resource_group_name, 
                vmss_name
            )
            logger.info(f"✅ VMSS found - Name: {vmss.name}")
            logger.info(f"✅ VMSS Capacity: {vmss.sku.capacity}")
            logger.info(f"✅ VMSS Provisioning State: {vmss.provisioning_state}")
        except Exception as e:
            logger.error(f"❌ Failed to get VMSS info: {e}")
            logger.error(f"Error details: {traceback.format_exc()}")
            return
        
        # Get and process instances
        logger.info("Getting VMSS instances...")
        try:
            instances = list(compute_client.virtual_machine_scale_set_vms.list(
                resource_group_name, 
                vmss_name
            ))
            logger.info(f"✅ Found {len(instances)} instances in VMSS")
        except Exception as e:
            logger.error(f"❌ Failed to list VMSS instances: {e}")
            logger.error(f"Error details: {traceback.format_exc()}")
            return
        
        if not instances:
            logger.info("No instances found in VMSS - nothing to shutdown")
            return
        
        # Process each instance
        shutdown_count = 0
        for instance in instances:
            try:
                instance_id = instance.instance_id
                logger.info(f"Processing instance: {instance_id}")
                
                # Get instance view
                instance_view = compute_client.virtual_machine_scale_set_vms.get_instance_view(
                    resource_group_name, 
                    vmss_name, 
                    instance_id
                )
                
                # Determine power state
                power_state = "unknown"
                if instance_view.statuses:
                    for status in instance_view.statuses:
                        if status.code and status.code.startswith('PowerState/'):
                            power_state = status.code.replace('PowerState/', '')
                            break
                
                logger.info(f"Instance {instance_id} power state: {power_state}")
                
                # Shutdown if running
                if power_state in ['running', 'starting']:
                    logger.info(f"Initiating shutdown for instance {instance_id}...")
                    try:
                        operation = compute_client.virtual_machine_scale_set_vms.begin_deallocate(
                            resource_group_name,
                            vmss_name,
                            instance_id
                        )
                        logger.info(f"✅ Shutdown operation started for instance {instance_id}")
                        logger.info(f"Operation status: {operation.status()}")
                        shutdown_count += 1
                    except Exception as e:
                        logger.error(f"❌ Failed to shutdown instance {instance_id}: {e}")
                        logger.error(f"Error details: {traceback.format_exc()}")
                else:
                    logger.info(f"Instance {instance_id} is already {power_state} - no action needed")
                    
            except Exception as e:
                logger.error(f"❌ Error processing instance {instance.instance_id}: {e}")
                logger.error(f"Error details: {traceback.format_exc()}")
                continue
        
        # Summary
        if shutdown_count > 0:
            logger.info(f"🎉 Successfully initiated shutdown for {shutdown_count} instances")
        else:
            logger.info("ℹ️ No running instances found to shutdown")
        
        logger.info("✅  VMSS shutdown function completed successfully!")
        
    except Exception as e:
        logger.error(f"💥 Unexpected error in VMSS shutdown function: {e}")
        logger.error(f"Error type: {type(e).__name__}")
        logger.error(f"Full traceback: {traceback.format_exc()}")
        raise
EOF

# Create host.json with maximum allowed timeout and detailed logging
cat > host.json << 'EOF'
{
  "version": "2.0",
  "extensionBundle": {
    "id": "Microsoft.Azure.Functions.ExtensionBundle",
    "version": "[4.*, 5.0.0)"
  },
  "functionTimeout": "00:10:00",
  "logging": {
    "logLevel": {
      "default": "Information",
      "Function": "Information"
    },
    "applicationInsights": {
      "samplingSettings": {
        "isEnabled": false
      }
    }
  }
}
EOF

# Create requirements.txt with specific, compatible versions
cat > requirements.txt << 'EOF'
azure-functions>=1.18.0
azure-identity>=1.15.0,<2.0.0
azure-mgmt-compute>=30.0.0,<31.0.0
azure-mgmt-core>=1.4.0,<2.0.0
azure-core>=1.29.0,<2.0.0
EOF

echo -e "${CYAN}Files created for  VMSS function:${NC}"
ls -la

echo -e "${CYAN}Deploying  VMSS function...${NC}"
zip -r ../vmss_shutdown.zip .

az functionapp deployment source config-zip \
  --resource-group "$RESOURCE_GROUP" \
  --name "$FUNCTION_APP_NAME" \
  --src "../vmss_shutdown.zip"

echo -e "${GREEN}✅  VMSS function deployment initiated${NC}"

# Set environment variables
echo -e "${CYAN}Setting environment variables...${NC}"
az functionapp config appsettings set \
  --resource-group "$RESOURCE_GROUP" \
  --name "$FUNCTION_APP_NAME" \
  --settings \
    "AZURE_SUBSCRIPTION_ID=$SUBSCRIPTION_ID" \
    "RG_NAME=$VMSS_RESOURCE_GROUP" \
    "VMSS_NAME=$VMSS_NAME"

echo -e "${GREEN}✅ Environment variables configured${NC}"

echo -e "${CYAN} Deployment can take some time to complete...${NC}"

