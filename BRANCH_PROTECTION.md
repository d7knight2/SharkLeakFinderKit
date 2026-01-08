# Branch Protection and Testing Requirements

This document outlines the testing requirements and branch protection setup for the SharkLeakFinderKit repository to ensure high code quality and prevent regressions.

## Testing Requirements

All pull requests must pass the following tests before they can be merged:

### 1. Unit Tests
- **Framework:** JUnit 4
- **Command:** `gradle test` or `./gradlew test`
- **Location:** `app/src/test/`
- **Purpose:** Tests individual components and utility functions in isolation

### 2. UI Tests (Instrumented Tests)
- **Framework:** Espresso with LeakCanary integration
- **Command:** `gradle connectedAndroidTest` or `./gradlew connectedAndroidTest`
- **Location:** `app/src/androidTest/`
- **Purpose:** Tests UI interactions, memory leak detection, and activity lifecycle behavior

## Automated Testing via GitHub Actions

The repository includes a GitHub Actions workflow (`.github/workflows/pr-tests.yml`) that automatically runs both test suites on every pull request.

### Workflow Triggers
- Pull requests opened against `main` or `develop` branches
- Pull request updates (synchronize, reopened)
- Manual workflow dispatch for testing

### What the Workflow Does
1. **Unit Tests Job:**
   - Sets up Java 17 and Gradle
   - Runs all unit tests
   - Uploads test reports as artifacts
   - Publishes results to the PR summary

2. **UI Tests Job:**
   - Sets up Android emulator (API 30)
   - Runs all instrumented tests
   - Uploads test reports and screenshots
   - Publishes results to the PR summary

3. **Test Summary Job:**
   - Aggregates results from both test jobs
   - Fails the workflow if any tests fail
   - Provides a clear pass/fail summary

## Setting Up Branch Protection Rules

To enforce mandatory testing before merge, follow these steps:

### Step 1: Access Branch Protection Settings

1. Go to your repository on GitHub
2. Click on **Settings** (requires admin access)
3. Navigate to **Branches** in the left sidebar
4. Click **Add branch protection rule** or edit existing rule for `main`

### Step 2: Configure Protection Rule

Set up the following configurations:

#### Branch Name Pattern
```
main
```
(Create separate rules for `develop` or other branches if needed)

#### Required Status Checks

✅ **Require status checks to pass before merging**
   - Check this box to enable mandatory testing

✅ **Require branches to be up to date before merging**
   - Ensures the PR has the latest changes from main

**Select the following required checks:**
- `Unit Tests` (from pr-tests.yml workflow)
- `UI Tests` (from pr-tests.yml workflow)

#### Additional Recommended Settings

✅ **Require a pull request before merging**
   - Prevents direct pushes to main
   - Recommended: Require at least 1 approval

✅ **Require conversation resolution before merging**
   - Ensures all review comments are addressed

✅ **Do not allow bypassing the above settings**
   - Applies rules to administrators as well

❌ **Allow force pushes** (should be disabled)

❌ **Allow deletions** (should be disabled)

### Step 3: Save and Verify

1. Click **Create** or **Save changes**
2. Test by creating a test PR
3. Verify that tests run automatically
4. Confirm merge is blocked if tests fail

## Branch Protection Configuration Screenshot Guide

Your configuration should look similar to this:

```
Branch protection rule for: main

✅ Require a pull request before merging
   ✅ Require approvals: 1
   ✅ Dismiss stale pull request approvals when new commits are pushed

✅ Require status checks to pass before merging
   ✅ Require branches to be up to date before merging
   Required checks:
   - Unit Tests
   - UI Tests

✅ Require conversation resolution before merging

✅ Do not allow bypassing the above settings

❌ Allow force pushes
❌ Allow deletions
```

## Running Tests Locally

Before pushing changes, run tests locally to catch issues early:

### Run Unit Tests
```bash
# Using Gradle wrapper (if available)
./gradlew test

# Or using system Gradle
gradle test

# View results
open app/build/reports/tests/test/index.html
```

### Run UI Tests
```bash
# Connect an Android device or start an emulator first
adb devices

# Run UI tests
./gradlew connectedAndroidTest

# Or using system Gradle
gradle connectedAndroidTest

# View results
open app/build/reports/androidTests/connected/index.html
```

### Run Specific Tests
```bash
# Run a specific test class
gradle test --tests "LeakReporterTest"

# Run a specific test method
gradle test --tests "LeakReporterTest.testLogLeak_CreatesReport"

# Run UI test with specific class
gradle connectedAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.example.sharkleakfinderkit.MemoryLeakDetectionTest
```

## Test Organization

### Unit Tests (`app/src/test/`)
- **LeakReporterTest.kt** - Tests for leak reporting utility functions

### UI Tests (`app/src/androidTest/`)
- **MemoryLeakDetectionTest.kt** - Automated leak detection with LeakCanary
- **MemoryMonitoringTest.kt** - Memory usage monitoring during UI interactions
- **TestUtils.kt** - Shared test utilities

## Continuous Integration Benefits

With mandatory testing enabled, the repository gains:

1. **Quality Assurance** - No untested code reaches main
2. **Regression Prevention** - Existing functionality is protected
3. **Memory Leak Detection** - Automatic leak detection on every PR
4. **Fast Feedback** - Developers know immediately if changes break tests
5. **Documentation** - Test results serve as living documentation
6. **Confidence** - Team can merge with confidence

## Troubleshooting

### Tests Pass Locally but Fail in CI

**Possible causes:**
- Timing issues (CI may be slower)
- Environment differences
- Missing dependencies in CI config

**Solutions:**
- Add appropriate waits/timeouts
- Check CI logs for specific failures
- Ensure all dependencies are in build.gradle.kts

### UI Tests Fail to Start Emulator

**Possible causes:**
- Emulator startup timeout
- Resource constraints

**Solutions:**
- The workflow includes emulator caching
- AVD snapshot is created on first run
- Timeout is set to 60 minutes for UI tests

### "Required status checks" not appearing

**Possible causes:**
- Workflow hasn't run yet
- Workflow name mismatch

**Solutions:**
- Run the workflow at least once
- The exact job names are: "Unit Tests" and "UI Tests"
- After first run, they'll appear in the dropdown

## Support and Documentation

For more information, see:
- **TESTING.md** - Comprehensive testing guide
- **README.md** - Project overview and setup
- **CONFIGURATION.md** - LeakCanary configuration details
- **.github/workflows/pr-tests.yml** - Workflow configuration

## Questions or Issues?

If you encounter issues with the testing requirements or branch protection:
1. Check the GitHub Actions workflow logs
2. Review test failure messages
3. Consult the testing documentation
4. Open an issue for help
