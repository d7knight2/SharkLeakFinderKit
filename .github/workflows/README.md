# GitHub Actions Workflows

This directory contains GitHub Actions workflows for automating various tasks in the SharkLeakFinderKit repository.

## Core Workflows

### 1. Build and Test (`build-and-test.yml`)

**Primary CI/CD workflow for building APKs and running comprehensive tests.**

#### Trigger Conditions

- **Push**: Runs on push to `main`, `develop`, or `feature/**` branches
- **Pull Request**: Runs on PRs to `main` or `develop` branches
- **Manual**: Can be triggered manually using workflow_dispatch

#### Jobs

##### 1. **build** - Build Debug APK
- Sets up Java 17 (Temurin distribution)
- Configures Gradle caching for faster builds
- Runs `./gradlew assembleDebug`
- Uploads debug APK artifact (30-day retention)
- Verifies APK creation and reports size

##### 2. **unit-tests** - Unit Tests
- Runs after successful build
- Executes `./gradlew test`
- Uploads test results and HTML reports (7-day retention)
- Independent execution for parallel processing

##### 3. **ui-tests** - Instrumented UI Tests
- Runs after successful build (parallel with unit tests)
- Sets up Android Emulator (API 30, x86_64, Google APIs)
- Caches AVD for faster subsequent runs
- Executes `./gradlew connectedAndroidTest`
- Uploads test results and reports (7-day retention)

##### 4. **build-release** - Build Release APK
- Runs only after both unit and UI tests pass
- Only triggered on push to `main` or `develop` branches
- Builds unsigned release APK
- Uploads release APK artifact (90-day retention)

##### 5. **test-summary** - Aggregate Test Results
- Runs after all tests complete (success or failure)
- Reports overall test status
- Fails if any test job failed
- Provides summary in GitHub Actions UI

#### Environment Variables

- `JAVA_VERSION`: '17'
- `JAVA_DISTRIBUTION`: 'temurin'

#### Artifacts

| Artifact Name | Contents | Retention |
|---------------|----------|-----------|
| `app-debug` | Debug APK | 30 days |
| `app-release` | Release APK (unsigned) | 90 days |
| `unit-test-results` | Unit test reports | 7 days |
| `ui-test-results` | UI test reports | 7 days |

#### Timeouts

- build: 30 minutes
- unit-tests: 30 minutes
- ui-tests: 60 minutes
- build-release: 30 minutes

#### Features

✅ **Parallel Execution**: Unit and UI tests run simultaneously for faster feedback  
✅ **Smart Caching**: Gradle dependencies and AVD cached automatically  
✅ **Release Gating**: Release builds only after all tests pass  
✅ **Comprehensive Reporting**: Detailed summaries in GitHub Actions UI  
✅ **Artifact Management**: Strategic retention policies for different artifacts

### 2. Pull Request Tests (`pr-tests.yml`)

**Dedicated workflow for validating pull request changes.**

#### Trigger Conditions

- **Pull Request**: Runs on PRs opened, synchronized, or reopened
- **Target Branches**: `main`, `develop`
- **Manual**: Can be triggered manually using workflow_dispatch

#### Jobs

Similar to `build-and-test.yml` but focused on PR validation:
- **unit-tests**: Validates unit test changes
- **ui-tests**: Validates UI test changes
- **test-summary**: Aggregates results and blocks merging if tests fail

### 3. Upload APK to Appetize.io (`upload-apk-appetize.yml`)

This workflow automatically uploads Android APK files to Appetize.io for cloud-based testing.

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

2. **APK Files**: 
   - The workflow searches for APK files in the repository
   - Priority order:
     1. APKs with "anrwatchdog", "anr-watchdog", or "anr_watchdog" in the filename
     2. APKs with "demo" in the filename
     3. Any APK file found

#### Workflow Steps

1. **Checkout repository**: Fetches the repository code
2. **Search for AnrWatchdog APK**: Searches for APK files with intelligent prioritization
3. **Validate Appetize.io Token**: Ensures the API token is configured
4. **Upload APK to Appetize.io**: Uploads the found APK using the Appetize.io API
5. **Log No APK Found**: If no APK is found, logs details and fails gracefully
6. **Upload Summary**: Generates a summary of the workflow execution

#### Success Scenario

When an APK is found and uploaded successfully:
- ✅ The workflow completes successfully
- 📱 The APK is available on Appetize.io
- 🔑 The app URL and key are logged in the workflow output

#### Failure Scenarios

The workflow handles the following failure scenarios gracefully:

1. **No APK Found**:
   - Warning is logged
   - Detailed search information is provided
   - Suggestions for resolution are included
   - Workflow fails with exit code 1

2. **Missing API Token**:
   - Error message is displayed
   - Instructions for adding the secret are provided
   - Workflow fails with exit code 1

3. **Upload Failure**:
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
   - Add an APK file to the repository (e.g., `demo/anrwatchdog-demo.apk`)
   - Ensure `APPETIZE_TOKEN` is configured
   - Trigger the workflow

4. **Simulate Failure**:
   - Remove all APK files from the repository
   - Trigger the workflow to see graceful failure handling

#### Maintenance

- The workflow uses `actions/checkout@v4` which is kept up to date
- Appetize.io API endpoint: `https://api.appetize.io/v1/apps`
- API documentation: [Appetize.io API Docs](https://docs.appetize.io/api/)

#### Troubleshooting

**Issue**: "APPETIZE_TOKEN secret is not configured"
- **Solution**: Add the secret as described in the Prerequisites section

**Issue**: "No APK files found in the repository"
- **Solution**: Ensure APK files are:
  - Built and committed to the repository, OR
  - Generated by a build step before this workflow, OR
  - Stored as release artifacts

**Issue**: "Failed to upload APK to Appetize.io"
- **Solution**: Check:
  - API token is valid and not expired
  - APK file is not corrupted
  - APK file size is within Appetize.io limits
  - Network connectivity to Appetize.io API

### 2. Auto Resolve Merge Conflicts (`auto-resolve-merge-conflicts.yml`)

Automatically attempts to resolve merge conflicts in open pull requests.

#### Trigger Conditions

- **Automatic**: Runs every hour via cron schedule
- **Manual**: Can be triggered manually using workflow_dispatch

For more details, see the workflow file.

## Contributing

When adding new workflows:
1. Follow the existing naming conventions
2. Include comprehensive logging
3. Handle failure scenarios gracefully
4. Document the workflow in this README
5. Test both success and failure paths
