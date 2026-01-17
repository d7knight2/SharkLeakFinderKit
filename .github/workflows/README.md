# GitHub Actions Workflows

This directory contains GitHub Actions workflows for automating various tasks in the SharkLeakFinderKit repository.

## Workflows

### 1. Upload APK to Appetize.io (`upload-apk-appetize.yml`)

This workflow automatically builds the Android project, generates an APK, and uploads it to Appetize.io for testing and demonstration purposes.

#### Trigger Conditions

- **Automatic**: Runs on every push to the `main` branch
- **Manual**: Can be triggered manually using the "Run workflow" button in the GitHub Actions tab

#### Prerequisites

Before using this workflow, you need to configure the following:

1. **Appetize.io API Token**: 
   - Sign up for an account at [Appetize.io](https://appetize.io/)
   - Generate an API token from your account settings
   - Add the token as a GitHub secret named `APPETIZE_TOKEN`:
     - Go to your repository Settings → Secrets and variables → Actions
     - Click "New repository secret"
     - Name: `APPETIZE_TOKEN`
     - Value: Your Appetize.io API token
     - Click "Add secret"

2. **Android Project Configuration**: 
   - The workflow builds the Android project automatically
   - No pre-built APK files are required
   - The project must have a valid Gradle configuration (build.gradle.kts)
   - Build variant: Debug APK (unsigned, suitable for Appetize.io testing)

#### Workflow Steps

1. **Checkout repository**: Fetches the repository code
2. **Set up JDK 17**: Configures Java environment for Android builds
3. **Setup Gradle**: Configures Gradle with caching for faster builds
4. **Grant execute permission for gradlew**: Prepares Gradle wrapper (if present)
5. **Build Android APK**: Runs `gradle assembleDebug` to generate the debug APK
6. **Search for AnrWatchdog APK**: Searches for APK files in build output directory (app/build/outputs/apk/)
   - Priority order:
     1. Standard debug APK: `app/build/outputs/apk/debug/app-debug.apk`
     2. Standard release APK: `app/build/outputs/apk/release/app-release.apk`
     3. APKs with "anrwatchdog" in the filename
     4. Any APK file found in build outputs
7. **Validate Appetize.io Token**: Ensures the API token is configured
8. **Upload APK to Appetize.io**: Uploads the found APK using the Appetize.io API
9. **Log No APK Found**: If no APK is found after build, logs diagnostics and fails
10. **Upload Summary**: Generates a summary of the workflow execution

#### Success Scenario

When an APK is found and uploaded successfully:
- ✅ The workflow completes successfully
- 📱 The APK is available on Appetize.io
- 🔑 The app URL and key are logged in the workflow output

#### Failure Scenarios

The workflow handles the following failure scenarios gracefully:

1. **Build Failure**:
   - Gradle build fails with error output
   - Full stack trace is logged
   - Workflow fails with exit code from Gradle

2. **No APK Found After Build**:
   - Warning is logged
   - Build output directory contents are listed for diagnostics
   - Possible causes and expected APK locations are provided
   - Workflow fails with exit code 1

3. **Missing API Token**:
   - Error message is displayed
   - Instructions for adding the secret are provided
   - Workflow fails with exit code 1

4. **Upload Failure**:
   - HTTP status code and response are logged
   - Workflow fails with exit code 1

#### Logging

All key actions are logged for visibility:
- APK search results
- Selected APK details (name, path, size)
- API token validation status
- Upload progress and results
- Error messages with detailed context

#### Testing

To test the workflow:

1. **Manual Trigger**:
   - Go to Actions tab in GitHub
   - Select "Upload APK to Appetize.io" workflow
   - Click "Run workflow"
   - Select the branch
   - Click "Run workflow"

2. **Push to Main**:
   - Push any commit to the `main` branch
   - The workflow will automatically trigger

3. **Simulate Success**:
   - Ensure `APPETIZE_TOKEN` is configured
   - Trigger the workflow (it will automatically build the APK)
   - Check the Actions tab for successful execution

4. **Simulate Failure**:
   - Remove the `APPETIZE_TOKEN` secret temporarily
   - Trigger the workflow to see graceful failure handling

#### Maintenance

- The workflow uses `actions/checkout@v4`, `actions/setup-java@v4`, and `gradle/actions/setup-gradle@v4`
- Build configuration: Java 17 with Temurin distribution
- Gradle caching is enabled for faster builds
- Debug APK is built using `assembleDebug` task (no signing required)
- Appetize.io API endpoint: `https://api.appetize.io/v1/apps`
- API documentation: [Appetize.io API Docs](https://docs.appetize.io/api/)

#### Build Output Paths

The workflow searches for APK files in the following locations:
- Debug APK: `app/build/outputs/apk/debug/app-debug.apk`
- Release APK: `app/build/outputs/apk/release/app-release.apk`
- Any APK in: `app/build/outputs/apk/**/*.apk`

These paths follow standard Android Gradle plugin conventions.

#### Troubleshooting

**Issue**: "APPETIZE_TOKEN secret is not configured"
- **Solution**: Add the secret as described in the Prerequisites section

**Issue**: "Build failed"
- **Solution**: Check:
  - Gradle configuration in build.gradle.kts is valid
  - All dependencies are accessible
  - Java version compatibility (workflow uses JDK 17)
  - Review full build logs in the workflow output

**Issue**: "No APK files found after build"
- **Solution**: Check:
  - Build completed successfully without errors
  - APK output path matches standard Android conventions
  - Review build output directory contents in workflow logs
  - Verify app module exists and is configured correctly

**Issue**: "Failed to upload APK to Appetize.io"
- **Solution**: Check:
  - API token is valid and not expired
  - APK file is not corrupted
  - APK file size is within Appetize.io limits
  - Network connectivity to Appetize.io API

### 1a. Alternative Upload APK to Appetize.io (`appetize-upload.yml`)

This is a simplified version of the main upload workflow with similar functionality. It follows the same build and upload process but with a more streamlined approach.

#### Key Differences from `upload-apk-appetize.yml`:
- Simplified APK detection logic
- Fails immediately if no APK is found (no conditional handling)
- Suitable for CI/CD pipelines where strict failure is preferred

Both workflows implement the same core functionality:
- Build Android project with Gradle
- Search for generated APK in build outputs
- Upload to Appetize.io
- Provide detailed logging and error handling

## Contributing

When adding new workflows:
1. Follow the existing naming conventions
2. Include comprehensive logging
3. Handle failure scenarios gracefully
4. Document the workflow in this README
5. Test both success and failure paths
