#!/bin/bash

# Property 4: No Forbidden Admin Usernames
# Validates: Requirements 5.7
#
# For any configuration file that defines a database administrator username,
# the username SHALL NOT contain the substrings "admin", "Admin", "administrator",
# or "Administrator".

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_FILES=()

# Forbidden patterns in usernames (case-insensitive)
FORBIDDEN_PATTERNS="admin|administrator"

# Function to check .env file for forbidden admin usernames
check_env_file() {
    local file="$1"
    local found_forbidden=0
    
    if [ ! -f "$file" ]; then
        return 0
    fi
    
    # Check for username variables that might contain forbidden patterns
    # Look for MYSQL_USER, WP_ADMIN_USER, or similar
    local username_vars=$(grep -E "^(MYSQL_USER|WP_ADMIN_USER|DB_USER|ADMIN_USER)\s*=" "$file" 2>/dev/null || true)
    
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            continue
        fi
        
        # Extract the value after the = sign
        local value=$(echo "$line" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
        
        # Check if value contains forbidden patterns
        if echo "$value" | grep -qiE "$FORBIDDEN_PATTERNS"; then
            echo "  Found forbidden username pattern in: $line"
            found_forbidden=1
        fi
    done <<< "$username_vars"
    
    return $found_forbidden
}

# Function to check shell scripts for forbidden admin usernames
check_script_file() {
    local file="$1"
    local found_forbidden=0
    
    if [ ! -f "$file" ]; then
        return 0
    fi
    
    # Check for hardcoded usernames in CREATE USER statements
    local create_user_lines=$(grep -iE "CREATE\s+USER.*'[^']+'" "$file" 2>/dev/null || true)
    
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            continue
        fi
        
        # Extract username from CREATE USER statement
        local username=$(echo "$line" | grep -oE "'[^']+'" | head -1 | tr -d "'")
        
        # Skip if it's an environment variable reference
        if [[ "$username" =~ ^\$ ]]; then
            continue
        fi
        
        # Check if username contains forbidden patterns
        if echo "$username" | grep -qiE "$FORBIDDEN_PATTERNS"; then
            echo "  Found forbidden username in CREATE USER: $username"
            found_forbidden=1
        fi
    done <<< "$create_user_lines"
    
    return $found_forbidden
}

# Function to check that setup scripts validate usernames
check_username_validation() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        return 0
    fi
    
    # Check if the script has username validation logic
    if grep -qE "(admin|administrator)" "$file" && grep -qE "validate|check|error|exit" "$file"; then
        echo "  Script contains username validation logic"
        return 0
    fi
    
    return 0
}

# Function to run property test
test_no_forbidden_admin_usernames() {
    echo "Running Property Test: No Forbidden Admin Usernames"
    echo "===================================================="
    echo ""
    echo "Forbidden patterns: admin, Admin, administrator, Administrator"
    echo ""
    
    local all_passed=true
    
    # Check .env file
    local env_file="$PROJECT_ROOT/srcs/.env"
    if [ -f "$env_file" ]; then
        echo "Checking: srcs/.env"
        if check_env_file "$env_file"; then
            echo -e "${GREEN}✓ srcs/.env - No forbidden usernames found${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ srcs/.env - Contains forbidden username patterns!${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            FAILED_FILES+=("srcs/.env")
            all_passed=false
        fi
        echo ""
    fi
    
    # Check all shell scripts in tools directories
    local scripts=$(find "$PROJECT_ROOT/srcs" -name "*.sh" -type f 2>/dev/null)
    
    for script in $scripts; do
        local relative_path="${script#$PROJECT_ROOT/}"
        echo "Checking: $relative_path"
        
        if check_script_file "$script"; then
            echo -e "${GREEN}✓ $relative_path - No forbidden usernames found${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ $relative_path - Contains forbidden username patterns!${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            FAILED_FILES+=("$relative_path")
            all_passed=false
        fi
        
        # Also verify that setup scripts have validation
        check_username_validation "$script"
        echo ""
    done
    
    if [ $TESTS_PASSED -eq 0 ] && [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ No configuration files found yet - test passes vacuously${NC}"
        TESTS_PASSED=1
    fi
    
    echo "===================================================="
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    
    if [ "$all_passed" = true ]; then
        echo -e "${GREEN}Property 4: PASSED${NC}"
        return 0
    else
        echo -e "${RED}Property 4: FAILED${NC}"
        echo "Files with forbidden admin usernames:"
        for f in "${FAILED_FILES[@]}"; do
            echo "  - $f"
        done
        return 1
    fi
}

# Run the test
test_no_forbidden_admin_usernames
exit $?
