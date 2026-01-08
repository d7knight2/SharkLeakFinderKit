#!/bin/bash

# Build and Validate Script
# This script builds the APK, runs all tests, and validates the final output

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse command line arguments
BUILD_TYPE="debug"
RUN_TESTS=true
SKIP_UI_TESTS=false

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -r, --release         Build release APK instead of debug"
    echo "  -s, --skip-tests      Skip running tests"
    echo "  -u, --skip-ui-tests   Skip UI tests (run unit tests only)"
    echo "  -h, --help            Show this help message"
    echo ""
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--release)
            BUILD_TYPE="release"
            shift
            ;;
        -s|--skip-tests)
            RUN_TESTS=false
            shift
            ;;
        -u|--skip-ui-tests)
            SKIP_UI_TESTS=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            usage
            exit 1
            ;;
    esac
done

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Build and Validate Pipeline       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Navigate to project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_ROOT"

# Check if gradlew exists
if [ ! -f "gradlew" ]; then
    echo -e "${RED}❌ Error: gradlew not found${NC}"
    echo "Please ensure you're running this script from the project root."
    exit 1
fi

chmod +x gradlew

# Track overall status
OVERALL_SUCCESS=true

# Step 1: Run Tests (if not skipped)
if [ "$RUN_TESTS" = true ]; then
    echo -e "${CYAN}Step 1: Running Tests${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Run unit tests
    echo -e "${YELLOW}Running unit tests...${NC}"
    if ./gradlew test --no-daemon; then
        echo -e "${GREEN}✅ Unit tests passed${NC}"
    else
        echo -e "${RED}❌ Unit tests failed${NC}"
        OVERALL_SUCCESS=false
        
        if [ -d "app/build/reports/tests/test" ]; then
            echo -e "${YELLOW}Test report: app/build/reports/tests/test/index.html${NC}"
        fi
    fi
    echo ""
    
    # Run UI tests (if not skipped)
    if [ "$SKIP_UI_TESTS" = false ]; then
        echo -e "${YELLOW}Running UI tests...${NC}"
        
        # Check if a device is connected
        if adb devices | grep -q "device$"; then
            if ./gradlew connectedAndroidTest --no-daemon; then
                echo -e "${GREEN}✅ UI tests passed${NC}"
            else
                echo -e "${RED}❌ UI tests failed${NC}"
                OVERALL_SUCCESS=false
                
                if [ -d "app/build/reports/androidTests/connected" ]; then
                    echo -e "${YELLOW}Test report: app/build/reports/androidTests/connected/index.html${NC}"
                fi
            fi
        else
            echo -e "${YELLOW}⚠️  No device detected, skipping UI tests${NC}"
        fi
        echo ""
    else
        echo -e "${YELLOW}ℹ️  Skipping UI tests as requested${NC}"
        echo ""
    fi
else
    echo -e "${YELLOW}ℹ️  Skipping tests as requested${NC}"
    echo ""
fi

# Step 2: Build APK
echo -e "${CYAN}Step 2: Building APK${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ "$BUILD_TYPE" = "release" ]; then
    echo -e "${YELLOW}Building release APK...${NC}"
    BUILD_TASK="assembleRelease"
    APK_DIR="app/build/outputs/apk/release"
else
    echo -e "${YELLOW}Building debug APK...${NC}"
    BUILD_TASK="assembleDebug"
    APK_DIR="app/build/outputs/apk/debug"
fi

if ./gradlew $BUILD_TASK --no-daemon; then
    echo -e "${GREEN}✅ APK build successful${NC}"
else
    echo -e "${RED}❌ APK build failed${NC}"
    OVERALL_SUCCESS=false
    exit 1
fi

echo ""

# Step 3: Validate APK
echo -e "${CYAN}Step 3: Validating APK${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

APK_PATH=$(find $APK_DIR -name "*.apk" 2>/dev/null | head -n 1)

if [ -z "$APK_PATH" ]; then
    echo -e "${RED}❌ No APK file found after build${NC}"
    OVERALL_SUCCESS=false
    exit 1
fi

echo -e "${GREEN}✅ APK file created${NC}"
echo -e "   Location: ${BLUE}$APK_PATH${NC}"

# Get APK size
APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
echo -e "   Size: ${BLUE}$APK_SIZE${NC}"

# Validate APK file integrity
if file "$APK_PATH" | grep -q "Zip archive"; then
    echo -e "${GREEN}✅ APK file format valid (Zip archive)${NC}"
else
    echo -e "${RED}❌ APK file format invalid${NC}"
    OVERALL_SUCCESS=false
fi

# Extract APK info if aapt is available
if command -v aapt &> /dev/null; then
    echo ""
    echo -e "${YELLOW}APK Information:${NC}"
    
    PACKAGE_NAME=$(aapt dump badging "$APK_PATH" | grep "package:" | sed -E "s/.*name='([^']+)'.*/\1/")
    VERSION_CODE=$(aapt dump badging "$APK_PATH" | grep "package:" | sed -E "s/.*versionCode='([^']+)'.*/\1/")
    VERSION_NAME=$(aapt dump badging "$APK_PATH" | grep "package:" | sed -E "s/.*versionName='([^']+)'.*/\1/")
    MIN_SDK=$(aapt dump badging "$APK_PATH" | grep "sdkVersion:" | sed -E "s/.*'([^']+)'.*/\1/")
    TARGET_SDK=$(aapt dump badging "$APK_PATH" | grep "targetSdkVersion:" | sed -E "s/.*'([^']+)'.*/\1/")
    
    echo -e "   Package: ${BLUE}$PACKAGE_NAME${NC}"
    echo -e "   Version: ${BLUE}$VERSION_NAME ($VERSION_CODE)${NC}"
    echo -e "   Min SDK: ${BLUE}$MIN_SDK${NC}"
    echo -e "   Target SDK: ${BLUE}$TARGET_SDK${NC}"
fi

echo ""

# Step 4: Final Summary
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Build Summary                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

if [ "$OVERALL_SUCCESS" = true ]; then
    echo -e "${GREEN}✅ All steps completed successfully!${NC}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo -e "  • Install APK: ${BLUE}adb install -r $APK_PATH${NC}"
    echo -e "  • View test reports in ${BLUE}app/build/reports/${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}❌ Some steps failed${NC}"
    echo ""
    echo -e "${YELLOW}Please check the error messages above and fix the issues.${NC}"
    echo ""
    exit 1
fi
