package com.example.bus_booking
import android.os.Build


import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object ArcOverlayChannel {

    private const val CHANNEL = "arc_overlay"

    fun register(context: Context, flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            if (call.method == "startOverlay") {
                if (!Settings.canDrawOverlays(context)) {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:${context.packageName}")
                    )
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(intent)
                    result.success("permission_required")
                    return@setMethodCallHandler
                }

                // ✅ Permission already granted → safe to start service
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(
                        Intent(context, ArcOverlayService::class.java)
                    )
                } else {
                    context.startService(
                        Intent(context, ArcOverlayService::class.java)
                    )
                }

                result.success("service_started")

                        }
                    }
    }
}
