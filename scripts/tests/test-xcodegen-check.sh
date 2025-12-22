#!/bin/bash
# Test script for XcodeGen optimization logic
# This tests the logic that determines whether XcodeGen needs to run

set -e

TEST_PASSED=0
TEST_FAILED=0

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
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

# Create a temporary test directory
TEST_DIR=$(mktemp -d)
cd "$TEST_DIR"

echo "Running XcodeGen optimization tests..."
echo "Test directory: $TEST_DIR"
echo ""

# Test 1: should_regenerate_xcode_project returns true when project.yml is newer
echo "Test 1: Returns true when project.yml is newer than .xcodeproj"
touch -t 202401010000 Olive.xcodeproj
touch -t 202401020000 project.yml
if source /tmp/olive-worktrees/issue-110/scripts/check-xcodegen-needed.sh && should_regenerate_xcode_project; then
    pass "Detects project.yml is newer"
else
    fail "Should detect project.yml is newer"
fi

# Test 2: should_regenerate_xcode_project returns false when .xcodeproj is newer
echo "Test 2: Returns false when .xcodeproj is newer than project.yml"
touch -t 202401020000 Olive.xcodeproj
touch -t 202401010000 project.yml
if source /tmp/olive-worktrees/issue-110/scripts/check-xcodegen-needed.sh && ! should_regenerate_xcode_project; then
    pass "Detects .xcodeproj is up to date"
else
    fail "Should detect .xcodeproj is up to date"
fi

# Test 3: should_regenerate_xcode_project returns true when .xcodeproj doesn't exist
echo "Test 3: Returns true when .xcodeproj doesn't exist"
rm -rf Olive.xcodeproj
touch project.yml
if source /tmp/olive-worktrees/issue-110/scripts/check-xcodegen-needed.sh && should_regenerate_xcode_project; then
    pass "Detects missing .xcodeproj"
else
    fail "Should detect missing .xcodeproj"
fi

# Test 4: should_regenerate_xcode_project returns true when project.yml doesn't exist
echo "Test 4: Returns true when project.yml doesn't exist"
mkdir -p Olive.xcodeproj
rm -f project.yml
if source /tmp/olive-worktrees/issue-110/scripts/check-xcodegen-needed.sh && should_regenerate_xcode_project; then
    pass "Handles missing project.yml gracefully"
else
    fail "Should handle missing project.yml"
fi

# Cleanup
cd /
rm -rf "$TEST_DIR"

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
