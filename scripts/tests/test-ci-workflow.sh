#!/bin/bash
# Test script for CI workflow optimization
# This validates the CI workflow caching and conditional logic

set -e

TEST_PASSED=0
TEST_FAILED=0

# Get the repository root dynamically
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CI_WORKFLOW="$REPO_ROOT/.github/workflows/ci.yml"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Test helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    TEST_PASSED=$((TEST_PASSED + 1))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    TEST_FAILED=$((TEST_FAILED + 1))
}

info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

echo "Running CI workflow optimization tests..."
echo "Repository root: $REPO_ROOT"
echo "CI workflow: $CI_WORKFLOW"
echo ""

# Test 1: Workflow file contains caching configuration
echo "Test 1: CI workflow uses actions/cache for XcodeGen"
if grep -q "actions/cache" "$CI_WORKFLOW"; then
    pass "CI workflow includes caching step"
else
    fail "CI workflow should include actions/cache for XcodeGen"
fi

# Test 2: Workflow file uses hash-based cache key for project
echo "Test 2: Cache key includes hash of project.yml for Xcode project"
if grep -q "hashFiles.*project\.yml" "$CI_WORKFLOW"; then
    pass "Cache key uses project.yml hash for Xcode project"
else
    fail "Cache key should include hashFiles of project.yml for Xcode project"
fi

# Test 3: XcodeGen binary cache uses version-based key (not project.yml dependent)
echo "Test 3: XcodeGen binary cache uses version-based key"
if grep -q "xcodegen-2\\.40\\.1" "$CI_WORKFLOW"; then
    pass "XcodeGen cache uses version-based key"
else
    fail "XcodeGen cache should use version-based key, not project.yml hash"
fi

# Test 4: Workflow conditionally runs XcodeGen
echo "Test 4: XcodeGen step is conditional"
if grep -A5 "Generate Xcode project" "$CI_WORKFLOW" | grep -q "if:"; then
    pass "XcodeGen generation is conditional"
else
    fail "XcodeGen generation should be conditional"
fi

# Test 5: Workflow includes validation step
echo "Test 5: Workflow validates cached project"
if grep -q "Validate Xcode project" "$CI_WORKFLOW"; then
    pass "Workflow includes project validation"
else
    fail "Workflow should validate cached project"
fi

# Test 6: Test job exists in workflow
echo "Test 6: CI workflow includes test job for optimization scripts"
if grep -q "test-ci-optimization" "$CI_WORKFLOW"; then
    pass "CI workflow runs optimization tests"
else
    fail "CI workflow should run test scripts"
fi

# Summary
echo ""
echo "=========================="
echo "Test Results:"
echo "  Passed: $TEST_PASSED"
echo "  Failed: $TEST_FAILED"
echo "=========================="

if [ $TEST_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
