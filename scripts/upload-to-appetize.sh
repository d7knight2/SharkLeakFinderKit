#!/bin/bash

# Upload APK to Appetize.io
# Usage: ./upload-to-appetize.sh <apk_path> <appetize_token>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check arguments
if [ "$#" -lt 2 ]; then
    log_error "Usage: $0 <apk_path> <appetize_token>"
    exit 1
fi

APK_PATH="$1"
APPETIZE_TOKEN="$2"

log_info "Starting APK upload to Appetize.io"

# Validate APK file exists
if [ ! -f "$APK_PATH" ]; then
    log_error "APK file not found: $APK_PATH"
    exit 1
fi

log_success "Found APK file: $APK_PATH"

# Get APK file size
APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
log_info "APK size: $APK_SIZE"

# Validate token
if [ -z "$APPETIZE_TOKEN" ]; then
    log_error "APPETIZE_TOKEN is empty"
    exit 1
fi

log_info "Uploading to Appetize.io API..."

# Upload to Appetize.io
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" \
    -X POST \
    -u "$APPETIZE_TOKEN:" \
    -F "file=@$APK_PATH" \
    -F "platform=android" \
    https://api.appetize.io/v1/apps)

# Extract HTTP code and body
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE:/d')

log_info "API Response (HTTP $HTTP_CODE):"

# Pretty print JSON if possible
if command -v jq &> /dev/null; then
    echo "$BODY" | jq '.'
else
    echo "$BODY"
fi

# Check HTTP status code
if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 201 ]; then
    log_success "Successfully uploaded APK to Appetize.io"
    
    # Extract app details
    if command -v jq &> /dev/null; then
        APP_URL=$(echo "$BODY" | jq -r '.publicURL // .url // empty')
        APP_KEY=$(echo "$BODY" | jq -r '.publicKey // .key // empty')
        
        if [ -n "$APP_URL" ]; then
            log_info "App URL: $APP_URL"
        fi
        
        if [ -n "$APP_KEY" ]; then
            log_info "App Key: $APP_KEY"
        fi
    fi
    
    exit 0
else
    log_error "Failed to upload APK (HTTP $HTTP_CODE)"
    exit 1
fi
