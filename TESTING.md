# LeakCanary Testing Guide

## Overview

This document provides detailed guidance on testing for memory leaks using LeakCanary in the SharkLeakFinderKit project.

## Test Categories

### 1. Automated Leak Detection Tests

Located in `MemoryLeakDetectionTest.kt`, these tests use LeakCanary's `DetectLeaksAfterTestSuccess()` rule to automatically detect leaks.

#### Key Features:
- **Automatic Failure** - Tests fail when leaks are detected
- **Lifecycle Testing** - Validates proper cleanup in activity lifecycle
- **Instance Tracking** - Monitors multiple instances for retention issues

#### Example Test:
```kotlin
@Test
fun testLeakyActivityDetectsMemoryLeaks() {
    // Navigate to LeakyActivity
    onView(withId(R.id.leakyActivityButton)).perform(click())
    
    // Destroy the activity
    onView(withId(R.id.finishButton)).perform(click())
    
    // Wait for leak detection
    Thread.sleep(3000)
    
    // Test will fail if leaks are detected
}
```

### 2. Memory Monitoring Tests

Located in `MemoryMonitoringTest.kt`, these tests continuously monitor memory metrics during UI interactions.

#### Monitored Metrics:
- **PSS (Proportional Set Size)** - Total memory used
- **Dalvik Heap** - Java heap memory
- **Native Heap** - Native memory allocation
- **Thread Count** - Active threads
- **Heap Allocation** - Runtime memory allocation

#### Memory Snapshot:
```kotlin
data class MemorySnapshot(
    val timestamp: Long,
    val totalPss: Long,
    val dalvikPss: Long,
    val nativePss: Long,
    val heapAllocated: Long,
    val heapFree: Long,
    val threadCount: Int
)
```

## Running Tests

### Local Development

```bash
# Run all instrumentation tests
./gradlew connectedAndroidTest

# Run specific test class
./gradlew connectedAndroidTest -Pandroid.testInstrumentationRunnerArguments.class=com.example.sharkleakfinderkit.MemoryLeakDetectionTest

# Run with detailed logs
./gradlew connectedAndroidTest --info
```

### View Test Results

```bash
# Open HTML report
open app/build/reports/androidTests/connected/index.html

# Check logcat for leak details
adb logcat | grep -E "LeakCanary|LeakReporter|MemoryMonitor"
```

## Test Patterns

### Pattern 1: Basic Leak Detection

```kotlin
@Test
fun testActivityDoesNotLeak() {
    // Perform activity operations
    // ...
    
    // Close activity
    activityRule.scenario.close()
    
    // Wait for leak detection
    Thread.sleep(2000)
    
    // DetectLeaksAfterTestSuccess rule will verify no leaks
}
```

### Pattern 2: Memory Monitoring

```kotlin
@Test
fun testMemoryGrowth() {
    takeMemorySnapshot("baseline")
    
    // Perform operations
    repeat(10) {
        // ... UI interactions
        takeMemorySnapshot("iteration_$it")
    }
    
    // Analyze memory growth
    logMemoryReport()
}
```

### Pattern 3: Thread Leak Detection

```kotlin
@Test
fun testThreadCountStable() {
    val initialThreadCount = Thread.activeCount()
    
    // Perform operations
    // ...
    
    val finalThreadCount = Thread.activeCount()
    
    // Thread count should return to baseline
    assertEquals(initialThreadCount, finalThreadCount)
}
```

## Common Leak Scenarios

### 1. Handler Leaks

**Problem:**
```kotlin
private val handler = Handler(Looper.getMainLooper())

override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    handler.postDelayed({ /* work */ }, 60000)
}
```

**Solution:**
```kotlin
override fun onDestroy() {
    super.onDestroy()
    handler.removeCallbacksAndMessages(null)
}
```

### 2. Static Reference Leaks

**Problem:**
```kotlin
companion object {
    var staticActivity: Activity? = null
}

override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    staticActivity = this
}
```

**Solution:**
```kotlin
override fun onDestroy() {
    super.onDestroy()
    staticActivity = null
}
```

### 3. Thread Leaks

**Problem:**
```kotlin
private val thread = Thread {
    Thread.sleep(60000)
    runOnUiThread { /* update UI */ }
}

override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    thread.start()
}
```

**Solution:**
```kotlin
private var thread: Thread? = null

override fun onDestroy() {
    super.onDestroy()
    thread?.interrupt()
    thread = null
}
```

## Interpreting Test Results

### Success Case

```
✅ testMainActivityDoesNotLeak PASSED
✅ testNoLeaksAfterApplicationRestart PASSED
```

LeakCanary detected no leaks. All objects were properly garbage collected.

### Failure Case

```
❌ testLeakyActivityDetectsMemoryLeaks FAILED

LeakCanary detected 3 leaked objects:
1. LeakyActivity leaked via Handler callback
2. LeakyActivity leaked via static reference
3. Thread leaked holding activity reference
```

Test failed because LeakCanary detected memory leaks. Review the leak traces to fix the issues.

### Memory Report Example

```
=== Memory Report ===
Initial PSS: 45234KB
Final PSS: 67890KB
PSS Increase: 22656KB
Initial Threads: 15
Final Threads: 18
Thread Increase: 3
====================
```

This indicates significant memory growth during testing which may suggest memory leaks.

## Running Tests Locally

### Quick Start

```bash
# Run unit tests only
./scripts/run-tests.sh

# Run all tests (unit + UI)
./scripts/run-tests.sh --all

# Run with verbose output
./scripts/run-tests.sh --verbose
```

### Using Gradle Directly

```bash
# Run unit tests
./gradlew test

# Run UI tests (requires connected device/emulator)
./gradlew connectedAndroidTest

# Run all tests
./gradlew test connectedAndroidTest
```

