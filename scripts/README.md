# Project Scripts

## Build and Distribution

### `build.sh`

Automated build script for Debug and Release configurations.

**Usage:**
```bash
# Build Debug configuration
./scripts/build.sh Debug

# Build Release configuration
./scripts/build.sh Release

# Clean build
./scripts/build.sh Release clean
```

**Features:**
- Automatic Xcode project generation from project.yml
- Support for both Debug and Release configurations
- Optional clean build
- Colored output for better visibility
- Error handling and validation

**Output:**
Built app is located at: `build/Build/Products/{Configuration}/Olive.app`

---

### `package.sh`

Creates distribution ZIP archives of the built application.

**Usage:**
```bash
# Package Debug build
./scripts/package.sh Debug

# Package Release build
./scripts/package.sh Release
```

**Features:**
- Reads version from Info.plist
- Creates ZIP archive with version in filename
- Excludes .DS_Store files
- Shows archive size

**Output:**
Package is created at: `dist/Olive-{version}-{configuration}.zip`

---

### `notarize.sh`

Notarizes macOS app for distribution outside the Mac App Store.

**Usage:**
```bash
# Set environment variables
export APPLE_ID="your@apple.id"
export TEAM_ID="YOUR_TEAM_ID"
export APP_SPECIFIC_PASSWORD="your-app-specific-password"

# Notarize Release build
./scripts/notarize.sh Release
```

**Features:**
- Verifies code signature before submission
- Checks for hardened runtime
- Submits to Apple's notarization service
- Waits for notarization to complete
- Staples notarization ticket to app
- Validates stapling

**Requirements:**
- Apple Developer account
- App-specific password (generated in Apple ID settings)
- Valid code signing certificate
- Hardened runtime enabled

**Note:** Notarization is optional for development builds and will be skipped if environment variables are not set.

---

### `release.sh`

Complete release process with validation, testing, building, and tagging.

**Usage:**
```bash
./scripts/release.sh
```

**Process:**
1. Reads version from Info.plist
2. Validates semantic versioning format (X.Y.Z)
3. Checks for uncommitted changes
4. Verifies git tag doesn't already exist
5. Runs pre-release validation (validate-configuration.swift)
6. Executes full test suite
7. Builds Release configuration
8. Creates distribution package
9. Optionally notarizes (if credentials provided)
10. Creates git tag

**Output:**
- Release build at: `build/Build/Products/Release/Olive.app`
- Distribution package at: `dist/Olive-{version}-Release.zip`
- Git tag: `v{version}` (created locally, not pushed)

**Next Steps After Release:**
```bash
# Push the tag to GitHub
git push origin v{version}

# Create GitHub release and attach package from dist/
```

---

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
