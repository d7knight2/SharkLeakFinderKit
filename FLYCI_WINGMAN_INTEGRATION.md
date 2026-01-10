# FlyCI Wingman Integration Guide

This document provides a comprehensive guide to the FlyCI Wingman integration in this repository, including the automated workflows and GitHub App for applying suggested fixes.

## Table of Contents

1. [Overview](#overview)
2. [What is FlyCI Wingman?](#what-is-flyci-wingman)
3. [Integration Components](#integration-components)
4. [Workflow Integration](#workflow-integration)
5. [Automated Fix Application](#automated-fix-application)
6. [GitHub App Setup](#github-app-setup)
7. [Usage Guide](#usage-guide)
8. [Troubleshooting](#troubleshooting)

## Overview

This repository integrates FlyCI Wingman to provide intelligent CI failure analysis and suggested fixes. The integration includes:

- **Workflow Integration**: FlyCI Wingman runs automatically on CI job failures
- **GitHub Actions Automation**: Automatically applies Wingman's suggested fixes
- **GitHub App**: Node.js/Probot-based app for advanced automation with secure authentication

## What is FlyCI Wingman?

FlyCI Wingman is an AI-powered CI assistant that:
- Analyzes failing CI jobs
- Identifies root causes of failures
- Suggests code fixes as unified diff patches
- Comments directly on pull requests with actionable solutions

## Integration Components

### 1. Updated CI Workflows

The following workflows now include FlyCI Wingman as a final step on failure:

- **`.github/workflows/pr-tests.yml`**
  - `unit-tests` job
  - `ui-tests` job
  
- **`.github/workflows/appetize-upload.yml`**
  - `upload-apk` job
  
- **`.github/workflows/upload-apk-appetize.yml`**
  - `upload-apk` job

Each job includes:
```yaml
- name: FlyCI Wingman
  if: failure()
  uses: fly-ci/wingman-action@v1
```

This ensures Wingman analyzes failures without interrupting the CI workflow.

### 2. Automated Fix Application Workflow

**File**: `.github/workflows/apply-wingman-fixes.yml`

**Triggers**: When a comment is created on a PR

**What it does**:
1. Detects comments from Wingman (by username or diff content)
2. Extracts unified diff patches from code blocks
3. Checks out the PR branch
4. Applies patches using `git apply`
5. Commits and pushes changes
6. Reports results back to the PR

**Key Features**:
- ✅ Automatic detection of Wingman comments
- ✅ Multiple patch support in single comment
- ✅ Graceful handling of patch failures
- ✅ Automatic workflow re-run triggering
- ✅ Detailed status reporting

### 3. GitHub App (Probot-based)

**Location**: `wingman-app/`

**Technology Stack**:
- Node.js (18+)
- Probot framework
- simple-git for Git operations

**Features**:
- Monitors PR comments via webhooks
- Secure authentication with GitHub App private key
- Repository cloning and patch application
- Comprehensive error handling and reporting

## Workflow Integration

### How Wingman Steps Work

When a CI job fails:

1. **Failure Detected**: Job step fails with non-zero exit code
2. **Wingman Triggered**: The `if: failure()` condition activates the Wingman step
3. **Analysis**: Wingman analyzes logs and code context
4. **Suggestion**: Posts a comment on the PR with suggested fixes

Example workflow snippet:
```yaml
jobs:
  unit-tests:
    steps:
      - name: Run unit tests
        run: ./gradlew test
      
      # ... other steps ...
      
      - name: FlyCI Wingman
        if: failure()
        uses: fly-ci/wingman-action@v1
```

### Benefits

- **Non-Intrusive**: Only runs on failures, doesn't slow down successful builds
- **Contextual**: Has access to full job context and logs
- **Immediate Feedback**: Developers get suggestions while context is fresh

## Automated Fix Application

### GitHub Actions Solution

**Workflow**: `.github/workflows/apply-wingman-fixes.yml`

#### Process Flow

```
PR Comment Created
       ↓
Is it from Wingman? → No → Exit
       ↓ Yes
Extract Diff Patches
       ↓
Checkout PR Branch
       ↓
Apply Patches (git apply)
       ↓
Commit & Push
       ↓
Comment Result on PR
       ↓
Trigger CI Re-run
```

#### Permissions Required

```yaml
permissions:
  contents: write      # To commit and push changes
  pull-requests: write # To comment on PRs
  actions: write       # To trigger workflow re-runs
```

#### Usage

No manual action required! The workflow automatically:
1. Monitors all PR comments
2. Identifies Wingman suggestions
3. Applies fixes
4. Reports back

### GitHub App Solution

**Location**: `wingman-app/`

#### Advantages Over GitHub Actions

- ✅ **Better Authentication**: Uses GitHub App credentials
- ✅ **More Control**: Full programmatic control over Git operations
- ✅ **Scalability**: Can handle high-volume repositories
- ✅ **Customization**: Easy to extend with custom logic

#### Architecture

```javascript
// Main app structure (index.js)
module.exports = (app) => {
  app.on('issue_comment.created', async (context) => {
    // 1. Detect Wingman comment
    // 2. Extract patches
    // 3. Clone repository
    // 4. Apply patches
    // 5. Commit and push
    // 6. Report results
  });
};
```

## GitHub App Setup

### Prerequisites

- Node.js 18 or higher
- GitHub account with admin access to repositories
- GitHub App creation permissions

### Step-by-Step Setup

#### 1. Install Dependencies

```bash
cd wingman-app
npm install
```

#### 2. Create GitHub App

**Option A: Using Manifest** (Recommended)

1. Go to [GitHub Apps](https://github.com/settings/apps/new)
2. Click "New GitHub App"
3. Use "From manifest" option
4. Upload `wingman-app/manifest.json`

**Option B: Manual Creation**

1. Navigate to Settings → Developer settings → GitHub Apps
2. Click "New GitHub App"
3. Configure:
   - **App name**: flyci-wingman-applier
   - **Homepage URL**: Your repository URL
   - **Webhook URL**: Your deployment URL or smee.io channel
   - **Webhook secret**: Generate a secure random string

#### 3. Set Permissions

Required permissions:
- Repository permissions:
  - Contents: Read & Write
  - Issues: Write
  - Pull requests: Write
  - Actions: Write

Subscribe to events:
- Issue comment
- Pull request

#### 4. Generate Private Key

1. In GitHub App settings, scroll to "Private keys"
2. Click "Generate a private key"
3. Save the downloaded `.pem` file to `wingman-app/private-key.pem`

⚠️ **Important**: Never commit the private key!

#### 5. Configure Environment

```bash
cp .env.example .env
```

Edit `.env`:
```env
APP_ID=123456
WEBHOOK_SECRET=your-webhook-secret-here
PRIVATE_KEY_PATH=private-key.pem
WEBHOOK_PROXY_URL=https://smee.io/your-channel  # For development
LOG_LEVEL=info
PORT=3000
```

#### 6. Development Setup (Local)

Use smee.io for local webhook forwarding:

```bash
# Install smee-client globally
npm install -g smee-client

# Start smee proxy
smee --url https://smee.io/YOUR-CHANNEL --path /api/github/webhooks --port 3000
```

#### 7. Run the App

Development mode:
```bash
npm run dev
```

Production mode:
```bash
npm start
```

#### 8. Install on Repository

1. Go to your GitHub App page
2. Click "Install App"
3. Select the target repositories
4. Approve permissions

### Deployment

#### Heroku

```bash
heroku create flyci-wingman-applier
git subtree push --prefix wingman-app heroku main
heroku config:set APP_ID=your-app-id
heroku config:set WEBHOOK_SECRET=your-secret
heroku config:set PRIVATE_KEY="$(cat private-key.pem)"
```

#### Vercel

```bash
cd wingman-app
vercel deploy
```

Add environment variables in Vercel dashboard.

#### Docker

Create `wingman-app/Dockerfile`:
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

Build and run:
```bash
docker build -t wingman-app .
docker run -p 3000:3000 --env-file .env wingman-app
```

## Usage Guide

### For Developers

#### When CI Fails

1. **Wait for Wingman**: After a CI failure, Wingman analyzes and comments within 1-2 minutes
2. **Review Suggestions**: Check the comment for suggested fixes
3. **Automatic Application**: 
   - If using GitHub Actions workflow: Changes apply automatically
   - If using GitHub App: Same automatic behavior
4. **Verify Fix**: CI re-runs automatically after changes are pushed

#### Manual Application

If you prefer to apply fixes manually:

1. Copy the diff from Wingman's comment
2. Save to a file: `fix.patch`
3. Apply: `git apply fix.patch`
4. Commit and push

### For Repository Admins

#### Monitoring

**GitHub Actions Workflow**:
- View runs in Actions tab → "Apply FlyCI Wingman Fixes"
- Check workflow logs for application status

**GitHub App**:
- Check app logs (stdout/stderr)
- Review webhook deliveries in GitHub App settings
- Monitor success/failure rates

#### Maintenance

**Update Wingman Action Version**:
```yaml
# Update version in all workflows
- name: FlyCI Wingman
  if: failure()
  uses: fly-ci/wingman-action@v2  # Update version
```

**Update GitHub App**:
```bash
cd wingman-app
npm update probot
git commit -am "Update dependencies"
git push
# Redeploy to your hosting platform
```

## Troubleshooting

### Common Issues

#### 1. Wingman Not Running on Failures

**Symptoms**: CI fails but Wingman step doesn't execute

**Solutions**:
- Verify `if: failure()` condition is present
- Check workflow syntax is valid
- Ensure workflow has required permissions

#### 2. Patches Not Applying

**Symptoms**: Wingman comments but changes aren't applied

**For GitHub Actions Workflow**:
```bash
# Check workflow run logs
# Look for error messages in "Extract and apply patches" step
```

**For GitHub App**:
```bash
# Check app logs
# Common issues:
# - Invalid diff format
# - Branch conflicts
# - Permission issues
```

**Solutions**:
- Ensure PR branch is up to date
- Check for merge conflicts
- Verify patch format is valid unified diff
- Review git apply errors in logs

#### 3. Authentication Errors (GitHub App)

**Symptoms**: "Authentication failed" or "Invalid credentials"

**Solutions**:
- Verify `APP_ID` matches your GitHub App
- Check private key file exists and is readable
- Ensure app is installed on the repository
- Verify app has required permissions

#### 4. Webhook Not Received (GitHub App)

**Symptoms**: App doesn't respond to comments

**Solutions**:
- Check webhook deliveries in GitHub App settings
- Verify webhook URL is accessible
- For development: Ensure smee proxy is running
- Check webhook secret matches `.env`

### Debug Mode

**GitHub Actions**:
Enable debug logging:
```bash
# In repository settings → Secrets and variables → Actions
# Add secret: ACTIONS_RUNNER_DEBUG = true
```

**GitHub App**:
```bash
# In .env
LOG_LEVEL=debug
```

### Getting Help

1. **Check Logs**: Always start with workflow/app logs
2. **GitHub Actions**: View run details in Actions tab
3. **GitHub App**: Check deployment logs (Heroku logs, Vercel logs, etc.)
4. **Webhook Deliveries**: Review in GitHub App settings
5. **Open Issue**: If problem persists, open an issue with:
   - Error messages
   - Workflow/app logs
   - Steps to reproduce

## Best Practices

### Security

- ✅ Never commit private keys or secrets
- ✅ Use environment variables for sensitive data
- ✅ Rotate GitHub App private key periodically
- ✅ Use webhook secrets to verify payloads
- ✅ Review GitHub App permissions regularly

### Performance

- ✅ Clean up temporary directories after use
- ✅ Use shallow clones when possible
- ✅ Implement timeout handling
- ✅ Monitor resource usage

### Reliability

- ✅ Handle all error cases gracefully
- ✅ Provide clear error messages
- ✅ Implement retry logic for transient failures
- ✅ Log all significant events

## Additional Resources

- [FlyCI Wingman Documentation](https://fly-ci.com/wingman/docs)
- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Probot Documentation](https://probot.github.io)
- [GitHub Apps Documentation](https://docs.github.com/apps)
- [Git Apply Manual](https://git-scm.com/docs/git-apply)

## Contributing

To improve the Wingman integration:

1. Fork the repository
2. Make changes to workflows or GitHub App
3. Test thoroughly
4. Submit a pull request with detailed description

## License

See repository LICENSE file for details.

---

**Questions?** Open an issue or contact the repository maintainers.
