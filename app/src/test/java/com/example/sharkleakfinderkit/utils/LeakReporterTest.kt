package com.example.sharkleakfinderkit.utils

import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

/**
 * Unit tests for LeakReporter utility class.
 * These tests verify the leak reporting, formatting, and summary generation functionality.
 */
class LeakReporterTest {

    @Before
    fun setUp() {
        // Clear any existing reports before each test
        LeakReporter.clearReports()
    }

    @After
    fun tearDown() {
        // Clean up after each test
        LeakReporter.clearReports()
    }

    @Test
    fun testLogLeak_CreatesReport() {
        // When
        LeakReporter.logLeak(
            leakType = "ActivityLeak",
            description = "MainActivity leaked via Handler",
            retainedHeapBytes = 1024,
            retainedObjectCount = 5,
            trace = "test trace"
        )

        // Then
        val reports = LeakReporter.getAllReports()
        assertEquals(1, reports.size)
        
        val report = reports[0]
        assertEquals("ActivityLeak", report.leakType)
        assertEquals("MainActivity leaked via Handler", report.leakDescription)
        assertEquals(1024L, report.retainedHeapBytes)
        assertEquals(5, report.retainedObjectCount)
        assertEquals("test trace", report.leakTrace)
        assertTrue(report.timestamp > 0)
    }

    @Test
    fun testLogLeak_WithDefaultValues() {
        // When
        LeakReporter.logLeak(
            leakType = "SimpleLeak",
            description = "Basic leak"
        )

        // Then
        val reports = LeakReporter.getAllReports()
        assertEquals(1, reports.size)
        
        val report = reports[0]
        assertEquals("SimpleLeak", report.leakType)
        assertEquals("Basic leak", report.leakDescription)
        assertEquals(0L, report.retainedHeapBytes)
        assertEquals(0, report.retainedObjectCount)
        assertEquals("", report.leakTrace)
    }

    @Test
    fun testGetAllReports_ReturnsImmutableList() {
        // Given
        LeakReporter.logLeak("Leak1", "Description1")
        
        // When
        val reports = LeakReporter.getAllReports()
        
        // Then
        assertEquals(1, reports.size)
        
        // Verify it's a copy (modifying the returned list shouldn't affect the internal state)
        LeakReporter.logLeak("Leak2", "Description2")
        assertEquals(1, reports.size) // Original list unchanged
        assertEquals(2, LeakReporter.getAllReports().size) // New list has both
    }

    @Test
    fun testClearReports_RemovesAllReports() {
        // Given
        LeakReporter.logLeak("Leak1", "Description1")
        LeakReporter.logLeak("Leak2", "Description2")
        assertEquals(2, LeakReporter.getAllReports().size)

        // When
        LeakReporter.clearReports()

        // Then
        assertEquals(0, LeakReporter.getAllReports().size)
    }

    @Test
    fun testGenerateSummaryReport_NoLeaks() {
        // When
        val summary = LeakReporter.generateSummaryReport()

        // Then
        assertEquals("No memory leaks detected.", summary)
    }

    @Test
    fun testGenerateSummaryReport_WithLeaks() {
        // Given
        LeakReporter.logLeak(
            leakType = "ActivityLeak",
            description = "MainActivity leaked",
            retainedHeapBytes = 2048,
            retainedObjectCount = 3
        )
        LeakReporter.logLeak(
            leakType = "ActivityLeak",
            description = "SecondActivity leaked",
            retainedHeapBytes = 1024,
            retainedObjectCount = 2
        )
        LeakReporter.logLeak(
            leakType = "HandlerLeak",
            description = "Handler not released",
            retainedHeapBytes = 512,
            retainedObjectCount = 1
        )

        // When
        val summary = LeakReporter.generateSummaryReport()

        // Then
        assertTrue(summary.contains("Memory Leak Summary Report"))
        assertTrue(summary.contains("Total leaks detected: 3"))
        assertTrue(summary.contains("ActivityLeak: 2 occurrence(s)"))
        assertTrue(summary.contains("HandlerLeak: 1 occurrence(s)"))
        assertTrue(summary.contains("Recent leaks"))
    }

    @Test
    fun testGenerateSummaryReport_GroupsByLeakType() {
        // Given
        LeakReporter.logLeak("TypeA", "First", 1000)
        LeakReporter.logLeak("TypeA", "Second", 2000)
        LeakReporter.logLeak("TypeB", "Third", 3000)

        // When
        val summary = LeakReporter.generateSummaryReport()

        // Then
        assertTrue(summary.contains("TypeA: 2 occurrence(s)"))
        assertTrue(summary.contains("TypeB: 1 occurrence(s)"))
    }

    @Test
    fun testMultipleLeaks_MaintainsOrder() {
        // Given
        LeakReporter.logLeak("Leak1", "First")
        LeakReporter.logLeak("Leak2", "Second")
        LeakReporter.logLeak("Leak3", "Third")

        // When
        val reports = LeakReporter.getAllReports()

        // Then
        assertEquals(3, reports.size)
        assertEquals("Leak1", reports[0].leakType)
        assertEquals("Leak2", reports[1].leakType)
        assertEquals("Leak3", reports[2].leakType)
    }

    @Test
    fun testLeakReport_DataClass() {
        // Given
        val report1 = LeakReporter.LeakReport(
            timestamp = 12345L,
            leakType = "TestLeak",
            leakDescription = "Test description",
            retainedHeapBytes = 1024L,
            retainedObjectCount = 5,
            leakTrace = "test trace"
        )

        val report2 = LeakReporter.LeakReport(
            timestamp = 12345L,
            leakType = "TestLeak",
            leakDescription = "Test description",
            retainedHeapBytes = 1024L,
            retainedObjectCount = 5,
            leakTrace = "test trace"
        )

        // Then - data class equality
        assertEquals(report1, report2)
        assertEquals(report1.hashCode(), report2.hashCode())
    }
}
