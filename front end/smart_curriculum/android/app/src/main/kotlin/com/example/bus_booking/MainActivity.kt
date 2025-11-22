package com.example.bus_booking

import android.Manifest
import android.bluetooth.*
import android.bluetooth.le.*
import android.os.*
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.nio.charset.StandardCharsets
import java.util.*

class MainActivity : FlutterActivity() {

    private val CHANNEL = "student_ble"
    private val CLASS_A_UUID =
        UUID.fromString("00001111-0000-1000-8000-00805F9B34FB")

    private var scanner: BluetoothLeScanner? = null
    private var scanCallback: ScanCallback? = null

    private var hasReplied = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scanForTeacher" -> startScan(result)
                    else -> result.notImplemented()
                }
            }
    }

    // SAFE replyOnlyOnce helper
    private fun replyOnce(
        result: MethodChannel.Result,
        successValue: String? = null,
        errorCode: String? = null,
        errorMessage: String? = null
    ) {
        if (hasReplied) return
        hasReplied = true

        if (errorCode != null) {
            result.error(errorCode, errorMessage, null)
        } else {
            result.success(successValue)
        }
    }

    private fun startScan(result: MethodChannel.Result) {

        hasReplied = false   // reset flag each scan call

        // Permission check
        if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.BLUETOOTH_SCAN
            ) != android.content.pm.PackageManager.PERMISSION_GRANTED
        ) {
            replyOnce(
                result,
                errorCode = "PERMISSION",
                errorMessage = "Missing scan permission"
            )
            return
        }

        val manager = getSystemService(BLUETOOTH_SERVICE) as BluetoothManager
        val adapter = manager.adapter ?: run {
            replyOnce(
                result,
                errorCode = "NO_BT",
                errorMessage = "Bluetooth Off"
            )
            return
        }

        scanner = adapter.bluetoothLeScanner
        if (scanner == null) {
            replyOnce(
                result,
                errorCode = "NO_SCANNER",
                errorMessage = "BLE scanner unavailable"
            )
            return
        }

        val filters = listOf(
            ScanFilter.Builder()
                .setServiceUuid(ParcelUuid(CLASS_A_UUID))
                .build()
        )

        val settings = ScanSettings.Builder()
            .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
            .build()

        scanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, scanResult: ScanResult) {

                val manu = scanResult.scanRecord?.manufacturerSpecificData?.get(0xFFFF)
                val marker = manu?.toString(StandardCharsets.UTF_8)
                val rssi = scanResult.rssi

                if (marker == "TEACHER" && rssi > -80) {
                    scanner?.stopScan(this)
                    replyOnce(result, successValue = "FOUND")
                }
            }
        }

        scanner!!.startScan(filters, settings, scanCallback!!)

        // Timeout after 8s
        Handler(Looper.getMainLooper()).postDelayed({
            scanner?.stopScan(scanCallback!!)
            replyOnce(result, successValue = "NOT_FOUND")
        }, 8000)
    }
}
