package com.example.sharkleakfinderkit

import android.app.Application

/**
 * Application class for release builds (without LeakCanary).
 * 
 * LeakCanary is only included in debug builds for memory leak detection.
 * This release version provides a minimal Application class without leak detection.
 */
class LeakFinderApplication : Application() {
    
    override fun onCreate() {
        super.onCreate()
        // No LeakCanary configuration in release builds
    }
}
