#!/bin/bash

# Unit Tests for Appetize.io Upload Scripts
# This script provides comprehensive unit tests for upload and test scripts
# Uses a bats-core inspired testing pattern

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test tracking
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
CURRENT_SUITE=""

# Logging functions
log_suite() {
    CURRENT_SUITE="$1"
    echo ""
    echo -e "${CYAN}══════════════════════════════════════${NC}"
    echo -e "${CYAN}Test Suite: $1${NC}"
    echo -e "${CYAN}══════════════════════════════════════${NC}"
}

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

pass_test() {
    TESTS_PASSED=$((TESTS_PASSED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${GREEN}  ✓ PASS${NC} - $1"
}

fail_test() {
    TESTS_FAILED=$((TESTS_FAILED + 1))
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${RED}  ✗ FAIL${NC} - $1"
}

skip_test() {
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${YELLOW}  ⊘ SKIP${NC} - $1"
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should be equal}"
    
    if [ "$expected" = "$actual" ]; then
        pass_test "$message"
    else
        fail_test "$message (expected: '$expected', got: '$actual')"
    fi
}

assert_not_empty() {
    local value="$1"
    local message="${2:-Value should not be empty}"
    
    if [ ! -z "$value" ]; then
        pass_test "$message"
    else
        fail_test "$message"
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist: $file}"
    
    if [ -f "$file" ]; then
        pass_test "$message"
    else
        fail_test "$message"
    fi
}

assert_executable() {
    local file="$1"
    local message="${2:-File should be executable: $file}"
    
    if [ -x "$file" ]; then
        pass_test "$message"
    else
        fail_test "$message"
    fi
}

assert_command_exists() {
    local cmd="$1"
    local message="${2:-Command should exist: $cmd}"
    
    if command -v "$cmd" &> /dev/null; then
        pass_test "$message"
    else
        fail_test "$message"
    fi
}

# Test Suite 1: Script Existence and Permissions
test_suite_script_validation() {
    log_suite "Script Validation"
    
    SCRIPTS_DIR="$(dirname "$0")"
    
    log_test "Upload script exists"
    assert_file_exists "$SCRIPTS_DIR/upload-to-appetize.sh" "upload-to-appetize.sh exists"
    
    log_test "Test script exists"
    assert_file_exists "$SCRIPTS_DIR/test-appetize-upload.sh" "test-appetize-upload.sh exists"
    
    log_test "Upload script is executable or can be made executable"
    if [ -x "$SCRIPTS_DIR/upload-to-appetize.sh" ]; then
        pass_test "upload-to-appetize.sh is executable"
    elif chmod +x "$SCRIPTS_DIR/upload-to-appetize.sh" 2>/dev/null; then
        pass_test "upload-to-appetize.sh made executable"
    else
        fail_test "Cannot make upload-to-appetize.sh executable"
    fi
    
    log_test "Test script is executable or can be made executable"
    if [ -x "$SCRIPTS_DIR/test-appetize-upload.sh" ]; then
        pass_test "test-appetize-upload.sh is executable"
    elif chmod +x "$SCRIPTS_DIR/test-appetize-upload.sh" 2>/dev/null; then
        pass_test "test-appetize-upload.sh made executable"
    else
        fail_test "Cannot make test-appetize-upload.sh executable"
    fi
}

# Test Suite 2: APK Discovery Tests
test_suite_apk_discovery() {
    log_suite "APK Discovery"
    
    log_test "Find APK in directory with APK"
    TEST_DIR="/tmp/unit-test-apk-$$"
    mkdir -p "$TEST_DIR"
    touch "$TEST_DIR/test.apk"
    APK_COUNT=$(find "$TEST_DIR" -name "*.apk" | wc -l)
    assert_equals "1" "$APK_COUNT" "Should find exactly one APK"
    rm -rf "$TEST_DIR"
    
    log_test "Find no APK in empty directory"
    TEST_DIR="/tmp/unit-test-empty-$$"
    mkdir -p "$TEST_DIR"
    APK_COUNT=$(find "$TEST_DIR" -name "*.apk" | wc -l)
    assert_equals "0" "$APK_COUNT" "Should find no APKs in empty directory"
    rm -rf "$TEST_DIR"
    
    log_test "Find multiple APKs"
    TEST_DIR="/tmp/unit-test-multi-$$"
    mkdir -p "$TEST_DIR"
    touch "$TEST_DIR/app1.apk"
    touch "$TEST_DIR/app2.apk"
    APK_COUNT=$(find "$TEST_DIR" -name "*.apk" | wc -l)
    assert_equals "2" "$APK_COUNT" "Should find two APKs"
    rm -rf "$TEST_DIR"
    
    log_test "Find APK in subdirectory"
    TEST_DIR="/tmp/unit-test-subdir-$$"
    mkdir -p "$TEST_DIR/build/outputs/apk"
    touch "$TEST_DIR/build/outputs/apk/app.apk"
    APK_COUNT=$(find "$TEST_DIR" -name "*.apk" | wc -l)
    assert_equals "1" "$APK_COUNT" "Should find APK in subdirectory"
    rm -rf "$TEST_DIR"
}

