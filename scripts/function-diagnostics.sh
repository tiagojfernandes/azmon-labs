#!/bin/bash

# function-diagnostics.sh
# Diagnostic script for Azure Function issues

set -e

# Color codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}🔍 Azure Function Diagnostics${NC}"

# Get the function app name from user
read -p "$(echo -e "${CYAN}Enter your Function App name: ${NC}")" FUNCTION_APP_NAME
read -p "$(echo -e "${CYAN}Enter your Resource Group name: ${NC}")" RESOURCE_GROUP

echo -e "${CYAN}📋 Gathering Function App information...${NC}"

# 1. Check basic function app info
echo -e "${CYAN}1. Function App Status:${NC}"
az functionapp show --resource-group "$RESOURCE_GROUP" --name "$FUNCTION_APP_NAME" --query "{name:name,state:state,kind:kind,runtime:siteConfig.linuxFxVersion}" -o table

# 2. Check all app settings
echo -e "${CYAN}2. App Settings:${NC}"
az functionapp config appsettings list --resource-group "$RESOURCE_GROUP" --name "$FUNCTION_APP_NAME" --query "[].{Name:name,Value:value}" -o table

# 3. Check if functions are listed
echo -e "${CYAN}3. Attempting to list functions:${NC}"
az functionapp function list --resource-group "$RESOURCE_GROUP" --name "$FUNCTION_APP_NAME" -o table 2>/dev/null || echo "No functions found or command failed"

# 4. Check deployment status (alternative approach)
echo -e "${CYAN}4. Deployment information:${NC}"
az functionapp deployment source show --resource-group "$RESOURCE_GROUP" --name "$FUNCTION_APP_NAME" 2>/dev/null || echo "Deployment source info not available"

# 5. Check kudu/scm site status
echo -e "${CYAN}5. Checking deployment site:${NC}"
az functionapp deployment list-publishing-credentials --resource-group "$RESOURCE_GROUP" --name "$FUNCTION_APP_NAME" --query "scmUri" -o tsv 2>/dev/null || echo "SCM URI not available"

# 6. Check if the function runtime is working
echo -e "${CYAN}6. Function App runtime check:${NC}"
az functionapp show --resource-group "$RESOURCE_GROUP" --name "$FUNCTION_APP_NAME" --query "{hostingEnvironment:hostingEnvironmentProfile.name,runtime:siteConfig.linuxFxVersion,version:functionVersion,extensionVersion:functionExtensionVersion}" -o table

# 7. Try to get master key (indicates if function app is accessible)
echo -e "${CYAN}7. Testing Function App accessibility:${NC}"
az functionapp keys list --resource-group "$RESOURCE_GROUP" --name "$FUNCTION_APP_NAME" --query "masterKey" -o tsv 2>/dev/null && echo "✅ Function App is accessible" || echo "❌ Function App accessibility issue"

echo ""
echo -e "${YELLOW}💡 Troubleshooting Tips:${NC}"
echo -e "${CYAN}   - If state is not 'Running', the app may be starting up${NC}"
echo -e "${CYAN}   - FUNCTIONS_WORKER_RUNTIME should be 'python'${NC}"
echo -e "${CYAN}   - WEBSITE_RUN_FROM_PACKAGE should be '1'${NC}"
echo -e "${CYAN}   - If no functions are listed, there's a deployment structure issue${NC}"
echo ""
echo -e "${CYAN}🔧 Next steps if no functions found:${NC}"
echo -e "${CYAN}   1. Check the 'function_app.py' uses the correct function signature${NC}"
echo -e "${CYAN}   2. Verify 'function.json' has the correct timer trigger format${NC}"
echo -e "${CYAN}   3. Try deleting and recreating the Function App${NC}"
