#!/bin/bash

# Property 7: All Services Have Restart Policy
# Validates: Requirements 3.6, 4.5, 5.5, 8.4
#
# For any service defined in docker-compose.yml, the service SHALL have
# `restart: always` or `restart: unless-stopped` configured.

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
FAILED_SERVICES=()

# Allowed restart policies
ALLOWED_RESTART_POLICIES=(
    'always'
    'unless-stopped'
)

# Function to check if a restart policy is allowed
is_allowed_restart_policy() {
    local policy="$1"
    for allowed in "${ALLOWED_RESTART_POLICIES[@]}"; do
        if [ "$policy" = "$allowed" ]; then
            return 0
        fi
    done
    return 1
}

# Function to extract services and their restart policies from docker-compose.yml
check_restart_policies() {
    local file="$1"
    local all_passed=true
    local in_services=false
    local current_service=""
    local service_indent=""
    local found_restart=""
    local services_found=()
    local services_with_restart=()
    
    # Parse the docker-compose file to find services and their restart policies
    while IFS= read -r line || [ -n "$line" ]; do
        # Check if we're entering the services section
        if [[ "$line" =~ ^services: ]]; then
            in_services=true
            continue
        fi
        
        # Skip if not in services section
        if [ "$in_services" = false ]; then
            continue
        fi
        
        # Check if we're leaving services section (another top-level key)
        if [[ "$line" =~ ^[a-z]+: ]] && [[ ! "$line" =~ ^[[:space:]] ]]; then
            in_services=false
            continue
        fi
        
        # Check for service definition (2-space indent, ends with :)
        if [[ "$line" =~ ^[[:space:]]{2}[a-zA-Z_-]+:[[:space:]]*$ ]]; then
            # Save previous service if exists
            if [ -n "$current_service" ]; then
                services_found+=("$current_service")
                if [ -n "$found_restart" ]; then
                    services_with_restart+=("$current_service:$found_restart")
                fi
            fi
            # Extract new service name
            current_service=$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/:.*//')
            found_restart=""
            continue
        fi
        
        # Check for restart policy within a service
        if [ -n "$current_service" ] && [[ "$line" =~ ^[[:space:]]+restart:[[:space:]]* ]]; then
            found_restart=$(echo "$line" | sed 's/.*restart:[[:space:]]*//' | sed 's/[[:space:]]*$//' | tr -d '"' | tr -d "'")
        fi
    done < "$file"
    
    # Don't forget the last service
    if [ -n "$current_service" ]; then
        services_found+=("$current_service")
        if [ -n "$found_restart" ]; then
            services_with_restart+=("$current_service:$found_restart")
        fi
    fi
    
    # Now validate each service
    echo "  Services found: ${services_found[*]}"
    echo ""
    
    for service in "${services_found[@]}"; do
        local restart_policy=""
        
        # Find restart policy for this service
        for entry in "${services_with_restart[@]}"; do
            local svc=$(echo "$entry" | cut -d: -f1)
            local pol=$(echo "$entry" | cut -d: -f2)
            if [ "$svc" = "$service" ]; then
                restart_policy="$pol"
                break
            fi
        done
        
        if [ -z "$restart_policy" ]; then
            echo -e "  ${RED}✗ Service '$service': No restart policy defined${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            FAILED_SERVICES+=("$service (no restart policy)")
            all_passed=false
        elif is_allowed_restart_policy "$restart_policy"; then
            echo -e "  ${GREEN}✓ Service '$service': restart=$restart_policy (allowed)${NC}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "  ${RED}✗ Service '$service': restart=$restart_policy (NOT ALLOWED)${NC}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
            FAILED_SERVICES+=("$service (restart: $restart_policy)")
            all_passed=false
        fi
    done
    
    if [ "$all_passed" = true ]; then
        return 0
    else
        return 1
    fi
}

# Function to run property test on all docker-compose files
test_restart_policy() {
    echo "Running Property Test: All Services Have Restart Policy"
    echo "========================================================="
    echo ""
    echo "Allowed restart policies:"
    for policy in "${ALLOWED_RESTART_POLICIES[@]}"; do
        echo "  - restart: $policy"
    done
    echo ""
    
    # Find all docker-compose files
    local compose_files=$(find "$PROJECT_ROOT/srcs" \( -name "docker-compose*.yml" -o -name "docker-compose*.yaml" \) -type f 2>/dev/null)
    
    if [ -z "$compose_files" ]; then
        echo -e "${GREEN}✓ No docker-compose files found yet - test passes vacuously${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        echo ""
        echo "========================================================="
        echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
        echo -e "${GREEN}Property 7: PASSED${NC}"
        return 0
    fi
    
    local all_passed=true
    
    for compose_file in $compose_files; do
        if [ -f "$compose_file" ]; then
            local relative_path="${compose_file#$PROJECT_ROOT/}"
            echo "Checking: $relative_path"
            echo ""
            
            if check_restart_policies "$compose_file"; then
                echo ""
                echo -e "${GREEN}✓ $relative_path - All services have valid restart policies${NC}"
            else
                echo ""
                echo -e "${RED}✗ $relative_path - Some services missing or have invalid restart policies${NC}"
                all_passed=false
            fi
            echo ""
        fi
    done
    
    echo "========================================================="
    echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
    
    if [ "$all_passed" = true ]; then
        echo -e "${GREEN}Property 7: PASSED${NC}"
        return 0
    else
        echo -e "${RED}Property 7: FAILED${NC}"
        echo "Services with issues:"
        for s in "${FAILED_SERVICES[@]}"; do
            echo "  - $s"
        done
        return 1
    fi
}

# Run the test
test_restart_policy
exit $?
