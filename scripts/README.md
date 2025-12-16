# Project Scripts

## PR Creation and Validation

### `create-pr.sh`

Validated wrapper around `gh pr create` that enforces CLAUDE.md requirements.

**Usage:**
```bash
./scripts/create-pr.sh
```

**What it checks:**
- ❌ Blocks PRs with "Generated with Claude Code" footer
- ❌ Blocks PRs with "Co-Authored-By: Claude" lines
- ✅ Validates TDD evidence in commit history
- ✅ Shows warnings for missing test commits

**Instead of:**
```bash
gh pr create --title "..." --body "..."
```

**Use:**
```bash
./scripts/create-pr.sh
# Then enter title and body when prompted
```

### `install-hooks.sh`

Installs local git hooks for the project.

**Usage:**
```bash
./scripts/install-hooks.sh
```

**What it installs:**

1. **Pre-push hook** - Shows reminder when pushing feature branches:
   - Reminds about forbidden footers
   - Points to PR checklist
   - Suggests using validated PR creation script

2. **Commit-msg hook** - Validates commit messages:
   - Blocks commits with "Generated with Claude Code" footer
   - Blocks commits with "Co-Authored-By: Claude" line
   - Ensures CLAUDE.md compliance

## Setup

After cloning the repository, run:

```bash
./scripts/install-hooks.sh
```

This ensures your local environment follows project standards.
