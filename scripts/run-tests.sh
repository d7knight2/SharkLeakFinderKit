#!/bin/bash

# Run Tests Script
# This script runs all tests (unit and instrumented) for the SharkLeakFinderKit app

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Parse command line arguments
RUN_UNIT_TESTS=true
RUN_UI_TESTS=false
VERBOSE=false

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -u, --unit-only       Run only unit tests (default)"
    echo "  -i, --ui-only         Run only UI/instrumented tests"
    echo "  -a, --all             Run both unit and UI tests"
    echo "  -v, --verbose         Enable verbose output"
    echo "  -h, --help            Show this help message"
    echo ""
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--unit-only)
            RUN_UNIT_TESTS=true
            RUN_UI_TESTS=false
            shift
            ;;
        -i|--ui-only)
            RUN_UNIT_TESTS=false
            RUN_UI_TESTS=true
            shift
            ;;
        -a|--all)
            RUN_UNIT_TESTS=true
            RUN_UI_TESTS=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
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

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Running Tests${NC}"
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

# Track test results
UNIT_TEST_RESULT=0
UI_TEST_RESULT=0

# Run unit tests
if [ "$RUN_UNIT_TESTS" = true ]; then
    echo -e "${CYAN}Running Unit Tests...${NC}"
    echo ""
    
    if [ "$VERBOSE" = true ]; then
        ./gradlew test --no-daemon --stacktrace || UNIT_TEST_RESULT=$?
    else
        ./gradlew test --no-daemon || UNIT_TEST_RESULT=$?
    fi
    
    echo ""
    
    if [ $UNIT_TEST_RESULT -eq 0 ]; then
        echo -e "${GREEN}✅ Unit tests passed${NC}"
    else
        echo -e "${RED}❌ Unit tests failed${NC}"
    fi
    
    # Display test reports location
    if [ -d "app/build/reports/tests/test" ]; then
        echo -e "${YELLOW}Unit test report:${NC} app/build/reports/tests/test/index.html"
    fi
    
    echo ""
fi

# Run UI tests
if [ "$RUN_UI_TESTS" = true ]; then
    echo -e "${CYAN}Running UI Tests (Instrumented Tests)...${NC}"
    echo ""
    
    # Check if a device or emulator is connected
    if ! adb devices | grep -q "device$"; then
        echo -e "${RED}❌ Error: No Android device or emulator detected${NC}"
        echo "Please start an emulator or connect a device before running UI tests."
        echo ""
        echo "To start an emulator:"
        echo "  emulator -avd <avd_name>"
        echo ""
        echo "To list available AVDs:"
        echo "  emulator -list-avds"
        exit 1
    fi
    
    echo -e "${YELLOW}Device detected:${NC}"
    adb devices
    echo ""
    
    if [ "$VERBOSE" = true ]; then
        ./gradlew connectedAndroidTest --no-daemon --stacktrace || UI_TEST_RESULT=$?
    else
        ./gradlew connectedAndroidTest --no-daemon || UI_TEST_RESULT=$?
    fi
    
    echo ""
    
    if [ $UI_TEST_RESULT -eq 0 ]; then
        echo -e "${GREEN}✅ UI tests passed${NC}"
    else
        echo -e "${RED}❌ UI tests failed${NC}"
    fi
    
    # Display test reports location
    if [ -d "app/build/reports/androidTests/connected" ]; then
        echo -e "${YELLOW}UI test report:${NC} app/build/reports/androidTests/connected/index.html"
    fi
    
    echo ""
fi

# Summary
echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Test Summary${NC}"
echo -e "${BLUE}================================${NC}"
echo ""

if [ "$RUN_UNIT_TESTS" = true ]; then
    if [ $UNIT_TEST_RESULT -eq 0 ]; then
        echo -e "Unit Tests: ${GREEN}✅ PASSED${NC}"
    else
        echo -e "Unit Tests: ${RED}❌ FAILED${NC}"
    fi
fi

if [ "$RUN_UI_TESTS" = true ]; then
    if [ $UI_TEST_RESULT -eq 0 ]; then
        echo -e "UI Tests: ${GREEN}✅ PASSED${NC}"
    else
        echo -e "UI Tests: ${RED}❌ FAILED${NC}"
    fi
fi

echo ""

# Exit with error if any tests failed
if [ $UNIT_TEST_RESULT -ne 0 ] || [ $UI_TEST_RESULT -ne 0 ]; then
    exit 1
fi

exit 0
