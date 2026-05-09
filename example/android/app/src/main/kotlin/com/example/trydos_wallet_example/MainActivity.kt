package com.example.trydos_wallet_example

import android.view.View
import android.view.WindowManager
import android.graphics.Color
import android.graphics.PixelFormat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.trydos_wallet_example/security"
    private var blackOverlayView: View? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "hideContent" -> {
                        hideContentInBackground()
                        result.success(true)
                    }
                    "showContent" -> {
                        showContentInForeground()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hideContentInBackground() {
        // Set FLAG_SECURE to prevent screenshots and recents preview
        window?.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        
        // Add black overlay view above the content
        if (blackOverlayView == null) {
            blackOverlayView = View(this).apply {
                setBackgroundColor(Color.BLACK)
            }
            
            val params = WindowManager.LayoutParams().apply {
                type = WindowManager.LayoutParams.TYPE_APPLICATION
                format = PixelFormat.OPAQUE
                flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                width = WindowManager.LayoutParams.MATCH_PARENT
                height = WindowManager.LayoutParams.MATCH_PARENT
            }
            
            window?.addContentView(blackOverlayView, params)
        } else {
            blackOverlayView?.visibility = View.VISIBLE
        }
    }

    private fun showContentInForeground() {
        // Remove FLAG_SECURE to allow normal functionality
        window?.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
        
        // Hide black overlay
        blackOverlayView?.visibility = View.GONE
    }

    override fun onPause() {
        super.onPause()
        // Hide sensitive data when app goes to background
        hideContentInBackground()
    }

    override fun onResume() {
        super.onResume()
        // Show app content when app returns to foreground
        showContentInForeground()
    }

    override fun onDestroy() {
        super.onDestroy()
        blackOverlayView = null
    }
}
