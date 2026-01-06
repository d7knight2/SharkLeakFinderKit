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

Significant memory growth and thread increase indicate potential leaks.

## Best Practices

### 1. Test Organization

- Group related tests in the same file
- Use descriptive test names
- Add comments explaining what's being tested
- Keep tests focused on one scenario

### 2. Test Timing

- Allow sufficient time for leak detection (2-3 seconds)
- Force GC before assertions: `Runtime.getRuntime().gc()`
- Use `Thread.sleep()` strategically for async operations

### 3. Cleanup

- Always implement `@After` methods for cleanup
- Close activities properly in tests
- Clear static references after tests
- Interrupt background threads

### 4. Assertions

```kotlin
// Use LeakCanary assertions
LeakAssertions.assertNoLeaks()

// Monitor memory growth
assertTrue(memoryGrowth < ACCEPTABLE_THRESHOLD)

// Verify thread count
assertEquals(expectedThreads, actualThreads)
```

## Debugging Failed Tests

### Step 1: Review Logs

```bash
adb logcat | grep "LeakCanary"
```

Look for:
- Leak traces showing reference chains
- Retained object information
- Heap dump locations

### Step 2: Analyze Heap Dumps

1. Find heap dump: `/sdcard/Download/leakcanary-{app}/`
2. Pull to local: `adb pull /sdcard/Download/leakcanary-{app}/`
3. Open in Android Studio Memory Profiler
4. Search for leaked objects

### Step 3: Review Reference Chain

```
├─ LeakyActivity
│  ├─ Handler (mCallback)
│  │  └─ Message (callback)
│  │     └─ LeakyActivity (this$0) [LEAKING]
```

The leak trace shows Handler is holding a reference to the destroyed activity.

### Step 4: Fix and Retest

1. Implement proper cleanup in `onDestroy()`
2. Re-run tests: `./gradlew connectedAndroidTest`
3. Verify leak is fixed

## Continuous Monitoring

### CI Integration

Add to your CI pipeline:

```yaml
- name: Run Memory Leak Tests
  run: ./gradlew connectedAndroidTest
  
- name: Check for Leaks
  run: |
    if grep -r "LEAK" app/build/reports/androidTests/; then
      echo "Memory leaks detected!"
      exit 1
    fi
```

### Regular Testing Schedule

- Run leak tests on every PR
- Include in nightly builds
- Monitor memory trends over time
- Track leak count metrics

## Performance Considerations

### Test Duration

- Each test takes 5-15 seconds
- Heap dumps add 2-5 seconds overhead
- Consider parallel test execution

### Device Requirements

- Use real devices for accurate results
- Emulators may have different memory characteristics
- Test on multiple Android versions

### Resource Cleanup

```kotlin
@After
fun tearDown() {
    // Force GC
    Runtime.getRuntime().gc()
    Thread.sleep(1000)
    
    // Clear leak reports
    LeakReporter.clearReports()
}
```

## Advanced Topics

### Custom Leak Watchers

```kotlin
// Watch custom objects
AppWatcher.objectWatcher.watch(myObject, "My custom object")
```

### Conditional Leak Detection

```kotlin
// Skip leak detection in certain scenarios
if (BuildConfig.SKIP_LEAK_DETECTION) {
    return
}
```

### Leak Exclusions

```kotlin
// Exclude known library leaks
LeakCanary.config = LeakCanary.config.copy(
    referenceMatchers = AndroidReferenceMatchers.appDefaults +
        IgnoredReferenceMatcher(...)
)
```

## Troubleshooting

### Issue: Tests Pass But Leaks Exist

**Solution:**
- Increase wait time after operations
- Force GC explicitly
- Check DetectLeaksAfterTestSuccess rule is applied

### Issue: False Positives

**Solution:**
- Review leak trace carefully
- Check if objects have valid retention reasons
- Add exclusion rules for known safe cases

### Issue: Flaky Tests

**Solution:**
- Increase timeouts
- Add retry logic for network-dependent tests
- Use IdlingResource for async operations

## Resources

- [LeakCanary Documentation](https://square.github.io/leakcanary/)
- [Android Testing Guide](https://developer.android.com/training/testing)
- [Espresso Documentation](https://developer.android.com/training/testing/espresso)
- [Memory Profiler](https://developer.android.com/studio/profile/memory-profiler)

## Summary

Effective memory leak testing requires:
- ✅ Automated detection with LeakCanary
- ✅ Continuous memory monitoring
- ✅ Regular test execution
- ✅ Prompt leak fixing
- ✅ CI/CD integration

Follow these practices to maintain a leak-free Android application.
