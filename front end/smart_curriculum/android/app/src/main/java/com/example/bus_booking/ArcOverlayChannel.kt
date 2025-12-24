package com.example.bus_booking

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object ArcOverlayChannel {

    private const val CHANNEL = "arc_overlay"

    // 🔥 Activity instead of Context
    fun register(activity: Activity, flutterEngine: FlutterEngine) {

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            if (call.method == "startOverlay") {

                // 1️⃣ Check overlay permission
                if (!Settings.canDrawOverlays(activity)) {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:${activity.packageName}")
                    )
                    activity.startActivity(intent)
                    result.success("permission_required")
                    return@setMethodCallHandler
                }

                // 2️⃣ Start overlay service
                val serviceIntent = Intent(activity, ArcOverlayService::class.java)

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    activity.startForegroundService(serviceIntent)
                } else {
                    activity.startService(serviceIntent)
                }

                // 3️⃣ 🔥 SEND APP TO BACKGROUND (THIS WAS MISSING)
                activity.moveTaskToBack(true)

                result.success("overlay_started")
            }
        }
    }
}
