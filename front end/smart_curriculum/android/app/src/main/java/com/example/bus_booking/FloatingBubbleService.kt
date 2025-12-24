package com.example.bus_booking

import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.Build
import android.os.IBinder
import android.view.*
import android.widget.ImageView
import kotlin.math.sqrt
import kotlin.math.abs


class FloatingBubbleService : Service() {

    private lateinit var windowManager: WindowManager
    private lateinit var bubbleView: View
    private lateinit var trashView: View
    private lateinit var bubbleParams: WindowManager.LayoutParams
    private lateinit var trashParams: WindowManager.LayoutParams

    override fun onCreate() {
        super.onCreate()

        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        // ---------------- Bubble ----------------
        bubbleView = LayoutInflater.from(this).inflate(R.layout.floating_bubble, null)

        bubbleParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )

        bubbleParams.gravity = Gravity.TOP or Gravity.START
        bubbleParams.x = 0
        bubbleParams.y = 300

        windowManager.addView(bubbleView, bubbleParams)

        val bubbleIcon = bubbleView.findViewById<ImageView>(R.id.bubbleIcon)

        // ---------------- Trash ----------------
        trashView = LayoutInflater.from(this).inflate(R.layout.bubble_trash, null)

        trashParams = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )

        trashParams.gravity = Gravity.BOTTOM or Gravity.CENTER_HORIZONTAL
        trashParams.y = 120

        trashView.visibility = View.GONE
        windowManager.addView(trashView, trashParams)

        // ---------------- Touch Logic ----------------
        var startX = 0
        var startY = 0
        var touchX = 0f
        var touchY = 0f
        var isDragging = false

        bubbleIcon.setOnTouchListener { _, event ->
            when (event.action) {

                MotionEvent.ACTION_DOWN -> {
                    startX = bubbleParams.x
                    startY = bubbleParams.y
                    touchX = event.rawX
                    touchY = event.rawY
                    isDragging = false
                    true
                }

                MotionEvent.ACTION_MOVE -> {
                    val dx = event.rawX - touchX
                    val dy = event.rawY - touchY

                    if (abs(dx) > 10 || abs(dy) > 10) {
                        isDragging = true
                    }

                    bubbleParams.x = startX + dx.toInt()
                    bubbleParams.y = startY + dy.toInt()
                    windowManager.updateViewLayout(bubbleView, bubbleParams)

                    // show trash only while dragging
                    trashView.visibility = View.VISIBLE

                    // 🔥 close if near trash
                    if (isNearTrash(bubbleParams, bubbleView, trashView)) {
                        stopService(Intent(this, ArcOverlayService::class.java))
                        stopSelf()
                        android.os.Process.killProcess(android.os.Process.myPid())
                    }
                    true
                }

                MotionEvent.ACTION_UP -> {
                    trashView.visibility = View.GONE

                    // 🟦 TAP → restore overlay
                    if (!isDragging) {
                        startOverlayAgain()
                    }
                    true
                }

                else -> false
            }
        }

    }

    private fun startOverlayAgain() {
        val intent = Intent(this, ArcOverlayService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        stopSelf()
    }

    private fun isNearTrash(
        bubbleParams: WindowManager.LayoutParams,
        bubbleView: View,
        trashView: View
    ): Boolean {

        val bubbleCenterX = bubbleParams.x + bubbleView.width / 2
        val bubbleCenterY = bubbleParams.y + bubbleView.height / 2

        val trashCenterX = resources.displayMetrics.widthPixels / 2
        val trashCenterY =
            resources.displayMetrics.heightPixels - trashView.height - 120

        val dx = bubbleCenterX - trashCenterX
        val dy = bubbleCenterY - trashCenterY

        val distance = sqrt((dx * dx + dy * dy).toDouble())

        return distance < 180   // 🎯 hit radius
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            windowManager.removeView(bubbleView)
            windowManager.removeView(trashView)
        } catch (_: Exception) {}
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
