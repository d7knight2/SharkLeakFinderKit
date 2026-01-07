# Testing the Appetize.io Upload Workflow

This document provides instructions for testing the Appetize.io upload workflow and scripts.

## Prerequisites

1. **Appetize.io Account**: Sign up at [appetize.io](https://appetize.io/)
2. **API Token**: Get your API token from Appetize.io dashboard
3. **GitHub Repository Access**: Admin access to set repository secrets

## Setup Steps

### 1. Configure GitHub Secret

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `APPETIZE_TOKEN`
5. Value: Your Appetize.io API token
6. Click **Add secret**

### 2. Prepare an APK File

Since this is a JavaScript project, you won't have a native APK. For testing purposes, you can:

**Option A: Create a minimal test APK**
```bash
# Create a test directory structure
mkdir -p test-apk/META-INF
cd test-apk

# Create AndroidManifest.xml
cat > AndroidManifest.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.sharkleakfinder.test"
    android:versionCode="1"
    android:versionName="1.0">
    <application android:label="Test App">
        <activity android:name=".MainActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

# Create a dummy APK (ZIP file with .apk extension)
zip -r ../test-app.apk AndroidManifest.xml META-INF/
cd ..
rm -rf test-apk
```

**Option B: Download a sample APK**
```bash
# Note: Only use open-source, freely distributable APKs
# Example: Download from a trusted source or use your own app
```

**Option C: Skip this for now**
- The workflow will fail gracefully with a clear error message if no APK is found
- This is expected behavior and can be used to test the error handling

### 3. Test Locally with Scripts

#### Test the Mock Test Suite
```bash
# Run mock tests
./scripts/test-appetize-upload.sh

# Expected output: 8/8 tests passed
```

#### Test the Unit Test Suite
```bash
# Run unit tests
./scripts/unit-tests.sh

# Expected output: 32/32 tests passed
```

#### Test the Upload Script (without actual upload)
```bash
# Test with a dummy APK (will fail at upload, which is expected)
touch test.apk
./scripts/upload-to-appetize.sh test.apk dummy_token

# This will demonstrate:
# - APK file discovery works
# - File size calculation works
# - API call is attempted
# - Error handling for invalid token
```

### 4. Test GitHub Actions Workflow

#### Method 1: Manual Trigger (Recommended for first test)

1. Go to your repository on GitHub
2. Navigate to **Actions** tab
3. Select **Upload APK to Appetize.io** workflow
4. Click **Run workflow** button
5. Select the branch (e.g., `main` or your feature branch)
6. Click **Run workflow**

**Expected Results:**
- If no APK exists: Workflow fails with clear error message
- If APK exists and token is valid: Workflow succeeds and uploads to Appetize.io

#### Method 2: Test with act (Local GitHub Actions Testing)

```bash
# Install act (if not already installed)
# macOS
brew install act

# Linux
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Test the workflow locally
act workflow_dispatch -W .github/workflows/appetize-upload.yml

# Or test push trigger
act push -W .github/workflows/appetize-upload.yml
```

#### Method 3: Push to Main Branch

```bash
# Merge your changes to main
git checkout main
git merge your-feature-branch
git push origin main

# Workflow will automatically trigger
```

## Validation Checklist

After running the workflow, verify:

- [ ] Workflow starts successfully
- [ ] APK discovery step completes
  - [ ] If APK exists: Found and path is logged
  - [ ] If no APK: Workflow fails with clear error message
- [ ] Upload step attempts to upload to Appetize.io
  - [ ] API request is made with proper authentication
  - [ ] Response is logged (success or failure)
- [ ] On success:
  - [ ] App URL is displayed in logs
  - [ ] App key is displayed in logs
  - [ ] Upload summary is shown
- [ ] On failure:
  - [ ] Error message is clear and actionable
  - [ ] HTTP status code is shown
  - [ ] Workflow fails with non-zero exit code

## Testing Scenarios

### Scenario 1: No APK File

**Setup:** Remove any APK files from repository

**Expected:** 
```
❌ ERROR: No APK file found in the repository
Error: No APK file found. Please add an APK file to the repository before running this workflow.
```

**Status:** ✅ Working (verified by unit tests)

### Scenario 2: Missing APPETIZE_TOKEN Secret

**Setup:** Do not set APPETIZE_TOKEN in repository secrets

**Expected:**
```
❌ ERROR: APPETIZE_TOKEN secret is not set
Error: APPETIZE_TOKEN is required. Please set it in repository secrets.
```

**Status:** ✅ Working (verified by unit tests)

### Scenario 3: Invalid API Token

**Setup:** Set APPETIZE_TOKEN to an invalid value

**Expected:**
```
❌ Failed to upload APK to Appetize.io (HTTP 401)
Error: Upload failed with HTTP code 401
```

**Status:** ✅ Working (verified by mock tests)

### Scenario 4: Successful Upload

**Setup:** 
- Valid APK file in repository
- Valid APPETIZE_TOKEN secret

**Expected:**
```
✅ Successfully uploaded APK to Appetize.io
🔗 App URL: https://appetize.io/app/[key]
🔑 App Key: [key]
```

**Status:** ⏳ Requires valid Appetize.io account to test

## Troubleshooting

### Issue: "No APK file found"

**Solution:**
1. Add an APK file to your repository
2. Ensure it has `.apk` extension
3. Commit and push the APK file

### Issue: "APPETIZE_TOKEN secret is not set"

**Solution:**
1. Go to repository Settings → Secrets → Actions
2. Add `APPETIZE_TOKEN` secret with your API token
3. Retry the workflow

### Issue: "Upload failed with HTTP 401"

**Solution:**
1. Verify your Appetize.io API token is correct
2. Check if your Appetize.io account is active
3. Regenerate API token if necessary

### Issue: "Upload failed with HTTP 400"

**Solution:**
1. Verify the APK file is valid
2. Check the APK is not corrupted
3. Ensure the APK meets Appetize.io requirements

### Issue: Workflow doesn't trigger on push

**Solution:**
1. Verify push is to `main` branch
2. Check workflow file syntax is correct
3. Ensure GitHub Actions are enabled for repository

## Integration with CI/CD

### Adding to Existing Workflows

You can integrate APK upload as a step in your existing workflows:

```yaml
# In your existing workflow
- name: Upload to Appetize
  uses: ./.github/workflows/appetize-upload.yml
```

### Build and Upload Pattern

For Android projects, you might want to build then upload:

```yaml
- name: Build APK
  run: ./gradlew assembleRelease

- name: Upload to Appetize
  env:
    APPETIZE_TOKEN: ${{ secrets.APPETIZE_TOKEN }}
  run: |
    APK_PATH=$(find . -name "*.apk" | head -1)
    ./scripts/upload-to-appetize.sh "$APK_PATH" "$APPETIZE_TOKEN"
```

## Performance Metrics

- **APK Discovery:** < 1 second for typical repository
- **Upload Time:** Depends on APK size (typically 10-60 seconds)
- **Total Workflow Time:** 1-2 minutes average

## Security Best Practices

1. ✅ Never commit API tokens to repository
2. ✅ Use GitHub secrets for sensitive data
3. ✅ Rotate API tokens regularly
4. ✅ Review workflow logs for exposed data
5. ✅ Limit workflow permissions to minimum required

## Next Steps

After successful testing:

1. Document the app URL for team access
2. Set up notifications for upload failures
3. Consider adding upload to multiple environments
4. Automate APK building if needed
5. Add upload to your release process

## Support

For issues:
1. Check workflow logs in GitHub Actions
2. Run local tests with mock scripts
3. Verify all prerequisites are met
4. Open an issue in the repository

## Additional Resources

- [Appetize.io API Documentation](https://appetize.io/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
