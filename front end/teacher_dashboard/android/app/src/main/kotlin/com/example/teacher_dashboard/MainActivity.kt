package com.example.teacher_dashboard   // <-- CHANGE THIS TO YOUR PACKAGE NAME
import android.content.pm.PackageManager
import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.*
import android.os.*
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.nio.charset.StandardCharsets
import java.util.*

class MainActivity : FlutterActivity() {

    private val CHANNEL = "ble_control"
    private val REQUEST_CODE = 2002

    private var advertiser: BluetoothLeAdvertiser? = null
    private var callback: AdvertiseCallback? = null

    private val handler = Handler(Looper.getMainLooper())

    private val CLASS_A_UUID =
        UUID.fromString("00001111-0000-1000-8000-00805F9B34FB")

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->

                when (call.method) {
                    "startNormalSession" -> startNormalSession(result)
                    "stopBroadcast" -> {
                        stopAdvertising()
                        result.success("Stopped")
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun hasPermissions(): Boolean {
        val permissions =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
                arrayOf(
                    Manifest.permission.BLUETOOTH_SCAN,
                    Manifest.permission.BLUETOOTH_CONNECT,
                    Manifest.permission.BLUETOOTH_ADVERTISE
                )
            else arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            )

        for (p in permissions) {
            if (ContextCompat.checkSelfPermission(this, p)
                != PackageManager.PERMISSION_GRANTED
            ) return false
        }
        return true
    }

    private fun startNormalSession(result: MethodChannel.Result) {
        if (!hasPermissions()) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.ACCESS_FINE_LOCATION),
                REQUEST_CODE
            )
            result.error("PERMISSION", "Missing permissions", null)
            return
        }

        val bluetoothManager = getSystemService(BLUETOOTH_SERVICE) as BluetoothManager
        val adapter = bluetoothManager.adapter

        if (adapter == null || !adapter.isEnabled) {
            result.error("NO_BLUETOOTH", "Enable Bluetooth", null)
            return
        }

        advertiser = adapter.bluetoothLeAdvertiser
        if (advertiser == null) {
            result.error("NO_ADVERTISER", "Not supported", null)
            return
        }

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .setConnectable(false)
            .build()

        val data = AdvertiseData.Builder()
            .addServiceUuid(ParcelUuid(CLASS_A_UUID))
            .addManufacturerData(
                0xFFFF,
                "TEACHER".toByteArray(StandardCharsets.UTF_8)
            )
            .setIncludeDeviceName(false)
            .build()

        callback = object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
                result.success("Broadcasting Class A Session")
            }

            override fun onStartFailure(errorCode: Int) {
                result.error("FAIL", "Error: $errorCode", null)
            }
        }

        advertiser!!.startAdvertising(settings, data, callback)

        // auto stop after 30 seconds
        handler.postDelayed({ stopAdvertising() }, 30_000)
    }

    private fun stopAdvertising() {
        try {
            advertiser?.stopAdvertising(callback)
        } catch (e: Exception) {}
    }
}