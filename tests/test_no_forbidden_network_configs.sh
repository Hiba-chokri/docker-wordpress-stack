#!/bin/bash

# Property 5: No Forbidden Network Configurations
# Validates: Requirements 7.3, 7.4
#
# For any docker-compose.yml file in the project, there SHALL be no usage of
# `network: host`, `network_mode: host`, `--link`, or `links:` directives.

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

# Forbidden network patterns
FORBIDDEN_PATTERNS=(
    'network:\s*host'
    'network_mode:\s*host'
    'network_mode:\s*"host"'
    "network_mode:\s*'host'"
    '--link'
    'links:'
)

# Function to check a single file for forbidden network configurations
check_file_for_forbidden_network() {
    local file="$1"
    local found_forbidden=0
    local violations=()
    
    for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
        local matches=$(grep -nE "$pattern" "$file" 2>/dev/null || true)
        if [ -n "$matches" ]; then
            found_forbidden=1
            while IFS= read -r line; do
                violations+=("$line")
            done <<< "$matches"
        fi
    done
    
    if [ $found_forbidden -eq 1 ]; then
        echo "  Found forbidden network configuration:"
        for v in "${violations[@]}"; do
            echo "    $v"
        done
        return 1
    fi
    
    return 0
}

# Function to run property test on all docker-compose files
test_no_forbidden_network_configs() {
    echo "Running Property Test: No Forbidden Network Configurations"
    echo "============================================================"
    echo ""
    echo "Forbidden patterns:"
    echo "  - network: host"
    echo "  - network_mode: host"
    echo "  - --link"
    echo "  - links:"
    echo ""
    
    # Find all docker-compose files
    local compose_files=$(find "$PROJECT_ROOT/srcs" \( -name "docker-compose*.yml" -o -name "docker-compose*.yaml" \) -type f 2>/dev/null)
    
    if [ -z "$compose_files" ]; then
        echo -e "${GREEN}✓ No docker-compose files found yet - test passes vacuously${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo ""
        echo "============================================================"
        echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
        echo -e "${GREEN}Property 5: PASSED${NC}"
        return 0
    fi
    
    local all_passed=true
    
    for compose_file in $compose_files; do
        if [ -f "$compose_file" ]; then
            local relative_path="${compose_file#$PROJECT_ROOT/}"
            echo "Checking: $relative_path"
            
            if check_file_for_forbidden_network "$compose_file"; then
                echo -e "${GREEN}✓ $relative_path - No forbidden network configs found${NC}"
                TESTS_PASSED=$((TESTS_PASSED + 1))
            else
                echo -e "${RED}✗ $relative_path - Contains forbidden network configurations!${NC}"
                TESTS_FAILED=$((TESTS_FAILED + 1))
                FAILED_FILES+=("$relative_path")
                all_passed=false
            fi
            echo ""
        fi
    done
    
    echo "============================================================"
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    
    if [ "$all_passed" = true ]; then
        echo -e "${GREEN}Property 5: PASSED${NC}"
        return 0
    else
        echo -e "${RED}Property 5: FAILED${NC}"
        echo "Files with forbidden network configurations:"
        for f in "${FAILED_FILES[@]}"; do
            echo "  - $f"
        done
        return 1
    fi
}

# Run the test
test_no_forbidden_network_configs
exit $?
