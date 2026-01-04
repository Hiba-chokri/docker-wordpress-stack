#!/bin/bash

# Property 1: Base Image Compliance
# Validates: Requirements 2.2, 2.3
#
# For any Dockerfile in the project, the FROM instruction SHALL specify either
# debian:bullseye, debian:bookworm, alpine:3.18, or alpine:3.19 (penultimate stable versions),
# and SHALL NOT reference any other Docker images.

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

# Allowed base images (penultimate stable versions)
ALLOWED_IMAGES=(
    "debian:bullseye"
    "debian:bookworm"
    "alpine:3.18"
    "alpine:3.19"
)

# Function to check if a base image is allowed
is_allowed_image() {
    local image="$1"
    for allowed in "${ALLOWED_IMAGES[@]}"; do
        if [ "$image" = "$allowed" ]; then
            return 0
        fi
    done
    return 1
}

# Function to check a single Dockerfile for base image compliance
check_dockerfile_base_image() {
    local file="$1"
    
    # Extract FROM instruction (first non-comment, non-ARG FROM line)
    local from_line=$(grep -E "^FROM\s+" "$file" | head -1)
    
    if [ -z "$from_line" ]; then
        echo "  Warning: No FROM instruction found"
        return 1
    fi
    
    # Extract the image name (second field after FROM)
    local image=$(echo "$from_line" | awk '{print $2}')
    
    # Remove any AS alias if present
    image=$(echo "$image" | sed 's/\s*AS.*//i')
    
    if is_allowed_image "$image"; then
        echo "  Base image: $image (allowed)"
        return 0
    else
        echo "  Base image: $image (NOT ALLOWED)"
        return 1
    fi
}

# Function to run property test on all Dockerfiles
test_base_image_compliance() {
    echo "Running Property Test: Base Image Compliance"
    echo "=============================================="
    echo ""
    echo "Allowed base images:"
    for img in "${ALLOWED_IMAGES[@]}"; do
        echo "  - $img"
    done
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
        echo "Checking: $relative_path"
        
        if check_dockerfile_base_image "$dockerfile"; then
            echo -e "${GREEN}✓ $relative_path - PASSED${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ $relative_path - FAILED${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            FAILED_FILES+=("$relative_path")
            all_passed=false
        fi
        echo ""
    done
    
    echo "=============================================="
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    
    if [ "$all_passed" = true ]; then
        echo -e "${GREEN}Property 1: PASSED${NC}"
        return 0
    else
        echo -e "${RED}Property 1: FAILED${NC}"
        echo "Files with non-compliant base images:"
        for f in "${FAILED_FILES[@]}"; do
            echo "  - $f"
        done
        return 1
    fi
}

# Run the test
test_base_image_compliance
exit $?