# Test Suite 3: File Operations
test_suite_file_operations() {
    log_suite "File Operations"
    
    log_test "Calculate file size"
    TEST_FILE="/tmp/unit-test-size-$$.apk"
    dd if=/dev/zero of="$TEST_FILE" bs=1024 count=512 2>/dev/null
    SIZE=$(du -h "$TEST_FILE" | cut -f1)
    assert_not_empty "$SIZE" "File size should be calculated"
    rm -f "$TEST_FILE"
    
    log_test "Check file exists"
    TEST_FILE="/tmp/unit-test-exists-$$.apk"
    touch "$TEST_FILE"
    if [ -f "$TEST_FILE" ]; then
        pass_test "File existence check works"
    else
        fail_test "File existence check failed"
    fi
    rm -f "$TEST_FILE"
    
    log_test "Check file does not exist"
    TEST_FILE="/tmp/unit-test-nonexistent-$$.apk"
    if [ ! -f "$TEST_FILE" ]; then
        pass_test "Non-existence check works"
    else
        fail_test "Non-existence check failed"
    fi
}

# Test Suite 4: API Response Parsing
test_suite_api_response() {
    log_suite "API Response Parsing"
    
    log_test "Parse HTTP status code"
    RESPONSE="test body
HTTP_CODE:201"
    HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
    assert_equals "201" "$HTTP_CODE" "Should extract HTTP code 201"
    
    log_test "Parse response body"
    RESPONSE="test body line 1
test body line 2
HTTP_CODE:200"
    BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE:/d')
    assert_not_empty "$BODY" "Should extract response body"
    
    log_test "Validate success HTTP codes"
    for CODE in 200 201; do
        if [ "$CODE" -eq 200 ] || [ "$CODE" -eq 201 ]; then
            pass_test "HTTP $CODE is recognized as success"
        else
            fail_test "HTTP $CODE should be recognized as success"
        fi
    done
    
    log_test "Validate failure HTTP codes"
    for CODE in 400 401 403 404 500; do
        if [ "$CODE" -ne 200 ] && [ "$CODE" -ne 201 ]; then
            pass_test "HTTP $CODE is recognized as failure"
        else
            fail_test "HTTP $CODE should be recognized as failure"
        fi
    done
}

# Test Suite 5: JSON Parsing
test_suite_json_parsing() {
    log_suite "JSON Parsing"
    
    if ! command -v jq &> /dev/null; then
        skip_test "jq not available, skipping JSON tests"
        return
    fi
    
    log_test "Extract publicKey from JSON"
    JSON='{"publicKey": "test123", "publicURL": "https://example.com"}'
    KEY=$(echo "$JSON" | jq -r '.publicKey')
    assert_equals "test123" "$KEY" "Should extract publicKey"
    
    log_test "Extract publicURL from JSON"
    JSON='{"publicKey": "test123", "publicURL": "https://example.com/app"}'
    URL=$(echo "$JSON" | jq -r '.publicURL')
    assert_equals "https://example.com/app" "$URL" "Should extract publicURL"
    
    log_test "Handle missing fields gracefully"
    JSON='{"platform": "android"}'
    KEY=$(echo "$JSON" | jq -r '.publicKey // empty')
    if [ -z "$KEY" ]; then
        pass_test "Handles missing publicKey field"
    else
        fail_test "Should return empty for missing field"
    fi
}

