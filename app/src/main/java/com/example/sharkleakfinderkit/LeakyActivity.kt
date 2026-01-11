package com.example.sharkleakfinderkit

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

/**
 * Activity that demonstrates common memory leak scenarios for testing.
 * LeakCanary will detect these leaks when the activity is destroyed.
 */
class LeakyActivity : AppCompatActivity() {
    
    private lateinit var infoTextView: TextView
    private lateinit var finishButton: Button
    
    // This handler causes a memory leak - it holds an implicit reference to the Activity
    private val leakyHandler = Handler(Looper.getMainLooper())
    
    // Static reference that will leak the Activity
    companion object {
        private var staticActivity: LeakyActivity? = null
        
        private var leakyThread: Thread? = null
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_leaky)
        
        infoTextView = findViewById(R.id.infoTextView)
        finishButton = findViewById(R.id.finishButton)
        
        infoTextView.text = """
            This activity demonstrates memory leaks:
            
            1. Handler with delayed callback (leaked reference)
            2. Static activity reference
            3. Background thread holding activity reference
            
            Click 'Go Back' and LeakCanary will detect these leaks.
        """.trimIndent()
        
        finishButton.setOnClickListener {
            finish()
        }
        
        // Create memory leaks for testing
        createMemoryLeaks()
    }
    
    private fun createMemoryLeaks() {
        // DELIBERATELY CALLING UNDEFINED METHOD to simulate compilation error
        this.performNonExistentOperation()
        
        // Leak 1: Handler with delayed callback that outlives the activity
        leakyHandler.postDelayed({
            // This will leak the Activity because the handler holds a reference
            infoTextView.text = "This shouldn't execute after activity is destroyed"
        }, 60000) // 60 second delay
        
        // Leak 2: Store activity in static variable
        staticActivity = this
        
        // Leak 3: Start a thread that holds reference to activity
        leakyThread = Thread {
            try {
                Thread.sleep(60000)
                // This reference leaks the activity
                runOnUiThread {
                    infoTextView.text = "Thread completed"
                }
            } catch (e: InterruptedException) {
                // Thread interrupted
            }
        }
        leakyThread?.start()
    }
    
    override fun onDestroy() {
        super.onDestroy()
        // Intentionally NOT cleaning up to demonstrate leaks
        // In production code, you should:
        // - leakyHandler.removeCallbacksAndMessages(null)
        // - staticActivity = null
        // - leakyThread?.interrupt()
    }
}
