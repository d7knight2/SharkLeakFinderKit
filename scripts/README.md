# Auto Resolve Merge Conflicts Script

## Overview

The `resolve_conflicts.sh` script automates the resolution of merge conflicts in open pull requests. It provides detailed logging, robust error handling, and prevents excessive email notifications by only commenting on PRs when meaningful actions are taken.

## Features

### 1. Enhanced Logging
- **Timestamped logs**: Every log entry includes a timestamp in format `YYYY-MM-DD HH:MM:SS`
- **Log levels**: INFO, WARN, ERROR, SUCCESS with color-coded output
- **Detailed error reporting**: Captures and logs command outputs for debugging

### 2. Smart Notification System
The script only sends PR comments when:
- ✅ **Conflicts are successfully resolved** - notifies that merge was successful
- ❌ **Conflict resolution fails** - notifies with detailed error information
- **NO notifications sent** when PRs have no conflicts - prevents spam

### 3. Robust Conflict Resolution
- Validates environment before execution
- Fetches latest changes from remote
- Attempts automatic merge with base branch
- Handles multiple error scenarios gracefully
- Returns repository to original state after processing

### 4. Comprehensive Error Handling
- Validates GitHub CLI availability
- Checks for required environment variables
- Handles git command failures
- Provides detailed error messages for debugging

## Usage

### In GitHub Actions

```yaml
- name: Resolve merge conflicts
  env:
    GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    bash scripts/resolve_conflicts.sh
```

### Local Testing

```bash
# Set GitHub token
export GITHUB_TOKEN="your_github_token"

# Run the script
bash scripts/resolve_conflicts.sh
```

## Requirements

- **bash**: Shell environment
- **git**: Version control
- **gh**: GitHub CLI tool
- **jq**: JSON processor
- **GITHUB_TOKEN** or **GH_TOKEN**: GitHub personal access token with appropriate permissions

## Permissions Required

The GitHub token needs the following permissions:
- `contents: write` - To push merge commits
- `pull-requests: write` - To add comments to PRs

## How It Works

1. **Initialization**
   - Validates environment (gh CLI, git, token)
   - Configures git with bot credentials

2. **Fetch Pull Requests**
   - Retrieves all open PRs using GitHub CLI
   - Checks mergeable status for each PR

3. **Process Conflicts**
   - For each PR with conflicts:
     - Checks out the PR branch
     - Attempts to merge the base branch
     - Pushes changes if successful
     - Adds a comment only on success or failure
   - Skips PRs without conflicts (no comment added)

4. **Summary Report**
   - Logs total PRs processed
   - Reports PRs without conflicts
   - Reports successful resolutions
   - Reports failed resolutions

## Exit Codes

- `0`: Success (all operations completed, or no PRs to process)
- `1`: Critical failure (environment validation failed, or all conflict resolutions failed)

## Example Output

```
[2026-01-07 08:10:27] [INFO] ==========================================
[2026-01-07 08:10:27] [INFO] Auto Resolve Merge Conflicts Script
[2026-01-07 08:10:27] [INFO] ==========================================
[2026-01-07 08:10:27] [INFO] GitHub CLI is available
[2026-01-07 08:10:27] [SUCCESS] Environment validation passed
[2026-01-07 08:10:27] [INFO] Configuring git...
[2026-01-07 08:10:28] [INFO] Fetching open pull requests...
[2026-01-07 08:10:29] [INFO] Found 3 open pull request(s)
[2026-01-07 08:10:29] [INFO] Processing 3 pull request(s)...
[2026-01-07 08:10:29] [INFO] ==========================================
[2026-01-07 08:10:29] [INFO] Processing PR #42: feature-branch -> main
[2026-01-07 08:10:29] [INFO] Mergeable status: CONFLICTING
[2026-01-07 08:10:29] [WARN] PR #42 has merge conflicts. Attempting resolution...
[2026-01-07 08:10:30] [SUCCESS] Successfully resolved merge conflicts for PR #42
[2026-01-07 08:10:30] [INFO] ==========================================
[2026-01-07 08:10:30] [INFO] Summary:
[2026-01-07 08:10:30] [INFO]   Total PRs processed: 3
[2026-01-07 08:10:30] [INFO]   PRs without conflicts: 2
[2026-01-07 08:10:30] [INFO]   Conflicts resolved: 1
[2026-01-07 08:10:30] [INFO]   Conflicts failed: 0
[2026-01-07 08:10:30] [SUCCESS] Script completed successfully
```

## Troubleshooting

### Script fails with "GitHub CLI is not installed"
Install GitHub CLI: https://cli.github.com/

### Script fails with "GitHub token not found"
Set the `GITHUB_TOKEN` or `GH_TOKEN` environment variable with a valid token.

### Script fails with "Not in a git repository"
Run the script from within a git repository directory.

### Merge conflicts cannot be resolved automatically
Some conflicts are too complex for automatic resolution. The script will:
- Abort the merge attempt
- Add a detailed comment to the PR explaining the issue
- Continue processing other PRs

## Maintenance

### Updating Git Configuration
The script configures git with bot credentials. To change:
```bash
# In the script, modify:
git config --global user.name "your-bot-name"
git config --global user.email "your-bot-email"
```

### Adjusting PR Limit
The script fetches up to 100 PRs by default. To change:
```bash
# In the script, modify the --limit parameter:
gh pr list --state open --json number,headRefName,baseRefName,mergeable --limit 200
```

## Best Practices

1. **Run on Schedule**: Use cron or GitHub Actions schedule trigger
2. **Monitor Logs**: Review workflow logs regularly for issues
3. **Test Locally**: Test changes to the script locally before deploying
4. **Review Auto-Merged PRs**: Always review PRs that were automatically merged

## Security Considerations

- The script requires write access to the repository
- Only run with trusted GitHub tokens
- Review the script before granting repository access
- Consider branch protection rules to prevent unwanted auto-merges
