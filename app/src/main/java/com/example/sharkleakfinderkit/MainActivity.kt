package com.example.sharkleakfinderkit

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
// INTENTIONAL ERROR #1: Import non-existent class for FlyCI Wingman testing
import com.fake.library.NonExistentClass

/**
 * Main activity demonstrating LeakCanary integration and memory leak detection.
 */
class MainActivity : AppCompatActivity() {
    
    private lateinit var statusTextView: TextView
    private lateinit var leakyActivityButton: Button
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        
        statusTextView = findViewById(R.id.statusTextView)
        leakyActivityButton = findViewById(R.id.leakyActivityButton)
        
        statusTextView.text = "SharkLeakFinderKit initialized.\nLeakCanary is monitoring for memory leaks."
        
        leakyActivityButton.setOnClickListener {
            startActivity(Intent(this, LeakyActivity::class.java))
        }
        
        // INTENTIONAL ERROR #2: Call to non-existent method for FlyCI Wingman testing
        triggerFakeCrash()
    }
}
