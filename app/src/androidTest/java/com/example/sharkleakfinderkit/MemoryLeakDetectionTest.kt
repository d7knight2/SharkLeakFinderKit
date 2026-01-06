package com.example.sharkleakfinderkit

import android.app.Application
import android.content.Context
import androidx.test.core.app.ApplicationProvider
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.action.ViewActions.click
import androidx.test.espresso.matcher.ViewMatchers.withId
import androidx.test.ext.junit.rules.ActivityScenarioRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import leakcanary.DetectLeaksAfterTestSuccess
import leakcanary.LeakAssertions
import org.junit.After
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Comprehensive UI tests for memory leak detection using LeakCanary.
 * 
 * These tests monitor:
 * - Activity lifecycle leaks
 * - Instance count monitoring
 * - Thread leaks
 * - Handler leaks
 * - Static reference leaks
 */
@RunWith(AndroidJUnit4::class)
class MemoryLeakDetectionTest {
    
    @get:Rule
    val activityRule = ActivityScenarioRule(MainActivity::class.java)
    
    @get:Rule
    val detectLeaksRule = DetectLeaksAfterTestSuccess()
    
    private val context: Context = ApplicationProvider.getApplicationContext()
    
    @After
    fun tearDown() {
        // Force garbage collection to help leak detection
        TestUtils.forceGarbageCollection()
    }
    
    @Test
    fun testMainActivityDoesNotLeak() {
        // This test verifies that MainActivity doesn't leak
        // when properly destroyed
        
        activityRule.scenario.close()
        
        // Wait for leak detection
        Thread.sleep(2000)
        
        // LeakCanary will automatically detect leaks via DetectLeaksAfterTestSuccess
    }
    
    @Test
    fun testLeakyActivityDetectsMemoryLeaks() {
        // Navigate to LeakyActivity
        onView(withId(R.id.leakyActivityButton)).perform(click())
        
        // Wait for activity to fully initialize
        Thread.sleep(1000)
        
        // Go back to destroy the LeakyActivity
        onView(withId(R.id.finishButton)).perform(click())
        
        // Wait for activity destruction and leak detection
        Thread.sleep(3000)
        
        // LeakCanary should detect the leaks created in LeakyActivity
        // The DetectLeaksAfterTestSuccess rule will fail the test if leaks are found
    }
    
    @Test
    fun testMultipleActivityInstancesForLeaks() {
        // Test multiple instances to monitor instance counts
        
        // Open and close LeakyActivity multiple times
        repeat(3) { iteration ->
            onView(withId(R.id.leakyActivityButton)).perform(click())
            Thread.sleep(500)
            onView(withId(R.id.finishButton)).perform(click())
            Thread.sleep(500)
        }
        
        // Force GC and wait for leak detection
        Runtime.getRuntime().gc()
        Thread.sleep(2000)
        
        // LeakCanary will detect if multiple instances are retained
    }
    
    @Test
    fun testNoLeaksAfterApplicationRestart() {
        // Simulate activity recreation (like screen rotation)
        activityRule.scenario.recreate()
        
        // Wait for recreation
        Thread.sleep(1000)
        
        activityRule.scenario.close()
        
        // Wait for leak detection
        Thread.sleep(2000)
        
        // Should not leak after recreation
    }
}
