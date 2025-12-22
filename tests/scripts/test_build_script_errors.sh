#!/bin/bash

# Test script for build script error messages
# Tests that error messages include usage examples

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to check for usage examples in output
check_usage_examples() {
    local output="$1"
    local script_name="$2"
    
    # Check for "Usage examples:" or "Usage:" section
    if ! echo "$output" | grep -q -E "(Usage examples:|Usage:)"; then
        echo "  Missing 'Usage examples:' or 'Usage:' section"
        return 1
    fi
    
    # Check for example commands (lines starting with ./scripts/)
    if ! echo "$output" | grep -q "./scripts/"; then
        echo "  Missing example commands"
        return 1
    fi
    
    return 0
}

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/scripts"

echo "========================================"
echo "Build Script Error Messages Tests"
echo "========================================"
echo ""

# Test 1: build.sh with invalid configuration
echo -e "${YELLOW}Test 1: build.sh invalid configuration${NC}"
output=$(cd "$SCRIPTS_DIR" && ./build.sh InvalidConfig 2>&1 || true)
if echo "$output" | grep -q "Error: Configuration must be 'Debug' or 'Release'" && \
   check_usage_examples "$output" "build.sh"; then
    echo -e "${GREEN}PASS: build.sh shows usage examples on error${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}FAIL: build.sh missing usage examples${NC}"
    echo "Output:"
    echo "$output" | sed 's/^/  /'
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

# Test 2: package.sh with invalid configuration
echo -e "${YELLOW}Test 2: package.sh invalid configuration${NC}"
output=$(cd "$SCRIPTS_DIR" && ./package.sh InvalidConfig 2>&1 || true)
if echo "$output" | grep -q "Error: Configuration must be 'Debug' or 'Release'" && \
   check_usage_examples "$output" "package.sh"; then
    echo -e "${GREEN}PASS: package.sh shows usage examples on error${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}FAIL: package.sh missing usage examples${NC}"
    echo "Output:"
    echo "$output" | sed 's/^/  /'
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

# Test 3: notarize.sh shows usage examples (when env vars missing OR when app missing)
echo -e "${YELLOW}Test 3: notarize.sh shows usage examples${NC}"
output=$(cd "$SCRIPTS_DIR" && ./notarize.sh Release 2>&1 || true)
if check_usage_examples "$output" "notarize.sh"; then
    echo -e "${GREEN}PASS: notarize.sh shows usage examples${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}FAIL: notarize.sh missing usage examples${NC}"
    echo "Output:"
    echo "$output" | sed 's/^/  /'
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

# Test 4: Verify error messages contain example usage
echo -e "${YELLOW}Test 4: Verify error messages contain example usage${NC}"
# Check build.sh source for usage examples function
if grep -q "show_usage\|print_usage\|usage_examples" "$SCRIPTS_DIR/build.sh" 2>/dev/null || \
   grep -A 5 "Error: Configuration must be" "$SCRIPTS_DIR/build.sh" | grep -q "examples:"; then
    echo -e "${GREEN}PASS: build.sh has usage example infrastructure${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}FAIL: build.sh missing usage example infrastructure${NC}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

# Test 5: Check that error messages include actual example commands
echo -e "${YELLOW}Test 5: build.sh error includes specific examples${NC}"
output=$(cd "$SCRIPTS_DIR" && ./build.sh WrongConfig 2>&1 || true)
if echo "$output" | grep -q "./scripts/build.sh Debug" && \
   echo "$output" | grep -q "./scripts/build.sh Release"; then
    echo -e "${GREEN}PASS: build.sh error includes specific examples${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}FAIL: build.sh error missing specific examples${NC}"
    echo "Expected both './scripts/build.sh Debug' and './scripts/build.sh Release'"
    echo "Actual output:"
    echo "$output" | sed 's/^/  /'
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

# Test 6: Check package.sh includes examples
echo -e "${YELLOW}Test 6: package.sh error includes examples${NC}"
output=$(cd "$SCRIPTS_DIR" && ./package.sh BadConfig 2>&1 || true)
if echo "$output" | grep -q "./scripts/package.sh"; then
    echo -e "${GREEN}PASS: package.sh error includes examples${NC}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}FAIL: package.sh error missing examples${NC}"
    echo "Actual output:"
    echo "$output" | sed 's/^/  /'
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))

echo ""
echo "========================================"
echo "Test Summary"
echo "========================================"
echo "Tests run:    $TESTS_RUN"
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
