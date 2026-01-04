#!/bin/bash

# Property 2: No Latest Tag Usage
# Validates: Requirements 2.4
#
# For any Dockerfile or docker-compose.yml file in the project, there SHALL be
# no reference to the :latest tag for any image.

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

# Function to check a single file for :latest tag usage
check_file_for_latest_tag() {
    local file="$1"
    
    # Search for :latest pattern in FROM instructions and image references
    # Patterns to check:
    # - FROM image:latest
    # - image: something:latest
    # - :latest anywhere in image context
    
    local latest_matches=$(grep -n ":latest" "$file" 2>/dev/null || true)
    
    if [ -n "$latest_matches" ]; then
        echo "  Found :latest tag usage:"
        echo "$latest_matches" | while read -r line; do
            echo "    $line"
        done
        return 1
    fi
    
    return 0
}

# Function to run property test on all relevant files
test_no_latest_tag() {
    echo "Running Property Test: No Latest Tag Usage"
    echo "=============================================="
    echo ""
    echo "Checking for :latest tag in Dockerfiles and docker-compose files..."
    echo ""
    
    # Find all Dockerfiles and docker-compose files
    local dockerfiles=$(find "$PROJECT_ROOT/srcs" -name "Dockerfile" -type f 2>/dev/null)
    local compose_files=$(find "$PROJECT_ROOT/srcs" -name "docker-compose*.yml" -o -name "docker-compose*.yaml" -type f 2>/dev/null)
    
    local all_files="$dockerfiles $compose_files"
    
    if [ -z "$(echo $all_files | tr -d ' ')" ]; then
        echo -e "${GREEN}✓ No Dockerfiles or docker-compose files found yet - test passes vacuously${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    fi
    
    local all_passed=true
    
    # Check Dockerfiles
    for dockerfile in $dockerfiles; do
        if [ -f "$dockerfile" ]; then
            local relative_path="${dockerfile#$PROJECT_ROOT/}"
            echo "Checking: $relative_path"
            
            if check_file_for_latest_tag "$dockerfile"; then
                echo -e "${GREEN}✓ $relative_path - PASSED${NC}"
                TESTS_PASSED=$((TESTS_PASSED + 1))
            else
                echo -e "${RED}✗ $relative_path - FAILED${NC}"
                TESTS_FAILED=$((TESTS_FAILED + 1))
                FAILED_FILES+=("$relative_path")
                all_passed=false
            fi
            echo ""
        fi
    done
    
    # Check docker-compose files
    for compose_file in $compose_files; do
        if [ -f "$compose_file" ]; then
            local relative_path="${compose_file#$PROJECT_ROOT/}"
            echo "Checking: $relative_path"
            
            if check_file_for_latest_tag "$compose_file"; then
                echo -e "${GREEN}✓ $relative_path - PASSED${NC}"
                TESTS_PASSED=$((TESTS_PASSED + 1))
            else
                echo -e "${RED}✗ $relative_path - FAILED${NC}"
                TESTS_FAILED=$((TESTS_FAILED + 1))
                FAILED_FILES+=("$relative_path")
                all_passed=false
            fi
            echo ""
        fi
    done
    
    echo "=============================================="
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    
    if [ "$all_passed" = true ]; then
        echo -e "${GREEN}Property 2: PASSED${NC}"
        return 0
    else
        echo -e "${RED}Property 2: FAILED${NC}"
        echo "Files with :latest tag usage:"
        for f in "${FAILED_FILES[@]}"; do
            echo "  - $f"
        done
        return 1
    fi
}

# Run the test
test_no_latest_tag
exit $?
