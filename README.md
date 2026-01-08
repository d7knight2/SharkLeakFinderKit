# SharkLeakFinderKit

A comprehensive Android toolkit for detecting and monitoring memory leaks using LeakCanary, with integrated UI tests and memory monitoring utilities.

## Overview

SharkLeakFinderKit demonstrates best practices for integrating LeakCanary into Android applications and provides a complete testing framework for detecting memory leaks during development and automated testing.

## Features

- ✅ **Latest LeakCanary Integration** - Uses LeakCanary 2.14 (latest stable version)
- ✅ **Best Practice Configuration** - Properly configured for optimal leak detection
- ✅ **Comprehensive UI Tests** - Automated tests to catch memory leaks
- ✅ **Memory Monitoring** - Real-time memory usage tracking during UI events
- ✅ **Leak Reporting** - Detailed logging and reporting of detected leaks
- ✅ **Sample Scenarios** - Demonstrates common memory leak patterns
- ✅ **Instance Count Tracking** - Monitors object retention and instance proliferation
- ✅ **Thread Leak Detection** - Identifies background threads that leak activity references

## LeakCanary Integration

### Version Information

**Current Version:** LeakCanary 2.14 (April 2024 - Latest Stable)

The project uses the latest stable version of LeakCanary. For bleeding-edge features, v3.0-alpha-8 is available but may have stability issues.

### Configuration

LeakCanary is configured in `LeakFinderApplication.kt` with the following best practices:

```kotlin
LeakCanary.config = LeakCanary.config.copy(
    retainedVisibleThreshold = 5,  // Show notification after 5 retained objects
    dumpHeap = true,                // Automatically dump heap for analysis
    dumpHeapWhenDebugging = true    // Dump heap even when debugger is attached
)
```

### Key Features

1. **Automatic Detection** - LeakCanary automatically monitors:
   - Activities
   - Fragments
   - ViewModels
   - Services
   - Root Views

2. **Debug-Only Integration** - LeakCanary is only included in debug builds:
   ```gradle
   debugImplementation("com.squareup.leakcanary:leakcanary-android:2.14")
   ```

3. **Instrumentation Testing** - LeakCanary testing library for UI tests:
   ```gradle
   androidTestImplementation("com.squareup.leakcanary:leakcanary-android-instrumentation:2.14")
   ```

## Project Structure

```
SharkLeakFinderKit/
├── app/
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/com/example/sharkleakfinderkit/
│   │   │   │   ├── LeakFinderApplication.kt      # App configuration
│   │   │   │   ├── MainActivity.kt               # Main entry point
│   │   │   │   ├── LeakyActivity.kt             # Demo activity with leaks
│   │   │   │   └── utils/
│   │   │   │       └── LeakReporter.kt          # Leak logging utility
│   │   │   └── res/
│   │   │       └── layout/                      # UI layouts
│   │   └── androidTest/
│   │       └── java/com/example/sharkleakfinderkit/
│   │           ├── MemoryLeakDetectionTest.kt   # Leak detection tests
│   │           └── MemoryMonitoringTest.kt      # Memory monitoring tests
│   └── build.gradle.kts                         # App dependencies
├── build.gradle.kts                             # Project configuration
└── README.md                                     # This file
```

## UI Testing for Memory Leaks

### Running Tests

Execute the instrumentation tests to detect memory leaks:

```bash
./gradlew connectedAndroidTest
```

### Test Suites

#### 1. MemoryLeakDetectionTest

Comprehensive tests for detecting various types of memory leaks:

- **testMainActivityDoesNotLeak** - Verifies MainActivity doesn't leak
- **testLeakyActivityDetectsMemoryLeaks** - Detects leaks in LeakyActivity
- **testMultipleActivityInstancesForLeaks** - Monitors instance retention
- **testNoLeaksAfterApplicationRestart** - Tests activity recreation scenarios

```kotlin
@get:Rule
val detectLeaksRule = DetectLeaksAfterTestSuccess()
```

The `DetectLeaksAfterTestSuccess()` rule automatically fails tests when leaks are detected.

#### 2. MemoryMonitoringTest

Advanced memory monitoring during UI events:

- **testMemoryUsageDuringUIInteractions** - Tracks memory during repeated interactions
- **testThreadCountMonitoring** - Detects thread leaks
- **testMemoryLeakDetectionWithInstanceCounting** - Monitors object proliferation

Features:
- Takes memory snapshots at key points
- Tracks PSS (Proportional Set Size)
- Monitors thread count changes
- Logs detailed memory reports

### Memory Leak Scenarios

The `LeakyActivity` demonstrates three common memory leak patterns:

1. **Handler Leak** - Handler with delayed callback that outlives activity
2. **Static Reference Leak** - Activity stored in static variable
3. **Thread Leak** - Background thread holding activity reference

These are intentional leaks for testing purposes. In production:
- Always clean up handlers: `handler.removeCallbacksAndMessages(null)`
- Never store activities in static variables
- Interrupt threads in `onDestroy()`

