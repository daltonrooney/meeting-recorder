#!/bin/bash

# Release script for creating tagged releases
# Validates, builds, tests, and tags releases

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="Olive"
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Parse version from Info.plist
INFO_PLIST="${WORKSPACE_DIR}/CallTranscription/Info.plist"
VERSION=$(defaults read "$INFO_PLIST" CFBundleShortVersionString 2>/dev/null || echo "")

if [ -z "$VERSION" ]; then
    echo -e "${RED}Error: Could not read version from Info.plist${NC}"
    echo ""
    echo "Please ensure Info.plist exists at: ${INFO_PLIST}"
    echo ""
    echo "Usage examples:"
    echo "  # Update version in Info.plist first, then run:"
    echo "  ./scripts/release.sh"
    exit 1
fi

echo -e "${GREEN}Preparing release ${VERSION}${NC}"

# Validate semantic versioning
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo -e "${RED}Error: Version must follow semantic versioning (X.Y.Z)${NC}"
    echo "Current version: $VERSION"
    echo ""
    echo "Please update the version in Info.plist to follow semantic versioning."
    echo ""
    echo "Usage examples:"
    echo "  # Update CFBundleShortVersionString in Info.plist to format like:"
    echo "  1.0.0"
    echo "  1.2.3"
    echo "  2.0.0"
    exit 1
fi

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${RED}Error: Uncommitted changes detected${NC}"
    echo ""
    echo "Please commit or stash changes before creating a release."
    echo ""
    echo "Usage examples:"
    echo "  git add ."
    echo "  git commit -m 'Prepare release'"
    echo "  ./scripts/release.sh"
    exit 1
fi

# Check if tag already exists
if git rev-parse "v${VERSION}" >/dev/null 2>&1; then
    echo -e "${RED}Error: Tag v${VERSION} already exists${NC}"
    echo ""
    echo "Please update the version in Info.plist to a new version."
    echo ""
    echo "Usage examples:"
    echo "  # Update version in Info.plist, then run:"
    echo "  ./scripts/release.sh"
    echo ""
    echo "  # Or delete the existing tag if you want to recreate it:"
    echo "  git tag -d v${VERSION}"
    echo "  git push origin :refs/tags/v${VERSION}"
    exit 1
fi

# Run validation
echo -e "${YELLOW}Running pre-release validation...${NC}"
if [ -f "scripts/validate-configuration.swift" ]; then
    swift scripts/validate-configuration.swift
fi

# Run tests
echo -e "${YELLOW}Running test suite...${NC}"
xcodebuild test \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "$PROJECT_NAME" \
    -configuration Release

# Build release
echo -e "${YELLOW}Building release configuration...${NC}"
"${WORKSPACE_DIR}/scripts/build.sh" Release clean

# Create distribution package
echo -e "${YELLOW}Creating distribution package...${NC}"
"${WORKSPACE_DIR}/scripts/package.sh" Release

# Optional: Notarize (if credentials provided)
if [ -n "${APPLE_ID:-}" ] && [ -n "${TEAM_ID:-}" ] && [ -n "${APP_SPECIFIC_PASSWORD:-}" ]; then
    echo -e "${YELLOW}Notarizing release...${NC}"
    "${WORKSPACE_DIR}/scripts/notarize.sh" Release
else
    echo -e "${YELLOW}Skipping notarization (credentials not provided)${NC}"
fi

# Create git tag
echo -e "${YELLOW}Creating git tag v${VERSION}...${NC}"
git tag -a "v${VERSION}" -m "Release version ${VERSION}"

echo -e "${GREEN}Release ${VERSION} prepared successfully!${NC}"
echo ""
echo "Next steps:"
echo "  1. Review the release build and package"
echo "  2. Push the tag: git push origin v${VERSION}"
echo "  3. Create a GitHub release with the package from dist/"
echo ""
echo -e "${YELLOW}Tag created locally but not pushed. Run 'git push origin v${VERSION}' to publish.${NC}"
