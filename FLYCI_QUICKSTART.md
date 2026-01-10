# FlyCI Wingman Quick Start Guide

This is a quick reference for using the FlyCI Wingman integration in this repository.

## What is FlyCI Wingman?

FlyCI Wingman automatically analyzes CI failures and provides fix suggestions as unified diff patches.

## How to Use

### Automatic Detection (Already Configured)

When a CI job fails:
1. FlyCI Wingman automatically analyzes the failure
2. Posts a comment on your PR with suggested fixes
3. The auto-apply workflow can automatically apply these fixes

### Option 1: GitHub Actions Auto-Apply (Recommended for Most Users)

**Setup:** No additional setup needed - already configured!

**How it works:**
- Automatically triggers when FlyCI Wingman posts a comment
- Applies patches and commits to your PR branch
- Re-runs the failed workflow

**Status:** Ready to use immediately

### Option 2: GitHub App Auto-Apply (Advanced Users)

**Setup Required:** See `probot-flyci-app/README.md`

**Steps:**
1. Create a GitHub App
2. Install dependencies: `cd probot-flyci-app && npm install`
3. Configure `.env` file with credentials
4. Deploy the app (locally or to a server)

**Benefits:**
- Immediate webhook-based responses
- More programmatic control
- Can be used across multiple repositories

## Workflows with Wingman Enabled

All CI workflows now include FlyCI Wingman:
- ✅ Pull Request Tests (unit-tests and ui-tests)
- ✅ Appetize Upload
- ✅ APK Upload to Appetize
- ✅ Auto-Resolve Merge Conflicts

## Workflow Files

- **Auto-Apply**: `.github/workflows/flyci-auto-apply.yml`
- **PR Tests**: `.github/workflows/pr-tests.yml`
- **App Code**: `probot-flyci-app/app.js`

## Documentation

- **Complete Guide**: [FLYCI_WINGMAN_INTEGRATION.md](FLYCI_WINGMAN_INTEGRATION.md)
- **App Setup**: [probot-flyci-app/README.md](probot-flyci-app/README.md)

## Testing the Integration

1. Create a PR with a failing test
2. Wait for CI to fail
3. Check for FlyCI Wingman comment
4. Watch as auto-apply fixes the issue (if applicable)

## Troubleshooting

### Patches Not Applying?
- Ensure your branch is up to date
- Check for merge conflicts
- Review the auto-apply workflow logs

### Workflow Not Triggering?
- Verify workflow permissions are enabled
- Check that the comment contains "fly-ci/wingman" or "FlyCI Wingman"
- Review Actions tab for workflow runs

### Need Help?
- Check [FLYCI_WINGMAN_INTEGRATION.md](FLYCI_WINGMAN_INTEGRATION.md)
- Review workflow logs in the Actions tab
- Open an issue in the repository

## Key Features

✅ **Automatic Analysis** - Analyzes failures without manual intervention
✅ **Smart Detection** - Only processes FlyCI Wingman comments
✅ **Safe Application** - Tests patches before applying
✅ **Status Updates** - Posts comments with application results
✅ **Workflow Re-trigger** - Automatically re-runs failed workflows
✅ **Error Handling** - Gracefully handles failures
✅ **Security** - Uses GitHub's built-in authentication

## Example FlyCI Wingman Comment

```markdown
FlyCI Wingman Suggested Fix:

```diff
diff --git a/path/to/file.java b/path/to/file.java
--- a/path/to/file.java
+++ b/path/to/file.java
@@ -10,7 +10,7 @@
-    String bug = "old";
+    String fix = "new";
```
```

The auto-apply workflow will:
1. Extract this diff
2. Apply it to your branch
3. Commit and push the changes
4. Re-run the workflow

## Best Practices

1. **Review Changes**: Always review auto-applied changes before merging
2. **Keep Branch Updated**: Keep your PR branch up to date with the base branch
3. **Monitor Logs**: Check workflow logs if issues occur
4. **Report Issues**: Open an issue if you encounter problems

## Support

For detailed information, troubleshooting, and advanced configuration:
- Read [FLYCI_WINGMAN_INTEGRATION.md](FLYCI_WINGMAN_INTEGRATION.md)
- Check [probot-flyci-app/README.md](probot-flyci-app/README.md)
- Review GitHub Actions logs
- Open an issue for help
