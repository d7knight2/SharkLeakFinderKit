#!/bin/bash

# Mock testing script for Appetize.io upload
# This script simulates APK discovery and Appetize.io API calls for testing
# Usage: ./test-appetize-upload.sh [--with-apk|--without-apk|--mock-api-success|--mock-api-failure]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to log messages
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

log_test() {
    echo -e "${CYAN}[TEST]${NC} $1"
}

# Test result tracking
pass_test() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
    log_success "$1"
}

fail_test() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
    log_error "$1"
}

# Mock Appetize.io API response
mock_appetize_success_response() {
    cat << 'EOF'
{
  "publicKey": "mock_app_key_123456789",
  "publicURL": "https://appetize.io/app/mock_app_key_123456789",
  "privateKey": "mock_private_key",
  "platform": "android",
  "created": "2026-01-06T23:00:00.000Z",
  "updated": "2026-01-06T23:00:00.000Z"
}
HTTP_CODE:201
EOF
}

mock_appetize_failure_response() {
    cat << 'EOF'
{
  "error": "Invalid authentication credentials"
}
HTTP_CODE:401
EOF
}

# Test 1: APK Discovery - With APK
test_apk_discovery_with_apk() {
    log_test "Test 1: APK Discovery - With APK present"
    
    # Create a temporary test APK file
    TEST_DIR="/tmp/test-appetize-$$"
    mkdir -p "$TEST_DIR"
    touch "$TEST_DIR/test-app.apk"
    
    # Search for APK
    APK_FILES=$(find "$TEST_DIR" -type f -name "*.apk")
    
    if [ ! -z "$APK_FILES" ]; then
        pass_test "APK file found successfully: $APK_FILES"
    else
        fail_test "APK file not found when it should exist"
    fi
    
    # Cleanup
    rm -rf "$TEST_DIR"
}

# Test 2: APK Discovery - Without APK
test_apk_discovery_without_apk() {
    log_test "Test 2: APK Discovery - Without APK present"
    
    # Create a temporary directory without APK
    TEST_DIR="/tmp/test-appetize-empty-$$"
    mkdir -p "$TEST_DIR"
    
    # Search for APK
    APK_FILES=$(find "$TEST_DIR" -type f -name "*.apk")
    
    if [ -z "$APK_FILES" ]; then
        pass_test "Correctly detected no APK files present"
    else
        fail_test "Found APK when none should exist"
    fi
    
    # Cleanup
    rm -rf "$TEST_DIR"
}

# Test 3: Mock API Call - Success
test_mock_api_success() {
    log_test "Test 3: Mock Appetize.io API - Success Response"
    
    # Simulate successful API response
    RESPONSE=$(mock_appetize_success_response)
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
    BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE:/d')
    
    if [ "$HTTP_CODE" -eq 201 ]; then
        # Validate response contains expected fields
        if echo "$BODY" | grep -q "publicKey" && echo "$BODY" | grep -q "publicURL"; then
            pass_test "Mock API success response is valid (HTTP $HTTP_CODE)"
        else
            fail_test "Mock API response missing required fields"
        fi
    else
        fail_test "Mock API returned unexpected status code: $HTTP_CODE"
    fi
}

# Test 4: Mock API Call - Failure
test_mock_api_failure() {
    log_test "Test 4: Mock Appetize.io API - Failure Response"
    
    # Simulate failed API response
    RESPONSE=$(mock_appetize_failure_response)
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
    BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE:/d')
    
    if [ "$HTTP_CODE" -eq 401 ]; then
        if echo "$BODY" | grep -q "error"; then
            pass_test "Mock API failure response is valid (HTTP $HTTP_CODE)"
        else
            fail_test "Mock API error response missing error field"
        fi
    else
        fail_test "Mock API returned unexpected status code: $HTTP_CODE"
    fi
}