### Build and Validate

Run complete validation pipeline (tests + build + APK validation):

```bash
# Debug build with all tests
./scripts/build-and-validate.sh

# Release build with unit tests only
./scripts/build-and-validate.sh --release --skip-ui-tests

# Skip tests and just build
./scripts/build-and-validate.sh --skip-tests
```

## Continuous Integration (CI/CD)

### GitHub Actions Workflows

The project includes comprehensive CI/CD workflows for automated testing and building:

#### 1. Build and Test Workflow (`build-and-test.yml`)

**Triggers:**
- Push to `main`, `develop`, or `feature/**` branches
- Pull requests to `main` or `develop`
- Manual dispatch

**Jobs:**

1. **build** - Builds debug APK
   - Sets up Java 17
   - Runs `./gradlew assembleDebug`
   - Uploads APK as artifact (30-day retention)
   - Provides build summary with APK size

2. **unit-tests** - Runs unit tests
   - Executes `./gradlew test`
   - Uploads test results and reports
   - Runs after successful build

3. **ui-tests** - Runs instrumented tests
   - Sets up Android emulator (API 30)
   - Caches AVD for faster subsequent runs
   - Executes `./gradlew connectedAndroidTest`
   - Uploads test results and reports
   - Runs after successful build

4. **build-release** - Builds release APK
   - Only runs on push to `main` or `develop`
   - Requires both unit and UI tests to pass
   - Uploads release APK (90-day retention)

5. **test-summary** - Aggregates test results
   - Reports overall pass/fail status
   - Fails if any tests failed
   - Provides summary in GitHub UI

**Artifacts:**
- `app-debug` - Debug APK (30 days)
- `app-release` - Release APK (90 days)
- `unit-test-results` - Unit test reports (7 days)
- `ui-test-results` - UI test reports (7 days)

#### 2. Pull Request Tests Workflow (`pr-tests.yml`)

**Triggers:**
- Pull requests opened, synchronized, or reopened
- Targets `main` or `develop` branches
- Manual dispatch

**Focus:** Runs comprehensive unit and UI tests to validate PR changes before merging.

### CI/CD Best Practices

1. **Parallel Execution**: Unit and UI tests run in parallel after build for faster feedback

2. **Artifact Management**: 
   - Debug APKs: 30-day retention for development
   - Release APKs: 90-day retention for production candidates
   - Test reports: 7-day retention for issue investigation

3. **Caching Strategy**:
   - Gradle dependencies cached automatically
   - Android AVD cached to reduce emulator startup time

4. **Release Gate**: Release APKs only built after all tests pass on main/develop branches

5. **Test Isolation**: Each test job runs independently to prevent interference

### Monitoring CI/CD

#### Viewing Test Results

1. Navigate to Actions tab in GitHub
2. Select workflow run
3. Click on test job (unit-tests or ui-tests)
4. Download artifacts to view detailed HTML reports

#### Common CI/CD Issues

**Issue: Tests timeout**
- Solution: Jobs have 30-60 minute timeouts; optimize test execution time

**Issue: Emulator fails to start**
- Solution: AVD cache may be corrupted; clear cache and rebuild

**Issue: Flaky UI tests**
- Solution: Add proper wait conditions and disable animations

**Issue: Build fails due to dependencies**
- Solution: Check Gradle cache; may need to refresh dependencies

### Status Badges

Add workflow status badges to README:

```markdown
[![Build and Test](https://github.com/d7knight2/SharkLeakFinderKit/workflows/Build%20and%20Test/badge.svg)](https://github.com/d7knight2/SharkLeakFinderKit/actions)
[![PR Tests](https://github.com/d7knight2/SharkLeakFinderKit/workflows/Pull%20Request%20Tests/badge.svg)](https://github.com/d7knight2/SharkLeakFinderKit/actions)
```

## Test Reports

### Unit Test Reports

Location: `app/build/reports/tests/test/index.html`

**Contains:**
- Test execution summary
- Pass/fail statistics
- Individual test results
- Execution time
- Stack traces for failures

### UI Test Reports

Location: `app/build/reports/androidTests/connected/index.html`

**Contains:**
- Device information
- Test execution timeline
- Screenshots (if captured)
- Logcat output
- Failure details

### Viewing Reports Locally

```bash
# Open unit test report
open app/build/reports/tests/test/index.html

# Open UI test report
open app/build/reports/androidTests/connected/index.html

# On Linux
xdg-open app/build/reports/tests/test/index.html
```

## Integration with Development Workflow

### Pre-commit Testing

Run tests before committing:

```bash
# Quick unit test check
./gradlew test

# Full validation
./scripts/build-and-validate.sh --skip-ui-tests
```

### Pull Request Workflow

1. Create feature branch
2. Write code and tests
3. Run tests locally: `./scripts/run-tests.sh --all`
4. Push branch - CI runs automatically
5. Review CI results in PR
6. Merge only if all tests pass

### Release Workflow

1. Merge to `develop` branch
2. CI runs full test suite
3. CI builds release APK
4. Download release APK from artifacts
5. Test APK on physical devices
6. Merge to `main` for production release

## Troubleshooting

### Tests Fail Locally but Pass in CI

- Check Android SDK versions
- Verify emulator/device API level matches CI
- Check for environment-specific issues

### Tests Pass Locally but Fail in CI

- May be timing issues in CI environment
- Add appropriate wait conditions
- Check for race conditions

### Memory Leak Tests Always Fail

- Ensure test device has sufficient memory
- Check for proper cleanup in `@After` methods
- Verify LeakCanary is configured correctly

### UI Tests Cannot Find Views

- Ensure activity is fully loaded before interaction
- Use IdlingResources for async operations
- Check if views are in correct visibility state
