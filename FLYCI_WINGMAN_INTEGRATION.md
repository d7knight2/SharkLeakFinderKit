# FlyCI Wingman Integration Guide

This repository includes comprehensive FlyCI Wingman integration for automated CI failure analysis and fix suggestions.

## Overview

FlyCI Wingman is integrated into the repository in three ways:

1. **Workflow Integration** - Added to all CI workflows to provide suggestions on failures
2. **GitHub Actions Auto-Apply** - Workflow that automatically applies Wingman suggestions
3. **GitHub App Auto-Apply** - Probot-based app for automated patch application

## 1. Workflow Integration

### What's Integrated

FlyCI Wingman has been added as a final step to the following workflows:

- `.github/workflows/pr-tests.yml` (unit-tests and ui-tests jobs)
- `.github/workflows/appetize-upload.yml`
- `.github/workflows/upload-apk-appetize.yml`
- `.github/workflows/auto-resolve-merge-conflicts.yml`

### How It Works

Each workflow includes a final step that runs only on job failure:

```yaml
- name: FlyCI Wingman
  if: failure()
  uses: fly-ci/wingman-action@v1
```

When a job fails, FlyCI Wingman will:
- Analyze the failure logs
- Identify the root cause
- Generate suggested fixes as unified diff patches
- Post a comment on the PR with the suggestions

## 2. GitHub Actions Auto-Apply Workflow

### Location

`.github/workflows/flyci-auto-apply.yml`

### How It Works

This workflow automatically applies FlyCI Wingman suggestions:

1. **Trigger**: Activated when a comment is created on a PR
2. **Detection**: Checks if the comment is from FlyCI Wingman
3. **Extraction**: Parses the comment to extract diff patches
4. **Application**: Applies patches to the PR branch using `git apply`
5. **Commit**: Commits and pushes changes back to the PR
6. **Re-run**: Triggers a workflow re-run to verify the fixes

### Setup

No additional setup required - the workflow is ready to use once merged.

### Features

- ✅ Automatic patch detection and extraction
- ✅ Support for multiple patches in a single comment
- ✅ Detailed logging and error handling
- ✅ Automatic workflow re-triggering
- ✅ Status comments on the PR
- ✅ No external dependencies required

### Permissions Required

The workflow requires the following permissions (already configured):

```yaml
permissions:
  contents: write
  pull-requests: write
  actions: write
```

## 3. GitHub App with Probot

### Location

`probot-flyci-app/` directory

### Components

- `app.js` - Main application logic
- `manifest.json` - GitHub App configuration
- `package.json` - Node.js dependencies
- `README.md` - Detailed setup instructions
- `.env.example` - Environment variable template
- `Dockerfile` - Container deployment configuration

### How It Works

The GitHub App provides similar functionality to the Actions workflow but with additional benefits:

1. **Webhook-based**: Responds immediately to PR comments
2. **Stateful**: Can maintain state across multiple operations
3. **More Control**: Full programmatic control over git operations
4. **Authentication**: Uses GitHub App authentication with private key
5. **Scalable**: Can be deployed as a service for multiple repositories

### Setup Overview

1. **Create GitHub App**: Register a new GitHub App in your organization/account
2. **Install Dependencies**: Run `npm install` in the `probot-flyci-app` directory
3. **Configure**: Set up `.env` file with App ID, webhook secret, and private key
4. **Deploy**: Run locally or deploy to a server (Heroku, Vercel, Docker, etc.)
5. **Install**: Install the app on your repositories

### Detailed Setup

See `probot-flyci-app/README.md` for comprehensive setup instructions including:
- Creating and configuring a GitHub App
- Local development with webhook proxy
- Production deployment options
- Troubleshooting guide

## Choosing Between Solutions

### Use GitHub Actions Workflow When:

- ✅ You want a simple, zero-configuration solution
- ✅ You're already using GitHub Actions
- ✅ You don't need immediate response to comments
- ✅ You want everything in one repository
- ✅ You don't want to manage additional infrastructure

### Use GitHub App When:

- ✅ You need immediate webhook-based responses
- ✅ You want more programmatic control
- ✅ You're managing multiple repositories
- ✅ You need advanced features and customization
- ✅ You have infrastructure to run a service

### Use Both When:

- ✅ You want maximum reliability (redundancy)
- ✅ You want to compare performance
- ✅ You have different use cases for each

## Patch Format

Both solutions expect FlyCI Wingman to provide suggestions in unified diff format:

