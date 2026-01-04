#!/bin/bash

# Property 3: No Hardcoded Passwords
# Validates: Requirements 2.6, 9.3
#
# For any Dockerfile in the project, the file content SHALL NOT contain
# hardcoded password values, password assignments, or inline credentials.

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

# Patterns that indicate hardcoded passwords
# These patterns look for common password assignment patterns
PASSWORD_PATTERNS=(
    'PASSWORD\s*=\s*["\x27][^$][^"\x27]*["\x27]'  # PASSWORD="value" or PASSWORD='value' (not env vars)
    'MYSQL_PASSWORD\s*=\s*["\x27][^$][^"\x27]*["\x27]'
    'MYSQL_ROOT_PASSWORD\s*=\s*["\x27][^$][^"\x27]*["\x27]'
    'password\s*:\s*["\x27][^$][^"\x27]+["\x27]'  # password: "value" in YAML-like syntax
    '-p\s*["\x27][^$][^"\x27]+["\x27]'  # mysql -p"password"
    '--password\s*=\s*["\x27][^$][^"\x27]+["\x27]'  # --password="value"
)

# Function to check a single file for hardcoded passwords
check_file_for_passwords() {
    local file="$1"
    local found_password=0
    
    for pattern in "${PASSWORD_PATTERNS[@]}"; do
        # Use grep with extended regex, ignore case for some patterns
        if grep -qE "$pattern" "$file" 2>/dev/null; then
            # Double check it's not using environment variable substitution
            local match=$(grep -E "$pattern" "$file" 2>/dev/null | head -1)
            # Skip if it contains $ (environment variable reference)
            if [[ ! "$match" =~ \$ ]]; then
                found_password=1
                break
            fi
        fi
    done
    
    return $found_password
}

# Function to run property test on all Dockerfiles
test_no_hardcoded_passwords() {
    echo "Running Property Test: No Hardcoded Passwords"
    echo "=============================================="
    echo ""
    
    # Find all Dockerfiles in the project
    local dockerfiles=$(find "$PROJECT_ROOT/srcs" -name "Dockerfile" -type f 2>/dev/null)
    
    if [ -z "$dockerfiles" ]; then
        echo -e "${GREEN}✓ No Dockerfiles found yet - test passes vacuously${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    fi
    
    local all_passed=true
    
    for dockerfile in $dockerfiles; do
        local relative_path="${dockerfile#$PROJECT_ROOT/}"
        
        if check_file_for_passwords "$dockerfile"; then
            echo -e "${GREEN}✓ $relative_path - No hardcoded passwords found${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ $relative_path - Contains hardcoded passwords!${NC}"
            # Show the offending lines
            for pattern in "${PASSWORD_PATTERNS[@]}"; do
                grep -nE "$pattern" "$dockerfile" 2>/dev/null | while read line; do
                    if [[ ! "$line" =~ \$ ]]; then
                        echo "    Line: $line"
                    fi
                done
            done
            TESTS_FAILED=$((TESTS_FAILED + 1))
            FAILED_FILES+=("$relative_path")
            all_passed=false
        fi
    done
    
    # Also check shell scripts in tools directories
    local scripts=$(find "$PROJECT_ROOT/srcs" -name "*.sh" -type f 2>/dev/null)
    
    for script in $scripts; do
        local relative_path="${script#$PROJECT_ROOT/}"
        
        if check_file_for_passwords "$script"; then
            echo -e "${GREEN}✓ $relative_path - No hardcoded passwords found${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ $relative_path - Contains hardcoded passwords!${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            FAILED_FILES+=("$relative_path")
            all_passed=false
        fi
    done
    
    echo ""
    echo "=============================================="
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    
    if [ "$all_passed" = true ]; then
        echo -e "${GREEN}Property 3: PASSED${NC}"
        return 0
    else
        echo -e "${RED}Property 3: FAILED${NC}"
        echo "Files with hardcoded passwords:"
        for f in "${FAILED_FILES[@]}"; do
            echo "  - $f"
        done
        return 1
    fi
}

# Run the test
test_no_hardcoded_passwords
exit $?
