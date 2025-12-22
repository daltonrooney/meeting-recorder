#!/bin/bash

# Package script for creating distribution archives
# Creates a ZIP archive of the built application

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
DIST_DIR="${WORKSPACE_DIR}/dist"

# Default configuration
CONFIGURATION="${1:-Release}"

# Validate configuration
if [[ "$CONFIGURATION" != "Debug" && "$CONFIGURATION" != "Release" ]]; then
    echo -e "${RED}Error: Configuration must be 'Debug' or 'Release'${NC}"
    echo ""
    echo "Usage examples:"
    echo "  ./scripts/package.sh Release"
    echo "  ./scripts/package.sh Debug"
    exit 1
fi

# Paths
APP_PATH="${BUILD_DIR}/Build/Products/${CONFIGURATION}/${PROJECT_NAME}.app"
VERSION=$(defaults read "${APP_PATH}/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "0.0.0")
ARCHIVE_NAME="${PROJECT_NAME}-${VERSION}-${CONFIGURATION}.zip"

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}Error: Application not found at ${APP_PATH}${NC}"
    echo ""
    echo "Please build the application first."
    echo ""
    echo "Usage examples:"
    echo "  ./scripts/build.sh ${CONFIGURATION}"
    echo "  ./scripts/package.sh ${CONFIGURATION}"
    exit 1
fi

# Create distribution directory
mkdir -p "$DIST_DIR"

echo -e "${YELLOW}Packaging ${PROJECT_NAME} ${VERSION} (${CONFIGURATION})...${NC}"

# Create ZIP archive
cd "${BUILD_DIR}/Build/Products/${CONFIGURATION}"
zip -r "${DIST_DIR}/${ARCHIVE_NAME}" "${PROJECT_NAME}.app" -x "*.DS_Store"
cd - > /dev/null

echo -e "${GREEN}Package created successfully!${NC}"
echo -e "Archive: ${DIST_DIR}/${ARCHIVE_NAME}"
echo -e "Size: $(du -h "${DIST_DIR}/${ARCHIVE_NAME}" | cut -f1)"
