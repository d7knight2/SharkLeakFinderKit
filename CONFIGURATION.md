# LeakCanary Configuration Guide

## Overview

This guide covers the LeakCanary configuration used in SharkLeakFinderKit and explains best practices for optimal memory leak detection.

## Current Configuration

### Version

**LeakCanary 2.14** (Latest Stable Release - April 2024)

```gradle
debugImplementation("com.squareup.leakcanary:leakcanary-android:2.14")
androidTestImplementation("com.squareup.leakcanary:leakcanary-android-instrumentation:2.14")
```

### Why Version 2.14?

- ✅ **Stable** - Production-ready with extensive testing
- ✅ **Battle-tested** - Used by thousands of apps
- ✅ **Complete Documentation** - Full API documentation available
- ✅ **Android 14 Support** - Compatible with latest Android versions
- ⚠️ **v3.0-alpha-8 Available** - But may have stability issues

## Application Configuration

### LeakFinderApplication.kt

```kotlin
class LeakFinderApplication : Application() {
    
    override fun onCreate() {
        super.onCreate()
        configureLeakCanary()
    }
    
    private fun configureLeakCanary() {
        LeakCanary.config = LeakCanary.config.copy(
            // Show notification after 5 retained objects
            retainedVisibleThreshold = 5,
            
            // Automatically dump heap for analysis
            dumpHeap = true,
            
            // Dump heap even when debugger is attached
            dumpHeapWhenDebugging = true
        )
        
        // Show launcher icon for easy access
        LeakCanary.showLeakDisplayActivityLauncherIcon(true)
    }
}
```

## Configuration Options

### 1. Retained Object Threshold

```kotlin
retainedVisibleThreshold = 5
```

**What it does:** Sets the number of retained objects before showing a notification.

**Recommendations:**
- **Development:** 1-5 (detect leaks quickly)
- **Testing:** 5-10 (reduce noise in automated tests)
- **Default:** 5

### 2. Heap Dumping

```kotlin
dumpHeap = true
```

**What it does:** Automatically triggers heap dump when leaks are detected.

**Recommendations:**
- **Always:** `true` (needed for leak analysis)
- **Disable only if:** Storage space is extremely limited

### 3. Dump When Debugging

```kotlin
dumpHeapWhenDebugging = true
```

**What it does:** Allows heap dumps even when debugger is attached.

**Recommendations:**
- **Development:** `true` (detect leaks during debugging)
- **CI/CD:** `true` (enable in automated tests)

### 4. Launcher Icon

```kotlin
LeakCanary.showLeakDisplayActivityLauncherIcon(true)
```

**What it does:** Shows LeakCanary icon in app launcher.

**Recommendations:**
- **Development:** `true` (easy access to leak reports)
- **Can be toggled** in LeakCanary settings

## Advanced Configuration

### Custom Object Watchers

Watch custom objects for leaks:

```kotlin
import leakcanary.AppWatcher

class MyActivity : AppCompatActivity() {
    private val customObject = MyCustomObject()
    
    override fun onDestroy() {
        super.onDestroy()
        
        // Watch custom object
        AppWatcher.objectWatcher.watch(
            watchedObject = customObject,
            description = "MyCustomObject from MyActivity"
        )
    }
}
```

### Custom Reference Matchers

Exclude known safe references:

```kotlin
import leakcanary.LeakCanary
import shark.AndroidReferenceMatchers
import shark.IgnoredReferenceMatcher

LeakCanary.config = LeakCanary.config.copy(
    referenceMatchers = AndroidReferenceMatchers.appDefaults + listOf(
        IgnoredReferenceMatcher(
            pattern = "com.example.ThirdPartyLibrary\$InternalClass",
            description = "Known safe reference from third-party library"
        )
    )
)
```

### Heap Dump Triggers

Configure when heap dumps occur:

