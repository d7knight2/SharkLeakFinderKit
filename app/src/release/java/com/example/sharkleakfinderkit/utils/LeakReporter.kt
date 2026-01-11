package com.example.sharkleakfinderkit.utils

import android.util.Log

/**
 * Stub implementation of LeakReporter for release builds.
 * 
 * LeakCanary and Shark are only available in debug builds.
 * This release version provides no-op implementations to allow compilation.
 */
object LeakReporter {
    
    private const val TAG = "LeakReporter"
    
    data class LeakReport(
        val timestamp: Long,
        val leakType: String,
        val leakDescription: String,
        val retainedHeapBytes: Long,
        val retainedObjectCount: Int,
        val leakTrace: String
    )
    
    /**
     * No-op implementation for release builds.
     */
    fun logLeak(
        leakType: String,
        description: String,
        retainedHeapBytes: Long = 0,
        retainedObjectCount: Int = 0,
        trace: String = ""
    ) {
        // No-op in release builds
    }
    
    /**
     * No-op implementation for release builds.
     */
    fun reportHeapAnalysis(analysis: Any) {
        // No-op in release builds
    }
    
    /**
     * Returns empty list in release builds.
     */
    fun getAllReports(): List<LeakReport> = emptyList()
    
    /**
     * No-op implementation for release builds.
     */
    fun clearReports() {
        // No-op in release builds
    }
    
    /**
     * Returns message indicating leak detection is disabled in release builds.
     */
    fun generateSummaryReport(): String {
        return "Memory leak detection is only available in debug builds."
    }
}