## Memory Monitoring

### LeakReporter Utility

The `LeakReporter` class provides comprehensive leak logging:

```kotlin
// Log a detected leak
LeakReporter.logLeak(
    leakType = "Activity",
    description = "MainActivity leaked via Handler",
    retainedHeapBytes = 1024000,
    retainedObjectCount = 150,
    trace = "Full leak trace..."
)

// Generate summary report
val summary = LeakReporter.generateSummaryReport()
Log.d("LeakReport", summary)
```

Features:
- Detailed leak information logging
- Heap analysis result parsing
- Summary report generation
- Leak trace formatting

## Best Practices

### 1. Development Workflow

- **Monitor Continuously** - Keep LeakCanary active during development
- **Fix Immediately** - Address leaks as soon as they're detected
- **Review Regularly** - Check LeakCanary notifications and heap dumps

### 2. Common Leak Sources to Avoid

- ❌ Static references to Context/Activity/Fragment
- ❌ Non-static inner classes holding outer class references
- ❌ Unclosed resources (Cursors, Streams, Database connections)
- ❌ Listeners not unregistered in lifecycle methods
- ❌ Handlers with pending callbacks after activity destruction
- ❌ Background threads with activity references

### 3. Testing Best Practices

- Run instrumentation tests regularly
- Monitor memory during stress tests
- Check thread counts after activity destruction
- Verify instance counts after GC
- Use `DetectLeaksAfterTestSuccess()` rule in all UI tests

### 4. Configuration Tips

```kotlin
// Recommended LeakCanary configuration
LeakCanary.config = LeakCanary.config.copy(
    // Retain dumps for offline analysis
    retainedVisibleThreshold = 5,
    
    // Enable heap dumping
    dumpHeap = true,
    
    // Dump even when debugging
    dumpHeapWhenDebugging = true
)

// Show LeakCanary launcher icon for easy access
LeakCanary.showLeakDisplayActivityLauncherIcon(true)
```

## Building the Project

### Prerequisites

- Android Studio Arctic Fox or later
- Android SDK 21+ (minimum)
- Android SDK 34 (target)
- Kotlin 1.9.20+
- Gradle 8.2+

### Build Commands

```bash
# Build debug APK
./gradlew assembleDebug

# Run unit tests
./gradlew test

# Run instrumentation tests
./gradlew connectedAndroidTest

# Build release APK
./gradlew assembleRelease
```

## Gradle Dependencies

```kotlin
dependencies {
    // LeakCanary - Latest stable version
    debugImplementation("com.squareup.leakcanary:leakcanary-android:2.14")
    
    // LeakCanary for instrumentation tests
    androidTestImplementation("com.squareup.leakcanary:leakcanary-android-instrumentation:2.14")
    
    // Testing framework
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
}
```

## Viewing Leak Reports

### During Development

1. LeakCanary shows a notification when leaks are detected
2. Tap the notification to view detailed leak traces
3. Access LeakCanary from the app launcher icon
4. Review heap dumps in `/sdcard/Download/leakcanary-{app}/`

### During Testing

1. Tests fail automatically when leaks are detected
2. Check logcat for detailed leak information:
   ```bash
   adb logcat | grep -E "LeakCanary|LeakReporter|MemoryMonitor"
   ```
3. Review test reports in `app/build/reports/androidTests/connected/`

## Continuous Integration

To integrate leak detection in CI:

```yaml
# Example GitHub Actions workflow
- name: Run Instrumentation Tests
  run: ./gradlew connectedAndroidTest
  
- name: Upload Test Reports
  if: always()
  uses: actions/upload-artifact@v3
  with:
    name: test-reports
    path: app/build/reports/
```

## Troubleshooting

### LeakCanary Not Detecting Leaks

1. Ensure you're running a debug build
2. Check LeakCanary configuration in Application class
3. Verify `debugImplementation` is used, not `implementation`
4. Force GC and wait: `Runtime.getRuntime().gc()`

### Tests Not Failing on Leaks

1. Verify `DetectLeaksAfterTestSuccess()` rule is present
2. Check LeakCanary instrumentation dependency is included
3. Ensure sufficient time for leak detection (add `Thread.sleep()`)

### Memory Monitoring Not Working

1. Check device permissions for memory profiling
2. Verify tests are running on a real device or AVD
3. Review logcat output for memory snapshots

## Further Reading

- [LeakCanary Official Documentation](https://square.github.io/leakcanary/)
- [LeakCanary GitHub Repository](https://github.com/square/leakcanary)
- [Android Memory Management Guide](https://developer.android.com/topic/performance/memory)
- [Shark Heap Analysis](https://square.github.io/leakcanary/shark/)

## License

This project is provided as a demonstration and educational resource for integrating LeakCanary into Android applications.

## Contributing

Contributions are welcome! Please ensure:
- All tests pass
- No new memory leaks are introduced (except in demo scenarios)
- Code follows Kotlin style guidelines
- Documentation is updated for new features