````markdown
```diff
diff --git a/path/to/file.java b/path/to/file.java
index 1234567..abcdefg 100644
--- a/path/to/file.java
+++ b/path/to/file.java
@@ -10,7 +10,7 @@ public class Example {
     public void method() {
-        String oldCode = "old";
+        String newCode = "new";
     }
 }
```
````

## Testing the Integration

### 1. Test Workflow Integration

1. Create a branch with intentional CI failures
2. Open a pull request
3. Wait for the workflow to fail
4. Verify FlyCI Wingman comment appears on the PR

### 2. Test Auto-Apply (Actions)

1. Ensure a PR has a FlyCI Wingman comment with patches
2. The workflow should automatically trigger
3. Check the Actions tab for the "FlyCI Wingman Auto-Apply Fixes" workflow
4. Verify changes are committed to the PR branch
5. Confirm the workflow re-runs

### 3. Test Auto-Apply (GitHub App)

1. Ensure the app is running and configured
2. Create a test comment with a diff patch
3. The app should immediately process it
4. Check app logs for processing details
5. Verify changes are applied to the PR

## Monitoring and Debugging

### GitHub Actions Workflow

View logs in:
- GitHub Actions tab → "FlyCI Wingman Auto-Apply Fixes" workflow
- Individual workflow run details

### GitHub App

View logs by:
- Checking the app's server logs
- Setting `LOG_LEVEL=debug` in `.env`
- Reviewing webhook delivery status in GitHub App settings

## Security Considerations

### GitHub Actions

- Uses `GITHUB_TOKEN` which is automatically provided
- Limited to repository scope
- No additional secrets required

### GitHub App

- Requires private key management
- Use webhook secret for validation
- Store credentials securely in environment variables
- Never commit private keys or secrets to the repository

## Maintenance

### Updating FlyCI Wingman Version

To update the Wingman action version in workflows:

```bash
# Update all workflows
sed -i 's/fly-ci\/wingman-action@v1/fly-ci\/wingman-action@v2/g' .github/workflows/*.yml
```

### Updating Dependencies (GitHub App)

```bash
cd probot-flyci-app
npm update
npm audit fix
```

## Troubleshooting

### Common Issues

#### Patches Not Applying

**Problem**: Patches fail to apply to the branch

**Solutions**:
1. Ensure the PR branch is up to date with base branch
2. Check for merge conflicts
3. Verify the patch format is correct (unified diff)
4. Review the file paths in the diff

#### Workflow Not Triggering

**Problem**: Auto-apply workflow doesn't run

**Solutions**:
1. Check workflow permissions in repository settings
2. Verify the comment contains FlyCI Wingman markers
3. Review workflow logs for errors
4. Ensure workflows are enabled for the repository

#### GitHub App Not Responding

**Problem**: App doesn't process comments

**Solutions**:
1. Verify the app is running and accessible
2. Check webhook delivery status in GitHub App settings
3. Review app logs for errors
4. Ensure the app is installed on the repository
5. Verify authentication credentials (App ID, private key)

#### Permission Errors

**Problem**: "Resource not accessible" or similar errors

**Solutions**:
1. Verify the app/workflow has necessary permissions
2. Check repository settings for workflow permissions
3. For GitHub App, verify installation scope includes the repository
4. Review branch protection rules

## Best Practices

1. **Monitor First**: Watch how Wingman suggestions work before enabling auto-apply
2. **Review Changes**: Even with auto-apply, review the changes before merging
3. **Test Thoroughly**: Test the integration in a development environment first
4. **Keep Updated**: Regularly update FlyCI Wingman and dependencies
5. **Secure Credentials**: Never commit secrets or private keys
6. **Log Analysis**: Regularly review logs to catch issues early
7. **Backup Strategy**: Consider keeping both solutions for redundancy

## Support and Resources

- **FlyCI Wingman Documentation**: https://github.com/fly-ci/wingman-action
- **GitHub Actions Documentation**: https://docs.github.com/en/actions
- **Probot Documentation**: https://probot.github.io/docs/
- **GitHub Apps Documentation**: https://docs.github.com/en/developers/apps

## Contributing

If you find issues or have suggestions for improving the FlyCI Wingman integration:

1. Open an issue describing the problem or enhancement
2. Submit a pull request with your proposed changes
3. Update documentation as needed
4. Add tests if applicable

## License

This integration follows the same license as the repository.
