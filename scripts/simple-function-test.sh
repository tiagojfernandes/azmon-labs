#!/bin/bash

# simple-function-test.sh
# Deploy a simple v2 function to test

set -e

# Color codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}🧪 Testing Simple v2 Function Deployment${NC}"

# Get input
read -p "$(echo -e "${CYAN}Enter your Function App name: ${NC}")" FUNCTION_APP_NAME
read -p "$(echo -e "${CYAN}Enter your Resource Group name: ${NC}")" RESOURCE_GROUP

# Create a simple test directory
echo -e "${CYAN}Creating test function...${NC}"
cd ~/azmon-labs/scripts
rm -rf function_test
mkdir function_test
cd function_test

# Create simple v2 function
cat > function_app.py << 'EOF'
import azure.functions as func
import logging

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

@app.function_name("TestTimer")
@app.timer_trigger(schedule="0 */5 * * * *", arg_name="mytimer", run_on_startup=False)
def test_timer(mytimer: func.TimerRequest) -> None:
    logging.info('Test timer function executed successfully!')
    
    if mytimer.past_due:
        logging.info('The timer is past due!')
        
    logging.info('Function completed.')
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

# Create requirements.txt
cat > requirements.txt << 'EOF'
azure-functions
EOF

echo -e "${CYAN}Files created:${NC}"
ls -la

echo -e "${CYAN}Deploying test function...${NC}"
zip -r ../test_function.zip .

az functionapp deployment source config-zip \
  --resource-group "$RESOURCE_GROUP" \
  --name "$FUNCTION_APP_NAME" \
  --src "../test_function.zip"

echo -e "${GREEN}✅ Test deployment completed${NC}"
echo -e "${CYAN}Wait 2-3 minutes, then check Azure portal for 'TestTimer' function${NC}"

# Clean up
cd ..
rm -rf function_test test_function.zip

echo -e "${YELLOW}If this works, we know v2 programming model works and can fix the VMSS function${NC}"
