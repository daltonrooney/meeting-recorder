#!/bin/bash
# Test script for CI workflow optimization
# This validates the CI workflow caching and conditional logic

set -e

TEST_PASSED=0
TEST_FAILED=0

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
echo ""

# Test 1: Workflow file contains caching configuration
echo "Test 1: CI workflow uses actions/cache for XcodeGen"
if grep -q "actions/cache" /tmp/olive-worktrees/issue-110/.github/workflows/ci.yml; then
    pass "CI workflow includes caching step"
else
    fail "CI workflow should include actions/cache for XcodeGen"
fi

# Test 2: Workflow file uses hash-based cache key
echo "Test 2: Cache key includes hash of project.yml"
if grep -q "hashFiles.*project\.yml" /tmp/olive-worktrees/issue-110/.github/workflows/ci.yml; then
    pass "Cache key uses project.yml hash"
else
    fail "Cache key should include hashFiles of project.yml"
fi

# Test 3: Workflow conditionally runs XcodeGen
echo "Test 3: XcodeGen step is conditional"
if grep -A5 "Generate Xcode project" /tmp/olive-worktrees/issue-110/.github/workflows/ci.yml | grep -q "if:"; then
    pass "XcodeGen generation is conditional"
else
    info "XcodeGen generation could be conditional (optional optimization)"
fi

# Test 4: XcodeGen binary is cached
echo "Test 4: XcodeGen binary installation is cached"
if grep -q "cache.*xcodegen" /tmp/olive-worktrees/issue-110/.github/workflows/ci.yml || \
   grep -q "XcodeGen" /tmp/olive-worktrees/issue-110/.github/workflows/ci.yml | head -20 | grep -q "cache"; then
    pass "XcodeGen binary is cached"
else
    fail "XcodeGen binary installation should be cached"
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
