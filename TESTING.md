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