```kotlin
import leakcanary.LeakCanary

LeakCanary.config = LeakCanary.config.copy(
    // Dump immediately when retained objects exceed threshold
    dumpHeap = true,
    
    // Wait for this many retained objects
    retainedVisibleThreshold = 5,
    
    // Maximum stored heap dumps
    maxStoredHeapDumps = 7
)
```

### Event Listeners

Listen to leak events:

```kotlin
import leakcanary.LeakCanary
import leakcanary.EventListener

class MyEventListener : EventListener {
    override fun onEvent(event: Event) {
        when (event) {
            is Event.HeapDump -> {
                Log.d("LeakCanary", "Heap dump created: ${event.file}")
            }
            is Event.HeapAnalysisProgress -> {
                Log.d("LeakCanary", "Analysis progress: ${event.step}")
            }
            is Event.HeapAnalysisDone -> {
                Log.d("LeakCanary", "Analysis complete: ${event.heapAnalysis}")
            }
        }
    }
}

LeakCanary.config = LeakCanary.config.copy(
    eventListeners = LeakCanary.config.eventListeners + MyEventListener()
)
```

## Build Configuration

### Gradle Setup

```kotlin
// app/build.gradle.kts
android {
    compileSdk = 34
    
    defaultConfig {
        minSdk = 21  // LeakCanary supports API 21+
        targetSdk = 34
        
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }
}

dependencies {
    // LeakCanary for debug builds only
    debugImplementation("com.squareup.leakcanary:leakcanary-android:2.14")
    
    // LeakCanary for instrumentation tests
    androidTestImplementation("com.squareup.leakcanary:leakcanary-android-instrumentation:2.14")
    
    // Don't use 'implementation' - only debug builds
}
```

### ProGuard Rules

```proguard
# app/proguard-rules.pro

# Keep LeakCanary classes
-dontwarn com.squareup.leakcanary.**
-keep class com.squareup.leakcanary.** { *; }

# Keep Shark (heap analyzer)
-dontwarn shark.**
-keep class shark.** { *; }
```

## Testing Configuration

### DetectLeaksAfterTestSuccess Rule

```kotlin
import leakcanary.DetectLeaksAfterTestSuccess
import org.junit.Rule

class MyTest {
    @get:Rule
    val detectLeaksRule = DetectLeaksAfterTestSuccess()
    
    @Test
    fun myTest() {
        // Test code
        // Leaks detected after test will cause failure
    }
}
```

### Custom Detection Configuration

```kotlin
import leakcanary.DetectLeaksAfterTestSuccess

@get:Rule
val detectLeaksRule = DetectLeaksAfterTestSuccess(
    tag = "MyTest",
    
    // Fail test only for application leaks (not library leaks)
    detectLeaksAssert = { heapAnalysis ->
        val appLeaks = heapAnalysis.allLeaks.filter { 
            it.leakTraces.any { trace ->
                trace.leakingObject.className.startsWith("com.example")
            }
        }
        if (appLeaks.isNotEmpty()) {
            throw AssertionError("${appLeaks.size} leaks detected")
        }
    }
)
```

## Environment-Specific Configuration

### Development

```kotlin
if (BuildConfig.DEBUG) {
    LeakCanary.config = LeakCanary.config.copy(
        retainedVisibleThreshold = 1,  // Immediate detection
        dumpHeap = true,
        dumpHeapWhenDebugging = true
    )
    LeakCanary.showLeakDisplayActivityLauncherIcon(true)
}
```

### Automated Testing

```kotlin
if (isRunningInTest()) {
    LeakCanary.config = LeakCanary.config.copy(
        retainedVisibleThreshold = 5,
        dumpHeap = true,
        // Don't show notifications during tests
        requestWriteExternalStoragePermission = false
    )
}
```

### Production

```kotlin
// Don't include LeakCanary in production builds
// Use 'debugImplementation' not 'implementation'
```

## Performance Tuning

### Reduce Overhead

