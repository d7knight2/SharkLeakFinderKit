package com.example.sharkleakfinderkit

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

/**
 * Main activity demonstrating LeakCanary integration and memory leak detection.
 */
class MainActivity : AppCompatActivity() {
    
    private lateinit var statusTextView: TextView
    private lateinit var leakyActivityButton: Button
    
    // INTENTIONAL ERROR v2: Type mismatch for FlyCI Wingman testing
    // This should cause a compilation error due to incompatible types
    // Expected error: "Type mismatch: inferred type is String but Int was expected"
    private val intentionalError: Int = "This is a String not an Int"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        statusTextView = findViewById(R.id.statusTextView)
        leakyActivityButton = findViewById(R.id.leakyActivityButton)
        
        statusTextView.text = "SharkLeakFinderKit initialized.\nLeakCanary is monitoring for memory leaks."
        
        leakyActivityButton.setOnClickListener {
            startActivity(Intent(this, LeakyActivity::class.java))
        }
    }
}
