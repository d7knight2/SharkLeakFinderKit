#!/bin/bash

# Auto Resolve Merge Conflicts Script
# This script attempts to resolve merge conflicts in open pull requests
# It provides detailed logging and only sends notifications when meaningful updates occur

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log levels
LOG_INFO="INFO"
LOG_WARN="WARN"
LOG_ERROR="ERROR"
LOG_SUCCESS="SUCCESS"

# State tracking
TOTAL_PRS_PROCESSED=0
CONFLICTS_RESOLVED=0
CONFLICTS_FAILED=0
NO_CONFLICT_COUNT=0

# Logging function with timestamps and levels
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case $level in
        "$LOG_INFO")
            echo -e "${BLUE}[${timestamp}] [INFO]${NC} ${message}"
            ;;
        "$LOG_WARN")
            echo -e "${YELLOW}[${timestamp}] [WARN]${NC} ${message}"
            ;;
        "$LOG_ERROR")
            echo -e "${RED}[${timestamp}] [ERROR]${NC} ${message}"
            ;;
        "$LOG_SUCCESS")
            echo -e "${GREEN}[${timestamp}] [SUCCESS]${NC} ${message}"
            ;;
    esac
}

# Function to check if gh CLI is available
check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        log "$LOG_ERROR" "GitHub CLI (gh) is not installed or not in PATH"
        exit 1
    fi
    log "$LOG_INFO" "GitHub CLI is available"
}

# Function to validate environment
validate_environment() {
    log "$LOG_INFO" "Validating environment..."
    
    if [ -z "$GH_TOKEN" ] && [ -z "$GITHUB_TOKEN" ]; then
        log "$LOG_ERROR" "GitHub token not found. Set GH_TOKEN or GITHUB_TOKEN environment variable"
        exit 1
    fi
    
    # Use GH_TOKEN if available, otherwise fall back to GITHUB_TOKEN
    export GH_TOKEN="${GH_TOKEN:-$GITHUB_TOKEN}"
    
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log "$LOG_ERROR" "Not in a git repository"
        exit 1
    fi
    
    log "$LOG_SUCCESS" "Environment validation passed"
}

# Function to get open pull requests with conflicts
get_conflicting_prs() {
    log "$LOG_INFO" "Fetching open pull requests..."
    
    local prs
    local gh_exit_code=0
    
    prs=$(gh pr list --state open --json number,headRefName,baseRefName,mergeable --limit 100 2>&1) || gh_exit_code=$?
    
    if [ $gh_exit_code -ne 0 ]; then
        log "$LOG_ERROR" "Failed to fetch pull requests from GitHub"
        log "$LOG_ERROR" "Error output: $prs"
        echo "[]"
        return 1
    fi
    
    if [ -z "$prs" ] || [ "$prs" = "[]" ]; then
        log "$LOG_INFO" "No open pull requests found"
        echo "[]"
        return 0
    fi
    
    local pr_count=$(echo "$prs" | jq '. | length' 2>/dev/null || echo "0")
    log "$LOG_INFO" "Found $pr_count open pull request(s)"
    
    echo "$prs"
}

# Function to restore the original branch
restore_original_branch() {
    local original_branch=$1
    log "$LOG_INFO" "Restoring original branch..."
    
    # Try original branch first
    if git checkout "$original_branch" 2>/dev/null; then
        return 0
    fi
    
    # If that fails, try to get the default branch from remote
    local default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "")
    
    if [ -n "$default_branch" ]; then
        git checkout "$default_branch" 2>/dev/null && return 0
    fi
    
    # Fallback to common branch names
    git checkout main 2>/dev/null || git checkout master 2>/dev/null || true
}