```kotlin
LeakCanary.config = LeakCanary.config.copy(
    // Increase threshold to reduce frequency
    retainedVisibleThreshold = 10,
    
    // Limit stored dumps
    maxStoredHeapDumps = 3,
    
    // Reduce analysis overhead
    computeRetainedHeapSize = false
)
```

### Optimize for CI

```kotlin
// Fail fast in CI environments
LeakCanary.config = LeakCanary.config.copy(
    retainedVisibleThreshold = 1,
    dumpHeap = true,
    dumpHeapWhenDebugging = true
)
```

## Monitoring Specific Components

### Activities

Automatically monitored by default. No configuration needed.

### Fragments

Automatically monitored by default. No configuration needed.

### ViewModels

```kotlin
import androidx.lifecycle.ViewModel
import leakcanary.AppWatcher

class MyViewModel : ViewModel() {
    override fun onCleared() {
        super.onCleared()
        
        // Watch ViewModel for leaks
        AppWatcher.objectWatcher.watch(
            watchedObject = this,
            description = "MyViewModel cleared"
        )
    }
}
```

### Services

```kotlin
import android.app.Service
import leakcanary.AppWatcher

class MyService : Service() {
    override fun onDestroy() {
        super.onDestroy()
        
        AppWatcher.objectWatcher.watch(
            watchedObject = this,
            description = "MyService destroyed"
        )
    }
}
```

### Custom Views

```kotlin
import android.view.View
import leakcanary.AppWatcher

class MyCustomView(context: Context) : View(context) {
    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        
        AppWatcher.objectWatcher.watch(
            watchedObject = this,
            description = "MyCustomView detached"
        )
    }
}
```

## Troubleshooting Configuration

### LeakCanary Not Working

1. **Check build variant:** Must be debug build
2. **Verify dependencies:** Check `debugImplementation`
3. **Check Application class:** Ensure it's registered in manifest
4. **Clear and rebuild:** `./gradlew clean build`

### Too Many Notifications

```kotlin
// Increase threshold
LeakCanary.config = LeakCanary.config.copy(
    retainedVisibleThreshold = 10
)
```

### Missing Heap Dumps

```kotlin
// Enable heap dumping
LeakCanary.config = LeakCanary.config.copy(
    dumpHeap = true,
    requestWriteExternalStoragePermission = true
)

// Check storage permissions
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### Crashes During Analysis

```kotlin
// Reduce memory usage
LeakCanary.config = LeakCanary.config.copy(
    computeRetainedHeapSize = false,
    maxStoredHeapDumps = 2
)
```

## Migration Guide

### From LeakCanary 1.x to 2.x

```kotlin
// Old (1.x)
LeakCanary.install(this)

// New (2.x)
// No installation needed - automatic initialization
// Configure in Application class if needed
```

### From LeakCanary 2.x to 3.x (Alpha)

```kotlin
// Dependencies change
debugImplementation("com.squareup.leakcanary:leakcanary-android:3.0-alpha-8")

// API mostly compatible
// Check changelog for breaking changes
```

## Best Practices Summary

1. ✅ **Use debug builds only** - `debugImplementation`
2. ✅ **Configure in Application class** - Centralized setup
3. ✅ **Enable heap dumping** - Essential for analysis
4. ✅ **Show launcher icon** - Easy access during development
5. ✅ **Use test rules** - Automated leak detection in tests
6. ✅ **Monitor custom objects** - Watch important objects
7. ✅ **Keep updated** - Use latest stable version
8. ✅ **Review regularly** - Check leak reports frequently

## Resources

- [Official Configuration Docs](https://square.github.io/leakcanary/config/)
- [API Reference](https://square.github.io/leakcanary/api/)
- [Changelog](https://square.github.io/leakcanary/changelog/)
- [GitHub Issues](https://github.com/square/leakcanary/issues)

## Conclusion

Proper LeakCanary configuration is essential for effective memory leak detection. This project uses industry best practices and the latest stable version to ensure reliable leak detection during development and testing.
