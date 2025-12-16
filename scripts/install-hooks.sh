#!/bin/bash

# Install git hooks for the project
# Run this script to set up local git hooks

set -e

HOOKS_DIR=".git/hooks"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🔧 Installing git hooks..."
echo ""

# Pre-push hook
cat > "$HOOKS_DIR/pre-push" << 'EOF'
#!/bin/bash

# Pre-push hook to remind about PR requirements when pushing feature branches

current_branch=$(git rev-parse --abbrev-ref HEAD)

# Only run checks for feature branches
if [[ "$current_branch" == feature/* ]] || [[ "$current_branch" == fix/* ]]; then
    echo ""
    echo "🔔 Pre-Push Reminder for Feature Branch: $current_branch"
    echo "==========================================================="
    echo ""
    echo "Before creating a PR, remember to check:"
    echo ""
    echo "  ❌ NO 'Generated with Claude Code' footer in PR description"
    echo "  ❌ NO 'Co-Authored-By: Claude' in commits or PR"
    echo "  ✅ Tests written FIRST (separate commits before feature commits)"
    echo "  ✅ All tests passing"
    echo ""
    echo "See .claude/PR_CHECKLIST.md for full checklist"
    echo "Use ./scripts/create-pr.sh for validated PR creation"
    echo ""
fi

exit 0
EOF

chmod +x "$HOOKS_DIR/pre-push"
echo "✅ Installed pre-push hook"

# Pre-commit hook
cat > "$HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash

# Pre-commit hook to validate commit messages

# Get the commit message from the file
commit_msg_file="$1"

# Only run if this is an interactive commit (not --amend, merge, etc.)
if [ -z "$commit_msg_file" ]; then
    exit 0
fi

echo ""
echo "🔍 Pre-Commit Validation"
echo "========================"
echo ""

# Read the commit message
commit_msg=$(cat .git/COMMIT_EDITMSG 2>/dev/null || echo "")

# Check for forbidden phrases in commit message
if echo "$commit_msg" | grep -q "Generated with \[Claude Code\]"; then
    echo "❌ FAILED: Commit message contains 'Generated with Claude Code' footer"
    echo "   This violates CLAUDE.md requirements"
    echo ""
    exit 1
fi

if echo "$commit_msg" | grep -q "Co-Authored-By: Claude"; then
    echo "❌ FAILED: Commit message contains 'Co-Authored-By: Claude' line"
    echo "   This violates CLAUDE.md requirements"
    echo ""
    exit 1
fi

echo "✅ Commit message passes validation"
echo ""

exit 0
EOF

chmod +x "$HOOKS_DIR/pre-commit"
echo "✅ Installed pre-commit hook"

echo ""
echo "✅ All hooks installed successfully!"
echo ""
echo "Git hooks are now active in your local repository."