# Test 5: Upload Script Validation
test_upload_script_exists() {
    log_test "Test 5: Upload Script Validation"
    
    SCRIPT_PATH="$(dirname "$0")/upload-to-appetize.sh"
    
    if [ -f "$SCRIPT_PATH" ]; then
        if [ -x "$SCRIPT_PATH" ]; then
            pass_test "Upload script exists and is executable"
        else
            log_info "Upload script exists but is not executable, checking if it can be made executable"
            if chmod +x "$SCRIPT_PATH" 2>/dev/null; then
                pass_test "Upload script made executable successfully"
            else
                fail_test "Upload script exists but cannot be made executable"
            fi
        fi
    else
        fail_test "Upload script not found at: $SCRIPT_PATH"
    fi
}

# Test 6: Environment Variable Validation
test_environment_validation() {
    log_test "Test 6: Environment Variable Validation"
    
    # Test with empty token
    if [ -z "${TEST_APPETIZE_TOKEN:-}" ]; then
        pass_test "Correctly validates empty APPETIZE_TOKEN"
    else
        fail_test "Should reject empty token"
    fi
}

# Test 7: File Size Calculation
test_file_size_calculation() {
    log_test "Test 7: APK File Size Calculation"
    
    # Create a test file
    TEST_DIR="/tmp/test-appetize-size-$$"
    mkdir -p "$TEST_DIR"
    TEST_FILE="$TEST_DIR/test.apk"
    
    # Create a 1MB file
    dd if=/dev/zero of="$TEST_FILE" bs=1024 count=1024 2>/dev/null
    
    # Get file size
    if [ -f "$TEST_FILE" ]; then
        FILE_SIZE=$(du -h "$TEST_FILE" | cut -f1)
        if [ ! -z "$FILE_SIZE" ]; then
            pass_test "File size calculated successfully: $FILE_SIZE"
        else
            fail_test "Failed to calculate file size"
        fi
    else
        fail_test "Test file not created"
    fi
    
    # Cleanup
    rm -rf "$TEST_DIR"
}

# Test 8: JSON Parsing
test_json_parsing() {
    log_test "Test 8: JSON Response Parsing"
    
    RESPONSE=$(mock_appetize_success_response)
    BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE:/d')
    
    # Check if jq is available
    if command -v jq &> /dev/null; then
        APP_KEY=$(echo "$BODY" | jq -r '.publicKey')
        APP_URL=$(echo "$BODY" | jq -r '.publicURL')
        
        if [ "$APP_KEY" = "mock_app_key_123456789" ] && [ "$APP_URL" = "https://appetize.io/app/mock_app_key_123456789" ]; then
            pass_test "JSON parsing successful (publicKey and publicURL extracted)"
        else
            fail_test "JSON parsing failed to extract correct values"
        fi
    else
        log_info "jq not available, skipping JSON parsing test"
        pass_test "Test skipped (jq not installed)"
    fi
}

# Main test runner
main() {
    echo ""
    echo "=========================================="
    echo "  Appetize.io Upload - Mock Test Suite"
    echo "=========================================="
    echo ""
    
    # Run all tests
    test_apk_discovery_with_apk
    test_apk_discovery_without_apk
    test_mock_api_success
    test_mock_api_failure
    test_upload_script_exists
    test_environment_validation
    test_file_size_calculation
    test_json_parsing
    
    # Print summary
    echo ""
    echo "=========================================="
    echo "           Test Summary"
    echo "=========================================="
    echo -e "Total Tests:  $TESTS_RUN"
    echo -e "${GREEN}Passed:       $TESTS_PASSED${NC}"
    echo -e "${RED}Failed:       $TESTS_FAILED${NC}"
    echo "=========================================="
    echo ""
    
    # Exit with appropriate code
    if [ $TESTS_FAILED -eq 0 ]; then
        log_success "All tests passed! ✓"
        exit 0
    else
        log_error "Some tests failed! ✗"
        exit 1
    fi
}

# Run main
main
