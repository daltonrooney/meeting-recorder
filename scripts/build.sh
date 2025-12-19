#!/bin/bash

# Build script for Olive
# Supports both Debug and Release configurations

set -e  # Exit on error
set -u  # Exit on undefined variable

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="Olive"
SCHEME="Olive"
WORKSPACE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${WORKSPACE_DIR}/build"

# Default configuration
CONFIGURATION="${1:-Debug}"
CLEAN="${2:-}"

# Validate configuration
if [[ "$CONFIGURATION" != "Debug" && "$CONFIGURATION" != "Release" ]]; then
    echo -e "${RED}Error: Configuration must be 'Debug' or 'Release'${NC}"
    echo "Usage: $0 [Debug|Release] [clean]"
    exit 1
fi

# Check if clean build requested
if [[ "$CLEAN" == "clean" || "$CLEAN" == "true" ]]; then
    echo -e "${YELLOW}Cleaning build directory...${NC}"
    xcodebuild clean \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION"
fi

echo -e "${GREEN}Building ${PROJECT_NAME} (${CONFIGURATION})...${NC}"

# Generate Xcode project if needed
if [ -f "project.yml" ]; then
    echo -e "${YELLOW}Generating Xcode project from project.yml...${NC}"
    xcodegen generate
fi

# Build the project
xcodebuild \
    -project "${PROJECT_NAME}.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$BUILD_DIR" \
    build

echo -e "${GREEN}Build completed successfully!${NC}"
echo -e "Build output: ${BUILD_DIR}/Build/Products/${CONFIGURATION}/${PROJECT_NAME}.app"
