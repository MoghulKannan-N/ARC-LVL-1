package com.example.bus_booking

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build

import com.example.bus_booking.R
import android.app.Service
import android.content.Intent
import android.graphics.PixelFormat
import android.os.IBinder
import android.view.*
import android.widget.ImageView

class ArcOverlayService : Service() {

    private lateinit var windowManager: WindowManager
    private lateinit var overlayView: View

    override fun onCreate() {
        super.onCreate()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "arc_overlay_channel"

            val channel = NotificationChannel(
                channelId,
                "ARC Overlay",
                NotificationManager.IMPORTANCE_LOW
            )

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)

            val notification = Notification.Builder(this, channelId)
                .setContentTitle("ARC Overlay Active")
                .setContentText("Stats overlay is running")
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .build()

            startForeground(1001, notification)
        }


        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        overlayView = LayoutInflater.from(this)
            .inflate(R.layout.arc_overlay_layout, null)

        // 🔹 BIG DEFAULT SIZE
        val params = WindowManager.LayoutParams(
            (resources.displayMetrics.widthPixels * 0.85).toInt(),
            (resources.displayMetrics.heightPixels * 0.55).toInt(),
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE,
            PixelFormat.TRANSLUCENT
        )

        params.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
        params.y = 120

        windowManager.addView(overlayView, params)

        // ================= DRAG LOGIC =================
        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f

        overlayView.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params.x
                    initialY = params.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    true
                }

                MotionEvent.ACTION_MOVE -> {
                    params.x = initialX + (event.rawX - initialTouchX).toInt()
                    params.y = initialY + (event.rawY - initialTouchY).toInt()
                    windowManager.updateViewLayout(overlayView, params)
                    true
                }

                else -> false
            }
        }

        // ================= RESIZE LOGIC =================
        var expanded = true

        overlayView.findViewById<ImageView>(R.id.resizeBtn)
            .setOnClickListener {
                expanded = !expanded
                if (expanded) {
                    params.width = (resources.displayMetrics.widthPixels * 0.85).toInt()
                    params.height = (resources.displayMetrics.heightPixels * 0.55).toInt()
                } else {
                    params.width = (resources.displayMetrics.widthPixels * 0.45).toInt()
                    params.height = (resources.displayMetrics.heightPixels * 0.30).toInt()
                }
                windowManager.updateViewLayout(overlayView, params)
            }

        // ================= DRAG-TO-RESIZE LOGIC =================
        var initialWidth = params.width
        var initialHeight = params.height
        var resizeInitialX = 0f
        var resizeInitialY = 0f
        var isResizing = false

        overlayView.findViewById<ImageView>(R.id.resizeHandle)
            .setOnTouchListener { _, event ->
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        isResizing = true
                        resizeInitialX = event.rawX
                        resizeInitialY = event.rawY
                        initialWidth = params.width
                        initialHeight = params.height
                        true
                    }

                    MotionEvent.ACTION_MOVE -> {
                        if (isResizing) {
                            val deltaX = event.rawX - resizeInitialX
                            val deltaY = event.rawY - resizeInitialY

                            val newWidth = (initialWidth + deltaX.toInt()).coerceIn(200, resources.displayMetrics.widthPixels)
                            val newHeight = (initialHeight + deltaY.toInt()).coerceIn(150, resources.displayMetrics.heightPixels)

                            params.width = newWidth
                            params.height = newHeight
                            windowManager.updateViewLayout(overlayView, params)
                        }
                        true
                    }

                    MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                        isResizing = false
                        true
                    }

                    else -> false
                }
            }

        // ================= CLOSE BUTTON =================
        overlayView.findViewById<ImageView>(R.id.closeBtn)
            .setOnClickListener { stopSelf() }
    }

    override fun onDestroy() {
        super.onDestroy()
        windowManager.removeView(overlayView)
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
