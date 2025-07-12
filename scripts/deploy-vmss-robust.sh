#!/bin/bash

# deploy-vmss-robust.sh
# Deploy VMSS shutdown function with robust Azure SDK handling

set -e

# Color codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}🚀 Deploying Robust VMSS Shutdown Function${NC}"

# Get input
read -p "$(echo -e "${CYAN}Enter your Function App name: ${NC}")" FUNCTION_APP_NAME
read -p "$(echo -e "${CYAN}Enter your Resource Group name: ${NC}")" RESOURCE_GROUP
read -p "$(echo -e "${CYAN}Enter your VMSS Resource Group name: ${NC}")" VMSS_RESOURCE_GROUP
read -p "$(echo -e "${CYAN}Enter your VMSS name: ${NC}")" VMSS_NAME

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
echo -e "${CYAN}Using subscription: ${SUBSCRIPTION_ID}${NC}"

# Create function directory
echo -e "${CYAN}Creating robust VMSS function...${NC}"
cd ~/azmon-labs/scripts
rm -rf vmss_robust
mkdir vmss_robust
cd vmss_robust

# Create robust VMSS function with comprehensive error handling
cat > function_app.py << 'EOF'
import azure.functions as func
import logging
import os
import sys
import traceback

# Set up detailed logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

@app.function_name("VMSSShutdownRobust")
@app.timer_trigger(schedule="0 0 19 * * *", arg_name="mytimer", run_on_startup=False)
def vmss_shutdown_robust(mytimer: func.TimerRequest) -> None:
    """
    Robust VMSS shutdown function with comprehensive error handling
    """
    utc_timestamp = mytimer.utc_timestamp.replace(tzinfo=None).isoformat()
    
    if mytimer.past_due:
        logger.info('The timer is past due!')
    
    logger.info('Robust VMSS shutdown timer triggered at %s', utc_timestamp)
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
        
        logger.info("✅ Robust VMSS shutdown function completed successfully!")
        
    except Exception as e:
        logger.error(f"💥 Unexpected error in VMSS shutdown function: {e}")
        logger.error(f"Error type: {type(e).__name__}")
        logger.error(f"Full traceback: {traceback.format_exc()}")
        raise
EOF

# Create host.json with extended timeout and detailed logging
cat > host.json << 'EOF'
{
  "version": "2.0",
  "extensionBundle": {
    "id": "Microsoft.Azure.Functions.ExtensionBundle",
    "version": "[4.*, 5.0.0)"
  },
  "functionTimeout": "00:15:00",
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

echo -e "${CYAN}Files created for robust VMSS function:${NC}"
ls -la

echo -e "${CYAN}Function content preview:${NC}"
head -n 20 function_app.py

echo -e "${CYAN}Deploying robust VMSS function...${NC}"
zip -r ../vmss_robust.zip .

az functionapp deployment source config-zip \
  --resource-group "$RESOURCE_GROUP" \
  --name "$FUNCTION_APP_NAME" \
  --src "../vmss_robust.zip"

echo -e "${GREEN}✅ Robust VMSS function deployment initiated${NC}"

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

# Wait for deployment
echo -e "${CYAN}Waiting for deployment to complete...${NC}"
sleep 45

# Check deployment
echo -e "${CYAN}Checking deployed functions...${NC}"
FUNCTIONS=$(az functionapp function list \
  --resource-group "$RESOURCE_GROUP" \
  --name "$FUNCTION_APP_NAME" \
  --query "[].name" \
  --output tsv)

echo -e "${CYAN}Deployed functions:${NC}"
echo "$FUNCTIONS"

if echo "$FUNCTIONS" | grep -q "VMSSShutdownRobust"; then
    echo -e "${GREEN}✅ VMSSShutdownRobust function successfully deployed and recognized!${NC}"
    echo -e "${CYAN}Function should appear in Azure portal shortly${NC}"
    echo -e "${YELLOW}⏰ Function is scheduled to run at 7:00 PM daily${NC}"
    
    # Test the function manually
    echo -e "${CYAN}Testing function manually...${NC}"
    az functionapp function invoke \
      --resource-group "$RESOURCE_GROUP" \
      --name "$FUNCTION_APP_NAME" \
      --function-name "VMSSShutdownRobust" || true
    
else
    echo -e "${RED}❌ VMSSShutdownRobust function not found in deployment${NC}"
    echo -e "${YELLOW}Check Azure portal and function logs for details${NC}"
fi

# Clean up
cd ..
rm -rf vmss_robust vmss_robust.zip

echo -e "${CYAN}🔍 Debugging commands:${NC}"
echo -e "1. View function logs:"
echo -e "   az functionapp log tail --resource-group $RESOURCE_GROUP --name $FUNCTION_APP_NAME"
echo -e "2. Check function details:"
echo -e "   az functionapp function show --resource-group $RESOURCE_GROUP --name $FUNCTION_APP_NAME --function-name VMSSShutdownRobust"
echo -e "3. Test function manually:"
echo -e "   az functionapp function invoke --resource-group $RESOURCE_GROUP --name $FUNCTION_APP_NAME --function-name VMSSShutdownRobust"
