package com.example.sharkleakfinderkit

/**
 * Test utilities for memory leak detection tests.
 */
object TestUtils {
    
    /**
     * Force garbage collection and wait for completion.
     * Calls GC twice to ensure thorough cleanup.
     */
    fun forceGarbageCollection(waitMillis: Long = 1000) {
        Runtime.getRuntime().gc()
        Thread.sleep(waitMillis)
        Runtime.getRuntime().gc()
        Thread.sleep(waitMillis)
    }
    
    /**
     * Wait for a specified duration with GC between waits.
     * Useful for allowing async operations to complete.
     */
    fun waitWithGC(waitMillis: Long = 2000) {
        Thread.sleep(waitMillis / 2)
        Runtime.getRuntime().gc()
        Thread.sleep(waitMillis / 2)
    }
}
