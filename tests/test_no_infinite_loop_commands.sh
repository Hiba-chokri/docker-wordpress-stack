#!/bin/bash

# Property 6: No Infinite Loop Commands
# Validates: Requirements 8.1, 8.2
#
# For any Dockerfile or shell script in the project, there SHALL be no usage of
# infinite loop patterns including `tail -f`, `sleep infinity`, `while true`,
# or `bash` as the sole CMD/ENTRYPOINT.

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

# Forbidden infinite loop patterns
FORBIDDEN_PATTERNS=(
    "tail -f"
    "tail -F"
    "sleep infinity"
    "while true"
    "while :;"
    "while 1"
)

# Function to check if a file contains forbidden infinite loop patterns
check_file_for_infinite_loops() {
    local file="$1"
    local found_issues=false
    
    for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
        if grep -qE "$pattern" "$file" 2>/dev/null; then
            echo "  Found forbidden pattern: '$pattern'"
            found_issues=true
        fi
    done
    
    if [ "$found_issues" = true ]; then
        return 1
    fi
    return 0
}

# Function to check Dockerfile for bash-only CMD/ENTRYPOINT
check_dockerfile_for_bash_only() {
    local file="$1"
    
    # Check for CMD ["bash"] or CMD bash or ENTRYPOINT ["bash"] or ENTRYPOINT bash
    # These patterns indicate using bash as the sole command (hacky workaround)
    if grep -qE '^\s*(CMD|ENTRYPOINT)\s+\[?\s*"?bash"?\s*\]?\s*$' "$file" 2>/dev/null; then
        echo "  Found forbidden pattern: bash as sole CMD/ENTRYPOINT"
        return 1
    fi
    
    # Check for CMD ["/bin/bash"] or ENTRYPOINT ["/bin/bash"]
    if grep -qE '^\s*(CMD|ENTRYPOINT)\s+\[?\s*"?/bin/bash"?\s*\]?\s*$' "$file" 2>/dev/null; then
        echo "  Found forbidden pattern: /bin/bash as sole CMD/ENTRYPOINT"
        return 1
    fi
    
    return 0
}

# Function to run property test on all Dockerfiles
test_dockerfiles_no_infinite_loops() {
    echo "Checking Dockerfiles for infinite loop patterns..."
    echo ""
    
    local dockerfiles=$(find "$PROJECT_ROOT/srcs" -name "Dockerfile" -type f 2>/dev/null)
    
    if [ -z "$dockerfiles" ]; then
        echo -e "${GREEN}✓ No Dockerfiles found yet - test passes vacuously${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    fi
    
    for dockerfile in $dockerfiles; do
        local relative_path="${dockerfile#$PROJECT_ROOT/}"
        echo "Checking: $relative_path"
        
        local file_passed=true
        
        if ! check_file_for_infinite_loops "$dockerfile"; then
            file_passed=false
        fi
        
        if ! check_dockerfile_for_bash_only "$dockerfile"; then
            file_passed=false
        fi
        
        if [ "$file_passed" = true ]; then
            echo -e "${GREEN}✓ $relative_path - PASSED${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ $relative_path - FAILED${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            FAILED_FILES+=("$relative_path")
        fi
        echo ""
    done
}

# Function to run property test on all shell scripts
test_shell_scripts_no_infinite_loops() {
    echo "Checking shell scripts for infinite loop patterns..."
    echo ""
    
    local scripts=$(find "$PROJECT_ROOT/srcs" -name "*.sh" -type f 2>/dev/null)
    
    if [ -z "$scripts" ]; then
        echo -e "${GREEN}✓ No shell scripts found yet - test passes vacuously${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    fi
    
    for script in $scripts; do
        local relative_path="${script#$PROJECT_ROOT/}"
        echo "Checking: $relative_path"
        
        if check_file_for_infinite_loops "$script"; then
            echo -e "${GREEN}✓ $relative_path - PASSED${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ $relative_path - FAILED${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            FAILED_FILES+=("$relative_path")
        fi
        echo ""
    done
}

# Main test function
test_no_infinite_loop_commands() {
    echo "Running Property Test: No Infinite Loop Commands"
    echo "================================================="
    echo ""
    echo "Forbidden patterns:"
    for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
        echo "  - $pattern"
    done
    echo "  - bash as sole CMD/ENTRYPOINT"
    echo "  - /bin/bash as sole CMD/ENTRYPOINT"
    echo ""
    
    test_dockerfiles_no_infinite_loops
    test_shell_scripts_no_infinite_loops
    
    echo "================================================="
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    
    if [ ${#FAILED_FILES[@]} -eq 0 ]; then
        echo -e "${GREEN}Property 6: PASSED${NC}"
        return 0
    else
        echo -e "${RED}Property 6: FAILED${NC}"
        echo "Files with infinite loop patterns:"
        for f in "${FAILED_FILES[@]}"; do
            echo "  - $f"
        done
        return 1
    fi
}

# Run the test
test_no_infinite_loop_commands
exit $?
