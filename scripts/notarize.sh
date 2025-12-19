#!/bin/bash

# Notarization script for macOS app distribution
# Notarizes and staples the app for Gatekeeper compatibility

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
BUILD_DIR="${WORKSPACE_DIR}/build"

# Required environment variables
APPLE_ID="${APPLE_ID:-}"
TEAM_ID="${TEAM_ID:-}"
APP_SPECIFIC_PASSWORD="${APP_SPECIFIC_PASSWORD:-}"

# Validate required parameters
if [ -z "$APPLE_ID" ] || [ -z "$TEAM_ID" ] || [ -z "$APP_SPECIFIC_PASSWORD" ]; then
    echo -e "${YELLOW}Notarization skipped: Missing required environment variables${NC}"
    echo "Required variables:"
    echo "  APPLE_ID - Your Apple ID email"
    echo "  TEAM_ID - Your Apple Developer Team ID"
    echo "  APP_SPECIFIC_PASSWORD - App-specific password for notarization"
    echo ""
    echo -e "${YELLOW}Note: Notarization is optional for development builds${NC}"
    exit 0
fi

# Paths
CONFIGURATION="${1:-Release}"
APP_PATH="${BUILD_DIR}/Build/Products/${CONFIGURATION}/${PROJECT_NAME}.app"
ZIP_PATH="${BUILD_DIR}/${PROJECT_NAME}-notarize.zip"

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}Error: Application not found at ${APP_PATH}${NC}"
    echo "Please build the application first using: scripts/build.sh ${CONFIGURATION}"
    exit 1
fi

# Verify app is signed
echo -e "${YELLOW}Verifying code signature...${NC}"
codesign --verify --verbose "$APP_PATH"

# Check for hardened runtime
echo -e "${YELLOW}Checking hardened runtime...${NC}"
if ! codesign --display --verbose "$APP_PATH" 2>&1 | grep -q "runtime"; then
    echo -e "${RED}Warning: Hardened runtime not detected${NC}"
fi

# Create ZIP for notarization
echo -e "${YELLOW}Creating archive for notarization...${NC}"
cd "${BUILD_DIR}/Build/Products/${CONFIGURATION}"
ditto -c -k --keepParent "${PROJECT_NAME}.app" "$ZIP_PATH"
cd - > /dev/null

# Submit for notarization
echo -e "${YELLOW}Submitting to Apple for notarization...${NC}"
echo -e "${YELLOW}This may take several minutes...${NC}"

SUBMIT_OUTPUT=$(xcrun notarytool submit "$ZIP_PATH" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_SPECIFIC_PASSWORD" \
    --wait 2>&1)

# Extract submission ID from output
SUBMISSION_ID=$(echo "$SUBMIT_OUTPUT" | grep -o 'id: [a-f0-9-]*' | head -1 | cut -d' ' -f2)

if [ -z "$SUBMISSION_ID" ]; then
    echo -e "${RED}Failed to get submission ID${NC}"
    echo "$SUBMIT_OUTPUT"
    exit 1
fi

# Check notarization status
echo -e "${YELLOW}Checking notarization status (ID: $SUBMISSION_ID)...${NC}"
NOTARIZATION_INFO=$(xcrun notarytool info "$SUBMISSION_ID" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_SPECIFIC_PASSWORD")

if echo "$NOTARIZATION_INFO" | grep -q "status: Accepted"; then
    echo -e "${GREEN}Notarization successful!${NC}"

    # Staple the notarization ticket
    echo -e "${YELLOW}Stapling notarization ticket...${NC}"
    xcrun stapler staple "$APP_PATH"

    echo -e "${GREEN}App notarized and stapled successfully!${NC}"

    # Verify stapling
    xcrun stapler validate "$APP_PATH"
else
    echo -e "${RED}Notarization failed!${NC}"
    echo "$NOTARIZATION_INFO"
    exit 1
fi

# Clean up
rm -f "$ZIP_PATH"

echo -e "${GREEN}Notarization complete!${NC}"
echo -e "App: ${APP_PATH}"
