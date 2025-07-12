#!/bin/bash

# test-vmss-simple.sh
# Test a simplified VMSS function

set -e

# Color codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}🧪 Testing Simplified VMSS Function${NC}"

# Get input
read -p "$(echo -e "${CYAN}Enter your Function App name: ${NC}")" FUNCTION_APP_NAME
read -p "$(echo -e "${CYAN}Enter your Resource Group name: ${NC}")" RESOURCE_GROUP

# Create a simple test directory
echo -e "${CYAN}Creating simplified VMSS function...${NC}"
cd ~/azmon-labs/scripts
rm -rf vmss_test
mkdir vmss_test
cd vmss_test

# Create simplified VMSS function (without the complex Azure SDK imports)
cat > function_app.py << 'EOF'
import azure.functions as func
import logging
import os

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

@app.function_name("VMSSShutdown")
@app.timer_trigger(schedule="0 0 19 * * *", arg_name="mytimer", run_on_startup=False)
def vmss_shutdown_timer(mytimer: func.TimerRequest) -> None:
    """
    Simplified VMSS shutdown function for testing
    """
    utc_timestamp = mytimer.utc_timestamp.replace(tzinfo=None).isoformat()
    
    if mytimer.past_due:
        logging.info('The timer is past due!')
    
    logging.info('VMSS shutdown timer triggered at %s', utc_timestamp)
    
    # Get environment variables (for testing)
    subscription_id = os.environ.get('AZURE_SUBSCRIPTION_ID')
    resource_group_name = os.environ.get('RG_NAME')
    vmss_name = os.environ.get('VMSS_NAME')
    
    logging.info(f"Environment check - Subscription: {subscription_id}")
    logging.info(f"Environment check - RG: {resource_group_name}")
    logging.info(f"Environment check - VMSS: {vmss_name}")
    
    if not all([subscription_id, resource_group_name, vmss_name]):
        logging.error("Missing required environment variables")
        return
    
    # TODO: Add actual VMSS shutdown logic later
    logging.info(f"Would shutdown VMSS: {vmss_name} in RG: {resource_group_name}")
    logging.info("VMSS shutdown function completed successfully!")
EOF

# Create simple host.json
cat > host.json << 'EOF'
{
  "version": "2.0",
  "extensionBundle": {
    "id": "Microsoft.Azure.Functions.ExtensionBundle",
    "version": "[4.*, 5.0.0)"
  },
  "functionTimeout": "00:05:00"
}
EOF

# Create minimal requirements.txt
cat > requirements.txt << 'EOF'
azure-functions
EOF

echo -e "${CYAN}Files created:${NC}"
ls -la

echo -e "${CYAN}Deploying simplified VMSS function...${NC}"
zip -r ../vmss_test.zip .

az functionapp deployment source config-zip \
  --resource-group "$RESOURCE_GROUP" \
  --name "$FUNCTION_APP_NAME" \
  --src "../vmss_test.zip"

echo -e "${GREEN}✅ Simplified VMSS deployment completed${NC}"
echo -e "${CYAN}Check Azure portal for 'VMSSShutdown' function${NC}"

# Clean up
cd ..
rm -rf vmss_test vmss_test.zip

echo -e "${YELLOW}If this works, the issue is with the Azure SDK dependencies${NC}"
