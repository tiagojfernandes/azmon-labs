#!/bin/bash

# deploy-vmss-final.sh
# Deploy the final optimized VMSS shutdown function

set -e

# Color codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}🚀 Deploying Final VMSS Shutdown Function${NC}"

# Get input
read -p "$(echo -e "${CYAN}Enter your Function App name: ${NC}")" FUNCTION_APP_NAME
read -p "$(echo -e "${CYAN}Enter your Resource Group name: ${NC}")" RESOURCE_GROUP
read -p "$(echo -e "${CYAN}Enter your VMSS Resource Group name: ${NC}")" VMSS_RESOURCE_GROUP
read -p "$(echo -e "${CYAN}Enter your VMSS name: ${NC}")" VMSS_NAME

# Get subscription ID
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
echo -e "${CYAN}Using subscription: ${SUBSCRIPTION_ID}${NC}"

# Create function directory
echo -e "${CYAN}Creating final VMSS function...${NC}"
cd ~/azmon-labs/scripts
rm -rf vmss_final
mkdir vmss_final
cd vmss_final

# Create optimized VMSS function
cat > function_app.py << 'EOF'
import azure.functions as func
import logging
import os

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

@app.function_name("VMSSShutdown")
@app.timer_trigger(schedule="0 0 19 * * *", arg_name="mytimer", run_on_startup=False)
def vmss_shutdown_timer(mytimer: func.TimerRequest) -> None:
    """
    Optimized VMSS shutdown function
    Shuts down all VMs in the specified VMSS at scheduled time
    """
    utc_timestamp = mytimer.utc_timestamp.replace(tzinfo=None).isoformat()
    
    if mytimer.past_due:
        logger.info('The timer is past due!')
    
    logger.info('VMSS shutdown timer triggered at %s', utc_timestamp)
    
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
        # Import Azure SDK components (lazy loading to avoid startup issues)
        logger.info("Importing Azure SDK components...")
        from azure.identity import DefaultAzureCredential
        from azure.mgmt.compute import ComputeManagementClient
        logger.info("✅ Azure SDK imports successful")
        
        # Initialize Azure credentials
        logger.info("Initializing Azure credentials...")
        credential = DefaultAzureCredential()
        logger.info("✅ Credentials initialized")
        
        # Create compute client
        logger.info("Creating Compute Management Client...")
        compute_client = ComputeManagementClient(credential, subscription_id)
        logger.info("✅ Compute client created")
        
        # Get VMSS information
        logger.info(f"Getting VMSS information for: {vmss_name}")
        vmss = compute_client.virtual_machine_scale_sets.get(
            resource_group_name, 
            vmss_name
        )
        logger.info(f"✅ VMSS found - Capacity: {vmss.sku.capacity}, State: {vmss.provisioning_state}")
        
        # Get VMSS instances
        logger.info("Getting VMSS instances...")
        instances = list(compute_client.virtual_machine_scale_set_vms.list(
            resource_group_name, 
            vmss_name
        ))
        
        if not instances:
            logger.info("No instances found in VMSS")
            return
        
        logger.info(f"Found {len(instances)} instances in VMSS")
        
        # Process each instance
        shutdown_count = 0
        for instance in instances:
            try:
                instance_id = instance.instance_id
                logger.info(f"Processing instance: {instance_id}")
                
                # Get instance power state
                instance_view = compute_client.virtual_machine_scale_set_vms.get_instance_view(
                    resource_group_name, 
                    vmss_name, 
                    instance_id
                )
                
                power_state = "unknown"
                if instance_view.statuses:
                    for status in instance_view.statuses:
                        if status.code and status.code.startswith('PowerState/'):
                            power_state = status.code.replace('PowerState/', '')
                            break
                
                logger.info(f"Instance {instance_id} power state: {power_state}")
                
                # Shutdown if running
                if power_state in ['running', 'starting']:
                    logger.info(f"Shutting down instance {instance_id}...")
                    compute_client.virtual_machine_scale_set_vms.begin_deallocate(
                        resource_group_name,
                        vmss_name,
                        instance_id
                    )
                    shutdown_count += 1
                    logger.info(f"✅ Instance {instance_id} shutdown initiated")
                else:
                    logger.info(f"Instance {instance_id} already {power_state}")
                    
            except Exception as e:
                logger.error(f"❌ Error processing instance {instance.instance_id}: {str(e)}")
                continue
        
        # Summary
        if shutdown_count > 0:
            logger.info(f"🎉 Successfully initiated shutdown for {shutdown_count} instances")
        else:
            logger.info("ℹ️ No running instances found to shutdown")
        
        logger.info("✅ VMSS shutdown function completed successfully!")
        
    except ImportError as e:
        logger.error(f"❌ Azure SDK import error: {str(e)}")
        logger.error("Check that azure-identity and azure-mgmt-compute are properly installed")
        raise
    except Exception as e:
        logger.error(f"❌ Error in VMSS shutdown function: {str(e)}")
        logger.error(f"Error type: {type(e).__name__}")
        raise
EOF

# Create optimized host.json
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
      "default": "Information"
    }
  }
}
EOF

# Create requirements.txt with proven working versions
cat > requirements.txt << 'EOF'
azure-functions>=1.18.0
azure-identity>=1.15.0
azure-mgmt-compute>=30.0.0
azure-mgmt-core>=1.4.0
EOF

echo -e "${CYAN}Files created for final VMSS function:${NC}"
ls -la
echo ""
echo -e "${CYAN}Function preview:${NC}"
head -n 25 function_app.py

echo -e "${CYAN}Deploying final VMSS function...${NC}"
zip -r ../vmss_final.zip .

az functionapp deployment source config-zip \
  --resource-group "$RESOURCE_GROUP" \
  --name "$FUNCTION_APP_NAME" \
  --src "../vmss_final.zip"

echo -e "${GREEN}✅ Final VMSS function deployment initiated${NC}"

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

# Check deployment status
echo -e "${CYAN}Checking deployed functions...${NC}"
FUNCTIONS=$(az functionapp function list \
  --resource-group "$RESOURCE_GROUP" \
  --name "$FUNCTION_APP_NAME" \
  --query "[].name" \
  --output tsv)

echo -e "${CYAN}Deployed functions:${NC}"
echo "$FUNCTIONS"

if echo "$FUNCTIONS" | grep -q "VMSSShutdown"; then
    echo -e "${GREEN}✅ VMSSShutdown function successfully deployed!${NC}"
    echo -e "${YELLOW}⏰ Function scheduled to run daily at 7:00 PM UTC${NC}"
    echo -e "${CYAN}Check Azure portal to confirm function appears${NC}"
else
    echo -e "${RED}❌ VMSSShutdown function not found${NC}"
    echo -e "${YELLOW}Check function logs for deployment issues${NC}"
fi

# Clean up
cd ..
rm -rf vmss_final vmss_final.zip

echo -e "${CYAN}🔧 Manual testing command:${NC}"
echo "az functionapp function invoke --resource-group $RESOURCE_GROUP --name $FUNCTION_APP_NAME --function-name VMSSShutdown"
echo ""
echo -e "${CYAN}📋 Key improvements in this version:${NC}"
echo "• Lazy loading of Azure SDK imports to avoid startup issues"
echo "• Better error handling with specific import error detection"
echo "• Optimized logging with more detailed status messages"
echo "• Cleaner function logic with improved instance processing"
echo "• Proven Azure SDK versions that work with Functions v2 model"
