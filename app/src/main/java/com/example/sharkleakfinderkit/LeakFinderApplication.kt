package com.example.sharkleakfinderkit

import android.app.Application
import leakcanary.LeakCanary

/**
 * Application class with LeakCanary configuration following best practices.
 * 
 * LeakCanary is automatically initialized and will detect memory leaks in:
 * - Activities
 * - Fragments
 * - ViewModels
 * - Services
 * - Root Views
 */
class LeakFinderApplication : Application() {
    
    override fun onCreate() {
        super.onCreate()
        
        // Configure LeakCanary with best practices
        configureLeakCanary()
    }
    
    private fun configureLeakCanary() {
        // LeakCanary 2.x is automatically initialized with sensible defaults
        // Additional configuration can be done here if needed
        
        LeakCanary.config = LeakCanary.config.copy(
            // Retain heap dumps for later analysis
            retainedVisibleThreshold = 5,
            
            // Dump heap when 5 retained objects are detected
            dumpHeap = true,
            
            // Number of GC triggers before declaring an object as leaked
            dumpHeapWhenDebugging = true
        )
        
        LeakCanary.showLeakDisplayActivityLauncherIcon(true)
    }
}
