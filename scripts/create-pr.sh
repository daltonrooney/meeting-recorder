#!/bin/bash

# PR Creation Wrapper Script
# This script validates requirements before creating a PR

set -e

echo "🔍 Pre-PR Validation Checklist"
echo "================================"
echo ""

# Check if CLAUDE.md exists
if [ ! -f "CLAUDE.md" ]; then
    echo "⚠️  Warning: CLAUDE.md not found"
else
    echo "✅ CLAUDE.md found"
fi

# Validate PR body doesn't contain forbidden phrases
validate_pr_body() {
    local body="$1"

    if echo "$body" | grep -q "Generated with \[Claude Code\]"; then
        echo "❌ FAILED: PR body contains 'Generated with Claude Code' footer"
        echo "   This violates CLAUDE.md requirements"
        return 1
    fi

    if echo "$body" | grep -q "Co-Authored-By: Claude"; then
        echo "❌ FAILED: PR body contains 'Co-Authored-By: Claude' line"
        echo "   This violates CLAUDE.md requirements"
        return 1
    fi

    echo "✅ PR body passes validation (no forbidden footers)"
    return 0
}

# Check recent commits for TDD evidence
check_tdd_commits() {
    echo ""
    echo "📝 Checking commit history for TDD evidence..."

    local test_commits=$(git log --oneline --grep="^test:" origin/dev..HEAD 2>/dev/null | wc -l | tr -d ' ')
    local feat_commits=$(git log --oneline --grep="^feat:" origin/dev..HEAD 2>/dev/null | wc -l | tr -d ' ')

    echo "   Test commits: $test_commits"
    echo "   Feature commits: $feat_commits"

    if [ "$test_commits" -eq 0 ] && [ "$feat_commits" -gt 0 ]; then
        echo "⚠️  Warning: Feature commits found but no test commits"
        echo "   TDD methodology requires tests written first"
    else
        echo "✅ Commit history looks good"
    fi
}

# Main validation
echo ""
echo "Enter PR title:"
read -r title

echo ""
echo "Enter PR body (Ctrl+D when done):"
body=$(cat)

echo ""
echo "Running validations..."
echo ""

# Validate body
if ! validate_pr_body "$body"; then
    echo ""
    echo "❌ Validation failed. Please remove forbidden content and try again."
    exit 1
fi

# Check TDD commits
check_tdd_commits

echo ""
echo "✅ All validations passed!"
echo ""
echo "Creating PR..."
echo ""

# Create the PR using gh
gh pr create --title "$title" --body "$body"

echo ""
echo "✅ PR created successfully!"
