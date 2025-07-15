#!/bin/bash

# test-storage-naming.sh
# Test script to validate Azure Function resource naming logic

set -e

# Color codes
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}🧪 Testing Azure Function Resource Naming Logic${NC}"
echo ""

# Test function to validate storage account prefix
test_storage_prefix() {
    local prefix="$1"
    local expected_result="$2"
    
    echo -e "${CYAN}Testing storage prefix: ${YELLOW}'$prefix'${NC}"
    
    # Check length (must be <= 16 to allow for 8-char random suffix)
    if [ ${#prefix} -gt 16 ]; then
        if [ "$expected_result" = "FAIL" ]; then
            echo -e "${GREEN}✅ PASS${NC} - Correctly detected prefix too long (${#prefix} > 16)"
            return 0
        else
            echo -e "${RED}❌ FAIL${NC} - Prefix too long (${#prefix} > 16)"
            return 1
        fi
    fi
    
    # Check for valid characters (lowercase alphanumeric only)
    if [[ ! "$prefix" =~ ^[a-z0-9]+$ ]]; then
        if [ "$expected_result" = "FAIL" ]; then
            echo -e "${GREEN}✅ PASS${NC} - Correctly detected invalid characters"
            return 0
        else
            echo -e "${RED}❌ FAIL${NC} - Invalid characters (must be lowercase alphanumeric)"
            return 1
        fi
    fi
    
    # Simulate what the final name would look like
    local simulated_suffix="abc12345"
    local final_name="${prefix}${simulated_suffix}"
    
    echo -e "  ${CYAN}Final storage name would be: ${YELLOW}'$final_name'${NC} (${#final_name} chars)"
    
    if [ ${#final_name} -gt 24 ]; then
        echo -e "${RED}❌ FAIL${NC} - Final name too long (${#final_name} > 24)"
        return 1
    fi
    
    if [ "$expected_result" = "PASS" ]; then
        echo -e "${GREEN}✅ PASS${NC} - Valid storage account prefix"
        return 0
    else
        echo -e "${RED}❌ FAIL${NC} - Expected this to fail but it passed"
        return 1
    fi
}

# Test function to validate function app prefix
test_function_prefix() {
    local prefix="$1"
    local expected_result="$2"
    
    echo -e "${CYAN}Testing function app prefix: ${YELLOW}'$prefix'${NC}"
    
    # Check length (must be <= 50 to allow for random suffix)
    if [ ${#prefix} -gt 50 ]; then
        if [ "$expected_result" = "FAIL" ]; then
            echo -e "${GREEN}✅ PASS${NC} - Correctly detected prefix too long (${#prefix} > 50)"
            return 0
        else
            echo -e "${RED}❌ FAIL${NC} - Prefix too long (${#prefix} > 50)"
            return 1
        fi
    fi
    
    # Check for valid characters (alphanumeric and hyphens)
    if [[ ! "$prefix" =~ ^[a-zA-Z0-9-]+$ ]]; then
        if [ "$expected_result" = "FAIL" ]; then
            echo -e "${GREEN}✅ PASS${NC} - Correctly detected invalid characters"
            return 0
        else
            echo -e "${RED}❌ FAIL${NC} - Invalid characters (must be alphanumeric and hyphens)"
            return 1
        fi
    fi
    
    # Simulate what the final name would look like
    local simulated_suffix="-abc12345"
    local final_name="${prefix}${simulated_suffix}"
    
    echo -e "  ${CYAN}Final function name would be: ${YELLOW}'$final_name'${NC} (${#final_name} chars)"
    
    if [ ${#final_name} -gt 60 ]; then
        echo -e "${RED}❌ FAIL${NC} - Final name too long (${#final_name} > 60)"
        return 1
    fi
    
    if [ "$expected_result" = "PASS" ]; then
        echo -e "${GREEN}✅ PASS${NC} - Valid function app prefix"
        return 0
    else
        echo -e "${RED}❌ FAIL${NC} - Expected this to fail but it passed"
        return 1
    fi
}

echo -e "${CYAN}Running test cases...${NC}"
echo ""

# Test cases
PASS_COUNT=0
TOTAL_COUNT=0

# Storage account test cases
echo -e "${CYAN}=== Storage Account Prefix Tests ===${NC}"
storage_prefixes=(
    "funcstorvmss:PASS"
    "mycompanyfunc:PASS"
    "azlabstorage:PASS"
    "func123:PASS"
    "a:PASS"
    "1234567890123456:PASS"  # Exactly 16 chars
    
    # Invalid prefixes
    "12345678901234567:FAIL"  # 17 chars (too long)
    "FuncStorage:FAIL"        # Contains uppercase
    "func-storage:FAIL"       # Contains hyphen
    "func_storage:FAIL"       # Contains underscore
    "func.storage:FAIL"       # Contains period
    "func storage:FAIL"       # Contains space
    "":FAIL                   # Empty string
)

for test_case in "${storage_prefixes[@]}"; do
    IFS=':' read -r prefix expected <<< "$test_case"
    ((TOTAL_COUNT++))
    
    if test_storage_prefix "$prefix" "$expected"; then
        ((PASS_COUNT++))
    fi
    echo ""
done

# Function app test cases
echo -e "${CYAN}=== Function App Prefix Tests ===${NC}"
function_prefixes=(
    "vmss-shutdown-fn:PASS"
    "my-company-function:PASS"
    "azlab-function:PASS"
    "func123:PASS"
    "a:PASS"
    "12345678901234567890123456789012345678901234567890:PASS"  # Exactly 50 chars
    
    # Invalid prefixes
    "123456789012345678901234567890123456789012345678901:FAIL"  # 51 chars (too long)
    "func_app:FAIL"           # Contains underscore
    "func.app:FAIL"           # Contains period
    "func app:FAIL"           # Contains space
    "func@app:FAIL"           # Contains special character
    "":FAIL                   # Empty string
)

for test_case in "${function_prefixes[@]}"; do
    IFS=':' read -r prefix expected <<< "$test_case"
    ((TOTAL_COUNT++))
    
    if test_function_prefix "$prefix" "$expected"; then
        ((PASS_COUNT++))
    fi
    echo ""
done

echo -e "${CYAN}Test Results:${NC}"
echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
echo -e "${RED}Failed: $((TOTAL_COUNT - PASS_COUNT))${NC}"
echo -e "${CYAN}Total:  $TOTAL_COUNT${NC}"

if [ $PASS_COUNT -eq $TOTAL_COUNT ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed!${NC}"
    exit 1
fi
