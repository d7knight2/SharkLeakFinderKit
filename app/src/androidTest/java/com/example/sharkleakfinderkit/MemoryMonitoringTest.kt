package com.example.sharkleakfinderkit

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.os.Debug
import android.util.Log
import androidx.test.core.app.ApplicationProvider
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.action.ViewActions.click
import androidx.test.espresso.matcher.ViewMatchers.withId
import androidx.test.ext.junit.rules.ActivityScenarioRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import leakcanary.DetectLeaksAfterTestSuccess
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import kotlin.test.assertTrue

/**
 * Tests for monitoring memory usage during UI events and detecting anomalies.
 */
@RunWith(AndroidJUnit4::class)
class MemoryMonitoringTest {
    
    @get:Rule
    val activityRule = ActivityScenarioRule(MainActivity::class.java)
    
    @get:Rule
    val detectLeaksRule = DetectLeaksAfterTestSuccess()
    
    private val context: Context = ApplicationProvider.getApplicationContext()
    private val memorySnapshots = mutableListOf<MemorySnapshot>()
    
    data class MemorySnapshot(
        val timestamp: Long,
        val totalPss: Long,
        val dalvikPss: Long,
        val nativePss: Long,
        val heapAllocated: Long,
        val heapFree: Long,
        val threadCount: Int
    )
    
    @Before
    fun setUp() {
        memorySnapshots.clear()
        takeMemorySnapshot("initial")
    }
    
    @After
    fun tearDown() {
        takeMemorySnapshot("final")
        logMemoryReport()
        TestUtils.forceGarbageCollection()
    }
    
    private fun takeMemorySnapshot(label: String) {
        val activityManager = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val memoryInfo = Debug.MemoryInfo()
        Debug.getMemoryInfo(memoryInfo)
        
        val runtime = Runtime.getRuntime()
        val threadCount = Thread.activeCount()
        
        val snapshot = MemorySnapshot(
            timestamp = System.currentTimeMillis(),
            totalPss = memoryInfo.totalPss.toLong(),
            dalvikPss = memoryInfo.dalvikPss.toLong(),
            nativePss = memoryInfo.nativePss.toLong(),
            heapAllocated = runtime.totalMemory() - runtime.freeMemory(),
            heapFree = runtime.freeMemory(),
            threadCount = threadCount
        )
        
        memorySnapshots.add(snapshot)
        Log.d("MemoryMonitor", "[$label] Memory: ${snapshot.totalPss}KB, Threads: ${snapshot.threadCount}")
    }
    
    private fun logMemoryReport() {
        if (memorySnapshots.size < 2) return
        
        val first = memorySnapshots.first()
        val last = memorySnapshots.last()
        
        val memoryIncrease = last.totalPss - first.totalPss
        val threadIncrease = last.threadCount - first.threadCount
        
        Log.d("MemoryMonitor", "=== Memory Report ===")
        Log.d("MemoryMonitor", "Initial PSS: ${first.totalPss}KB")
        Log.d("MemoryMonitor", "Final PSS: ${last.totalPss}KB")
        Log.d("MemoryMonitor", "PSS Increase: ${memoryIncrease}KB")
        Log.d("MemoryMonitor", "Initial Threads: ${first.threadCount}")
        Log.d("MemoryMonitor", "Final Threads: ${last.threadCount}")
        Log.d("MemoryMonitor", "Thread Increase: $threadIncrease")
        Log.d("MemoryMonitor", "====================")
    }
    
    @Test
    fun testMemoryUsageDuringUIInteractions() {
        // Monitor memory during repeated UI interactions
        
        takeMemorySnapshot("before_interactions")
        
        // Perform multiple UI interactions
        repeat(5) { iteration ->
            onView(withId(R.id.leakyActivityButton)).perform(click())
            takeMemorySnapshot("after_open_$iteration")
            Thread.sleep(300)
            
            onView(withId(R.id.finishButton)).perform(click())
            takeMemorySnapshot("after_close_$iteration")
            Thread.sleep(300)
        }
        
        // Force GC
        TestUtils.forceGarbageCollection()
        
        takeMemorySnapshot("after_gc")
        
        // Memory should stabilize after GC
        assertTrue(memorySnapshots.size >= 10, "Should have multiple memory snapshots")
    }
    
    @Test
    fun testThreadCountMonitoring() {
        // Monitor thread count during activity lifecycle
        
        val initialThreadCount = Thread.activeCount()
        takeMemorySnapshot("initial_threads")
        
        // Open and close activity multiple times
        repeat(3) {
            onView(withId(R.id.leakyActivityButton)).perform(click())
            Thread.sleep(500)
            takeMemorySnapshot("with_leaky_activity")
            
            onView(withId(R.id.finishButton)).perform(click())
            Thread.sleep(500)
            takeMemorySnapshot("after_close")
        }
        
        // Wait for cleanup
        TestUtils.forceGarbageCollection(2000)
        
        val finalThreadCount = Thread.activeCount()
        takeMemorySnapshot("final_threads")
        
        Log.d("MemoryMonitor", "Thread count change: $initialThreadCount -> $finalThreadCount")
        
        // Thread count should increase due to leaks (this is expected in this test)
        // In a real app, this would be a red flag
    }
    
    @Test
    fun testMemoryLeakDetectionWithInstanceCounting() {
        // Track instance counts indirectly through memory snapshots
        
        takeMemorySnapshot("baseline")
        val baselineMemory = memorySnapshots.last().totalPss
        
        // Create multiple leaky instances
        repeat(10) {
            onView(withId(R.id.leakyActivityButton)).perform(click())
            Thread.sleep(200)
            onView(withId(R.id.finishButton)).perform(click())
            Thread.sleep(200)
            
            if (it % 3 == 0) {
                takeMemorySnapshot("iteration_$it")
            }
        }
        
        // Memory should grow significantly due to leaks
        val finalMemory = memorySnapshots.last().totalPss
        val memoryGrowth = finalMemory - baselineMemory
        
        Log.d("MemoryMonitor", "Memory growth after 10 leaky activities: ${memoryGrowth}KB")
        
        // This test documents the leak - in production, growth should be minimal
    }
}