# Function to attempt conflict resolution for a PR
resolve_pr_conflicts() {
    local pr_number=$1
    local head_ref=$2
    local base_ref=$3
    local mergeable=$4
    
    log "$LOG_INFO" "Processing PR #$pr_number: $head_ref -> $base_ref"
    log "$LOG_INFO" "Mergeable status: $mergeable"
    
    # Only process PRs with conflicts
    if [ "$mergeable" != "CONFLICTING" ]; then
        log "$LOG_INFO" "PR #$pr_number has no conflicts (status: $mergeable). Skipping."
        NO_CONFLICT_COUNT=$((NO_CONFLICT_COUNT + 1))
        return 0
    fi
    
    log "$LOG_WARN" "PR #$pr_number has merge conflicts. Attempting resolution..."
    
    # Store current branch to return to later
    local original_branch=$(git branch --show-current)
    log "$LOG_INFO" "Current branch: $original_branch"
    
    # Fetch latest changes
    log "$LOG_INFO" "Fetching latest changes from remote..."
    if ! git fetch origin; then
        log "$LOG_ERROR" "Failed to fetch from origin"
        return 1
    fi
    
    # Checkout the PR branch
    log "$LOG_INFO" "Checking out branch: $head_ref"
    local checkout_output
    local checkout_exit_code=0
    
    checkout_output=$(git checkout "$head_ref" 2>&1) || checkout_exit_code=$?
    
    if [ $checkout_exit_code -ne 0 ]; then
        log "$LOG_ERROR" "Failed to checkout branch $head_ref"
        log "$LOG_ERROR" "Checkout output: $checkout_output"
        gh pr comment "$pr_number" --body "⚠️ **Automated Merge Conflict Resolution Failed**

Unable to checkout branch \`$head_ref\`. This may indicate:
- The branch has been deleted
- Insufficient permissions
- Local repository state issues

**Action Required:** Manual intervention needed." || true
        CONFLICTS_FAILED=$((CONFLICTS_FAILED + 1))
        return 1
    fi
    
    log "$LOG_SUCCESS" "Successfully checked out $head_ref"
    
    # Pull latest changes on the head branch
    log "$LOG_INFO" "Pulling latest changes for $head_ref..."
    git pull origin "$head_ref" --ff-only 2>&1 || log "$LOG_WARN" "Could not fast-forward pull (may be expected)"
    
    # Attempt to merge the base branch
    log "$LOG_INFO" "Attempting to merge origin/$base_ref into $head_ref..."
    
    local merge_output
    local merge_exit_code=0
    
    # Capture merge output and exit code
    merge_output=$(git merge "origin/$base_ref" --no-edit -m "Auto-merge $base_ref to resolve conflicts" 2>&1) || merge_exit_code=$?
    
    if [ $merge_exit_code -eq 0 ]; then
        log "$LOG_SUCCESS" "Successfully merged origin/$base_ref into $head_ref"
        log "$LOG_INFO" "Merge output: $merge_output"
        
        # Push the changes
        log "$LOG_INFO" "Pushing changes to origin/$head_ref..."
        local push_output
        local push_exit_code=0
        
        push_output=$(git push origin "$head_ref" 2>&1) || push_exit_code=$?
        
        if [ $push_exit_code -eq 0 ]; then
            log "$LOG_SUCCESS" "Successfully pushed changes for PR #$pr_number"
            log "$LOG_INFO" "Push output: $push_output"
            
            # Only send notification on successful resolution
            gh pr comment "$pr_number" --body "✅ **Automated Merge Conflict Resolution Successful**

Successfully merged \`$base_ref\` into \`$head_ref\` to resolve conflicts.

**Changes:** The base branch has been merged into your feature branch. Please review the changes and ensure everything works as expected." || log "$LOG_WARN" "Failed to add comment to PR #$pr_number"
            
            CONFLICTS_RESOLVED=$((CONFLICTS_RESOLVED + 1))
            
            # Return to original branch
            restore_original_branch "$original_branch"
            return 0
        else
            log "$LOG_ERROR" "Failed to push changes for PR #$pr_number"
            log "$LOG_ERROR" "Push output: $push_output"
            
            gh pr comment "$pr_number" --body "⚠️ **Automated Merge Conflict Resolution Failed**

The merge was successful locally, but failed to push changes to \`$head_ref\`.

**Possible causes:**
- Branch protection rules preventing push
- Insufficient permissions
- Remote branch has diverged

**Action Required:** Manual intervention needed." || log "$LOG_WARN" "Failed to add comment to PR #$pr_number"
            
            CONFLICTS_FAILED=$((CONFLICTS_FAILED + 1))
            
            # Return to original branch
            restore_original_branch "$original_branch"
            return 1
        fi
    else
        log "$LOG_ERROR" "Failed to automatically merge origin/$base_ref into $head_ref"
        log "$LOG_ERROR" "Merge output: $merge_output"
        log "$LOG_INFO" "Aborting merge..."
        
        # Abort the merge
        git merge --abort 2>/dev/null || log "$LOG_WARN" "No merge to abort or abort failed"
        
        # Only send notification on actual merge failure
        gh pr comment "$pr_number" --body "⚠️ **Automated Merge Conflict Resolution Failed**

The conflicts in this PR are too complex for automated resolution.

**Merge attempt details:**
\`\`\`
$merge_output
\`\`\`

**Action Required:** Please resolve the conflicts manually:
1. Pull the latest changes from \`$base_ref\`
2. Resolve conflicts in your local branch
3. Commit the resolved changes
4. Push to \`$head_ref\`" || log "$LOG_WARN" "Failed to add comment to PR #$pr_number"
        
        CONFLICTS_FAILED=$((CONFLICTS_FAILED + 1))
        
        # Return to original branch
        restore_original_branch "$original_branch"
        return 1
    fi
}

# Main execution
main() {
    log "$LOG_INFO" "=========================================="
    log "$LOG_INFO" "Auto Resolve Merge Conflicts Script"
    log "$LOG_INFO" "=========================================="
    
    # Validate environment
    check_gh_cli
    validate_environment
    
    # Configure git
    log "$LOG_INFO" "Configuring git..."
    git config --global user.name "github-actions[bot]"
    git config --global user.email "github-actions[bot]@users.noreply.github.com"
    
    # Get open pull requests
    local prs=$(get_conflicting_prs)
    local pr_count=$(echo "$prs" | jq '. | length' 2>/dev/null || echo "0")
    
    # Check if pr_count is a valid number and greater than 0
    if ! [[ "$pr_count" =~ ^[0-9]+$ ]] || [ "$pr_count" -eq 0 ]; then
        log "$LOG_INFO" "No pull requests to process. Exiting."
        exit 0
    fi
    
    log "$LOG_INFO" "Processing $pr_count pull request(s)..."
    
    # Process each PR
    for i in $(seq 0 $((pr_count - 1))); do
        local pr_number=$(echo "$prs" | jq -r ".[$i].number")
        local head_ref=$(echo "$prs" | jq -r ".[$i].headRefName")
        local base_ref=$(echo "$prs" | jq -r ".[$i].baseRefName")
        local mergeable=$(echo "$prs" | jq -r ".[$i].mergeable")
        
        log "$LOG_INFO" "=========================================="
        TOTAL_PRS_PROCESSED=$((TOTAL_PRS_PROCESSED + 1))
        
        # Attempt to resolve conflicts
        resolve_pr_conflicts "$pr_number" "$head_ref" "$base_ref" "$mergeable"
        
        log "$LOG_INFO" "=========================================="
    done
    
    # Summary
    log "$LOG_INFO" ""
    log "$LOG_INFO" "=========================================="
    log "$LOG_INFO" "Summary:"
    log "$LOG_INFO" "  Total PRs processed: $TOTAL_PRS_PROCESSED"
    log "$LOG_INFO" "  PRs without conflicts: $NO_CONFLICT_COUNT"
    log "$LOG_INFO" "  Conflicts resolved: $CONFLICTS_RESOLVED"
    log "$LOG_INFO" "  Conflicts failed: $CONFLICTS_FAILED"
    log "$LOG_INFO" "=========================================="
    
    # Only exit with error if we tried to resolve conflicts and all failed
    if [ $CONFLICTS_FAILED -gt 0 ] && [ $CONFLICTS_RESOLVED -eq 0 ]; then
        log "$LOG_ERROR" "All conflict resolution attempts failed"
        exit 1
    fi
    
    log "$LOG_SUCCESS" "Script completed successfully"
    exit 0
}

# Run main function
main
