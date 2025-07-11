#!/bin/bash

# manual-function-deploy.sh
# Manual script to redeploy just the Azure Function

set -e

# Color codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}🔄 Manual Azure Function Deployment${NC}"

# Get the function app name from user
read -p "$(echo -e "${CYAN}Enter your Function App name (from Azure portal): ${NC}")" FUNCTION_APP_NAME
read -p "$(echo -e "${CYAN}Enter your Resource Group name: ${NC}")" RESOURCE_GROUP

echo -e "${CYAN}📦 Preparing function deployment...${NC}"
cd ~/azmon-labs/scripts/function_code

# Verify files exist
echo -e "${CYAN}Checking function files...${NC}"
if [ ! -f "function_app.py" ]; then
  echo -e "${RED}ERROR: function_app.py not found${NC}"
  exit 1
fi

if [ ! -f "VMSSShutdown/function.json" ]; then
  echo -e "${RED}ERROR: VMSSShutdown/function.json not found${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Function files found${NC}"

# Create zip with verbose output
echo -e "${CYAN}Creating deployment package with detailed listing...${NC}"
rm -f ../function_deployment.zip
zip -rv ../function_deployment.zip . -x "*.git*" "*.DS_Store*" "*.pyc" "__pycache__/*" "local.settings.json"

echo -e "${CYAN}Verifying package contents:${NC}"
unzip -l ../function_deployment.zip

# Deploy with verbose output
echo -e "${CYAN}Deploying to Azure Function App: ${YELLOW}$FUNCTION_APP_NAME${NC}"
az functionapp deployment source config-zip \
  --resource-group "$RESOURCE_GROUP" \
  --name "$FUNCTION_APP_NAME" \
  --src "../function_deployment.zip" \
  --verbose

echo -e "${GREEN}✅ Deployment completed${NC}"

# Add diagnostic checks
echo -e "${CYAN}🔍 Running diagnostics...${NC}"

# Check function app status
echo -e "${CYAN}Checking Function App status...${NC}"
az functionapp show --resource-group "$RESOURCE_GROUP" --name "$FUNCTION_APP_NAME" --query "{state:state,runtimeVersion:siteConfig.linuxFxVersion,functionVersion:functionVersion}" -o table

# Check function app settings
echo -e "${CYAN}Checking critical app settings...${NC}"
az functionapp config appsettings list --resource-group "$RESOURCE_GROUP" --name "$FUNCTION_APP_NAME" --query "[?name=='FUNCTIONS_WORKER_RUNTIME' || name=='WEBSITE_RUN_FROM_PACKAGE' || name=='FUNCTIONS_EXTENSION_VERSION'].{Name:name,Value:value}" -o table

# Check deployment status
echo -e "${CYAN}Checking deployment status...${NC}"
az functionapp deployment list-publishing-credentials --resource-group "$RESOURCE_GROUP" --name "$FUNCTION_APP_NAME" --query "scmUri" -o tsv

# Force restart the function app
echo -e "${CYAN}Restarting Function App to refresh...${NC}"
az functionapp restart --resource-group "$RESOURCE_GROUP" --name "$FUNCTION_APP_NAME"

echo -e "${CYAN}Please check the Azure portal Functions tab in a few minutes${NC}"

# Clean up
#rm -f ../function_deployment.zip

echo -e "${CYAN}🔍 Next steps:${NC}"
echo -e "${CYAN}1. Wait 2-3 minutes for Azure to process the deployment${NC}"
echo -e "${CYAN}2. Refresh the Azure portal${NC}"
echo -e "${CYAN}3. Check the Functions tab - you should see 'VMSSShutdown'${NC}"
echo -e "${CYAN}4. If still not visible, check the Function App logs for errors${NC}"
