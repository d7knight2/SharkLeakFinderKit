#!/bin/bash

# Build Debug APK Script
# This script builds the debug APK for the SharkLeakFinderKit app

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Building Debug APK${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

# Navigate to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Check if gradlew exists
if [ ! -f "gradlew" ]; then
    echo -e "${RED}❌ Error: gradlew not found${NC}"
    echo "Please ensure you're running this script from the project root or that the Gradle wrapper is properly set up."
    exit 1
fi

# Make gradlew executable
chmod +x gradlew

echo -e "${YELLOW}Cleaning previous builds...${NC}"
./gradlew clean --no-daemon

echo ""
echo -e "${YELLOW}Building debug APK...${NC}"
./gradlew assembleDebug --no-daemon --stacktrace

echo ""

# Find and display the APK
APK_PATH=$(find app/build/outputs/apk/debug -name "*.apk" 2>/dev/null | head -n 1)

if [ -z "$APK_PATH" ]; then
    echo -e "${RED}❌ Error: No APK file found after build${NC}"
    exit 1
fi

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✅ Build Successful!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo -e "APK Location: ${BLUE}$APK_PATH${NC}"

# Get APK size
APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
echo -e "APK Size: ${BLUE}$APK_SIZE${NC}"

# Get APK info if aapt is available
if command -v aapt &> /dev/null; then
    echo ""
    echo -e "${YELLOW}APK Information:${NC}"
    aapt dump badging "$APK_PATH" | grep -E "package:|application-label:|sdkVersion:|targetSdkVersion:"
fi

echo ""
echo -e "${GREEN}You can now install this APK on your device or emulator:${NC}"
echo -e "${BLUE}adb install -r $APK_PATH${NC}"
echo ""