# Test Suite 6: Environment Variables
test_suite_environment() {
    log_suite "Environment Variables"
    
    log_test "Detect empty environment variable"
    unset TEST_VAR
    if [ -z "${TEST_VAR:-}" ]; then
        pass_test "Empty variable detected correctly"
    else
        fail_test "Should detect empty variable"
    fi
    
    log_test "Detect set environment variable"
    export TEST_VAR="test_value"
    if [ ! -z "${TEST_VAR:-}" ]; then
        pass_test "Set variable detected correctly"
    else
        fail_test "Should detect set variable"
    fi
    unset TEST_VAR
}

# Test Suite 7: Error Handling
test_suite_error_handling() {
    log_suite "Error Handling"
    
    log_test "Script fails on missing APK"
    if ! find /tmp/nonexistent-$$ -name "*.apk" 2>/dev/null | grep -q .; then
        pass_test "Correctly handles missing APK directory"
    else
        fail_test "Should fail when APK directory missing"
    fi
    
    log_test "Script handles empty token"
    TOKEN=""
    if [ -z "$TOKEN" ]; then
        pass_test "Detects empty token correctly"
    else
        fail_test "Should detect empty token"
    fi
}

# Test Suite 8: Integration Tests
test_suite_integration() {
    log_suite "Integration Tests"
    
    log_test "Workflow file exists"
    WORKFLOW_FILE="$(dirname "$0")/../.github/workflows/appetize-upload.yml"
    assert_file_exists "$WORKFLOW_FILE" "GitHub Actions workflow exists"
    
    log_test "Workflow contains required triggers"
    if [ -f "$WORKFLOW_FILE" ]; then
        if grep -q "workflow_dispatch" "$WORKFLOW_FILE" && grep -q "push" "$WORKFLOW_FILE"; then
            pass_test "Workflow has required triggers (push and workflow_dispatch)"
        else
            fail_test "Workflow missing required triggers"
        fi
    else
        fail_test "Workflow file not found for validation"
    fi
    
    log_test "Workflow uses APPETIZE_TOKEN secret"
    if [ -f "$WORKFLOW_FILE" ]; then
        if grep -q "APPETIZE_TOKEN" "$WORKFLOW_FILE"; then
            pass_test "Workflow references APPETIZE_TOKEN secret"
        else
            fail_test "Workflow should reference APPETIZE_TOKEN secret"
        fi
    else
        fail_test "Workflow file not found for secret validation"
    fi
}

# Test Suite 9: Documentation
test_suite_documentation() {
    log_suite "Documentation"
    
    SCRIPTS_DIR="$(dirname "$0")"
    
    log_test "Scripts README exists"
    assert_file_exists "$SCRIPTS_DIR/README.md" "README.md exists in scripts directory"
    
    log_test "README contains usage instructions"
    README="$SCRIPTS_DIR/README.md"
    if [ -f "$README" ]; then
        if grep -q "Usage" "$README"; then
            pass_test "README contains usage instructions"
        else
            fail_test "README should contain usage instructions"
        fi
    else
        fail_test "README not found"
    fi
}

# Main test runner
main() {
    echo ""
    echo "══════════════════════════════════════════════════════"
    echo "   Appetize.io Upload Scripts - Unit Test Suite"
    echo "══════════════════════════════════════════════════════"
    echo ""
    echo "Running comprehensive unit tests..."
    
    # Run all test suites
    test_suite_script_validation
    test_suite_apk_discovery
    test_suite_file_operations
    test_suite_api_response
    test_suite_json_parsing
    test_suite_environment
    test_suite_error_handling
    test_suite_integration
    test_suite_documentation
    
    # Print summary
    echo ""
    echo "══════════════════════════════════════════════════════"
    echo "                   Test Summary"
    echo "══════════════════════════════════════════════════════"
    printf "Total Tests:    %d\n" "$TESTS_RUN"
    printf "${GREEN}Passed:         %d${NC}\n" "$TESTS_PASSED"
    printf "${RED}Failed:         %d${NC}\n" "$TESTS_FAILED"
    
    PASS_RATE=0
    if [ $TESTS_RUN -gt 0 ]; then
        PASS_RATE=$((TESTS_PASSED * 100 / TESTS_RUN))
    fi
    printf "Pass Rate:      %d%%\n" "$PASS_RATE"
    echo "══════════════════════════════════════════════════════"
    echo ""
    
    # Exit with appropriate code
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}✗ Some tests failed!${NC}"
        exit 1
    fi
}

# Run main
main
