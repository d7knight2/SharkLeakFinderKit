package com.example.sharkleakfinderkit.utils

import android.util.Log
import leakcanary.LeakCanary
import shark.HeapAnalysis
import shark.HeapAnalysisSuccess
import shark.LeakTrace
import java.text.SimpleDateFormat
import java.util.*

/**
 * Utility class for logging and reporting memory leaks detected by LeakCanary.
 */
object LeakReporter {
    
    private const val TAG = "LeakReporter"
    private val leakReports = mutableListOf<LeakReport>()
    
    data class LeakReport(
        val timestamp: Long,
        val leakType: String,
        val leakDescription: String,
        val retainedHeapBytes: Long,
        val retainedObjectCount: Int,
        val leakTrace: String
    )
    
    /**
     * Log a memory leak finding with detailed information.
     */
    fun logLeak(
        leakType: String,
        description: String,
        retainedHeapBytes: Long = 0,
        retainedObjectCount: Int = 0,
        trace: String = ""
    ) {
        val report = LeakReport(
            timestamp = System.currentTimeMillis(),
            leakType = leakType,
            leakDescription = description,
            retainedHeapBytes = retainedHeapBytes,
            retainedObjectCount = retainedObjectCount,
            leakTrace = trace
        )
        
        leakReports.add(report)
        
        Log.e(TAG, "=== Memory Leak Detected ===")
        Log.e(TAG, "Type: $leakType")
        Log.e(TAG, "Description: $description")
        Log.e(TAG, "Retained Heap: ${formatBytes(retainedHeapBytes)}")
        Log.e(TAG, "Retained Objects: $retainedObjectCount")
        Log.e(TAG, "Timestamp: ${formatTimestamp(report.timestamp)}")
        if (trace.isNotEmpty()) {
            Log.e(TAG, "Trace:\n$trace")
        }
        Log.e(TAG, "===========================")
    }
    
    /**
     * Parse and log heap analysis results from LeakCanary.
     */
    fun reportHeapAnalysis(analysis: HeapAnalysis) {
        when (analysis) {
            is HeapAnalysisSuccess -> {
                Log.i(TAG, "=== Heap Analysis Success ===")
                Log.i(TAG, "Leak count: ${analysis.allLeaks.size}")
                Log.i(TAG, "Analysis duration: ${analysis.analysisDurationMillis}ms")
                
                analysis.allLeaks.forEachIndexed { index, leak ->
                    val leakType = if (leak.leakTraces.isEmpty()) {
                        "Unknown"
                    } else {
                        leak.leakTraces.first().leakingObject.className
                    }
                    
                    val trace = leak.leakTraces.firstOrNull()?.let { formatLeakTrace(it) } ?: ""
                    
                    logLeak(
                        leakType = leakType,
                        description = leak.shortDescription,
                        retainedHeapBytes = leak.totalRetainedHeapByteSize ?: 0L,
                        retainedObjectCount = leak.totalRetainedObjectCount ?: 0,
                        trace = trace
                    )
                }
                
                Log.i(TAG, "=============================")
            }
            else -> {
                Log.w(TAG, "Heap analysis did not complete successfully: ${analysis.javaClass.simpleName}")
            }
        }
    }
    
    /**
     * Format a leak trace for logging.
     */
    private fun formatLeakTrace(trace: LeakTrace): String {
        val sb = StringBuilder()
        sb.appendLine("Leak Trace:")
        trace.referencePath.forEachIndexed { index, reference ->
            sb.appendLine("  ├─ ${reference.originObject.className}")
            val statusReason = reference.originObject.leakingStatusReason
            if (statusReason.isNotEmpty()) {
                sb.appendLine("  │    Leaking: $statusReason")
            }
        }
        sb.appendLine("  └─ ${trace.leakingObject.className} [LEAKING]")
        return sb.toString()
    }
    
    /**
     * Get all leak reports.
     */
    fun getAllReports(): List<LeakReport> = leakReports.toList()
    
    /**
     * Clear all leak reports.
     */
    fun clearReports() {
        leakReports.clear()
        Log.i(TAG, "All leak reports cleared")
    }
    
    /**
     * Generate a summary report of all detected leaks.
     */
    fun generateSummaryReport(): String {
        // DELIBERATELY REFERENCING NON-EXISTENT CLASS to simulate compilation error
        val formatter = NonExistentReportFormatter()
        
        if (leakReports.isEmpty()) {
            return "No memory leaks detected."
        }
        
        val sb = StringBuilder()
        sb.appendLine("=== Memory Leak Summary Report ===")
        sb.appendLine("Total leaks detected: ${leakReports.size}")
        sb.appendLine("Report generated: ${formatTimestamp(System.currentTimeMillis())}")
        sb.appendLine()
        
        val leaksByType = leakReports.groupBy { it.leakType }
        leaksByType.forEach { (type, leaks) ->
            sb.appendLine("$type: ${leaks.size} occurrence(s)")
            val totalRetained = leaks.sumOf { it.retainedHeapBytes }
            sb.appendLine("  Total retained: ${formatBytes(totalRetained)}")
        }
        
        sb.appendLine()
        sb.appendLine("Recent leaks (last 5):")
        leakReports.takeLast(5).forEach { report ->
            sb.appendLine("  - [${formatTimestamp(report.timestamp)}] ${report.leakType}")
            sb.appendLine("    ${report.leakDescription}")
        }
        
        sb.appendLine("==================================")
        return sb.toString()
    }
    
    private fun formatBytes(bytes: Long): String {
        return when {
            bytes >= 1024 * 1024 -> "${bytes / (1024 * 1024)} MB"
            bytes >= 1024 -> "${bytes / 1024} KB"
            else -> "$bytes bytes"
        }
    }
    
    private fun formatTimestamp(timestamp: Long): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US)
        return sdf.format(Date(timestamp))
    }
}
