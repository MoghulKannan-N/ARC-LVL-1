package com.example.bus_booking

import android.Manifest
import android.bluetooth.*
import android.bluetooth.le.*
import android.content.Intent
import android.location.LocationManager
import android.os.*
import android.provider.Settings
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.nio.charset.StandardCharsets
import java.util.*

class MainActivity : FlutterActivity() {

    private val CHANNEL = "student_ble"
    private val CLASS_A_UUID = UUID.fromString("00001111-0000-1000-8000-00805F9B34FB")
    private val MANUFACTURER_ID = 0xFFFF
    private val TEACHER_MARKER = "TEACHER"
    private val RELAY_MARKER = "RELAY"
    private val RSSI_THRESHOLD = -95
    private val RSSI_SAMPLE_COUNT = 5
    private val rssiSamples = ArrayList<Int>(RSSI_SAMPLE_COUNT)

    private var scanner: BluetoothLeScanner? = null
    private var scanCallback: ScanCallback? = null
    private var advertiser: BluetoothLeAdvertiser? = null
    private var advertiseCallback: AdvertiseCallback? = null

    private var hasReplied = false
    private val handler = Handler(Looper.getMainLooper())

    private val SCAN_TIMEOUT_MS = 10_000L
    private val REBROADCAST_WINDOW_MS = 15_000L
    private val TEACHER_BEACON_DURATION_MS = 120_000L
    private val PERMISSION_REQUEST_CODE = 1001

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        requestAllPermissions()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scanForTeacher" -> startScan(result)
                    "startTeacherBeacon" -> startTeacherBeacon(result)
                    else -> result.notImplemented()
                }
            }
    }

    /** Permission request setup */
    private fun requestAllPermissions() {
        val permissions = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            permissions.addAll(
                listOf(
                    Manifest.permission.BLUETOOTH_SCAN,
                    Manifest.permission.BLUETOOTH_CONNECT,
                    Manifest.permission.BLUETOOTH_ADVERTISE
                )
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                permissions.add(Manifest.permission.NEARBY_WIFI_DEVICES)
            }
        } else {
            permissions.addAll(
                listOf(
                    Manifest.permission.ACCESS_FINE_LOCATION,
                    Manifest.permission.ACCESS_COARSE_LOCATION
                )
            )
        }

        val notGranted = permissions.filter {
            ContextCompat.checkSelfPermission(this, it) !=
                android.content.pm.PackageManager.PERMISSION_GRANTED
        }

        if (notGranted.isNotEmpty()) {
            requestPermissions(notGranted.toTypedArray(), PERMISSION_REQUEST_CODE)
        }
    }

    private fun replyOnce(
        result: MethodChannel.Result,
        successValue: String? = null,
        errorCode: String? = null,
        errorMessage: String? = null
    ) {
        if (hasReplied) return
        hasReplied = true
        if (errorCode != null) result.error(errorCode, errorMessage, null)
        else result.success(successValue)
    }

    /** ================= START REBROADCAST ================= */
    private fun startRebroadcast(onSuccess: () -> Unit, onFailure: (code: String, msg: String) -> Unit) {
        val manager = getSystemService(BLUETOOTH_SERVICE) as BluetoothManager
        val adapter = manager.adapter ?: run {
            onFailure("NO_BT", "Bluetooth Off")
            return
        }

        advertiser = adapter.bluetoothLeAdvertiser
        if (advertiser == null) {
            onFailure("NO_ADVERTISER", "BLE advertiser unavailable")
            return
        }

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_ULTRA_LOW)
            .setConnectable(false)
            .build()

        val data = AdvertiseData.Builder()
            .addServiceUuid(ParcelUuid(CLASS_A_UUID))
            .addManufacturerData(MANUFACTURER_ID, RELAY_MARKER.toByteArray(StandardCharsets.UTF_8))
            .setIncludeDeviceName(false)
            .build()

        advertiseCallback = object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
                handler.postDelayed({ stopRebroadcast() }, REBROADCAST_WINDOW_MS)
                onSuccess()
            }

            override fun onStartFailure(errorCode: Int) {
                onFailure("ADVERTISE_FAILED", "Advertising failed: $errorCode")
            }
        }

        try {
            advertiser!!.startAdvertising(settings, data, advertiseCallback!!)
        } catch (e: Exception) {
            onFailure("ADVERTISE_ERROR", e.message ?: "Unknown advertise error")
        }
    }

    private fun stopRebroadcast() {
        try {
            if (advertiser != null && advertiseCallback != null &&
                ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_ADVERTISE)
                == android.content.pm.PackageManager.PERMISSION_GRANTED
            ) {
                advertiser?.stopAdvertising(advertiseCallback!!)
            }
        } catch (e: Exception) {
            Log.w("MainActivity", "stopAdvertising exception: ${e.message}")
        } finally {
            advertiseCallback = null
        }
    }

    /** ================= SCAN FOR TEACHER ================= */
    private fun startScan(result: MethodChannel.Result) {
        hasReplied = false
        rssiSamples.clear()

        val manager = getSystemService(BLUETOOTH_SERVICE) as BluetoothManager
        val adapter = manager.adapter ?: run {
            replyOnce(result, errorCode = "NO_BT", errorMessage = "Bluetooth adapter not found")
            return
        }

        if (!adapter.isEnabled) {
            startActivity(Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE))
            replyOnce(result, errorCode = "BT_OFF", errorMessage = "Bluetooth is off")
            return
        }

        val locationManager = getSystemService(LOCATION_SERVICE) as LocationManager
        val isLocationEnabled =
            locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        if (!isLocationEnabled) {
            startActivity(Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS))
            replyOnce(result, errorCode = "LOC_OFF", errorMessage = "Location is off")
            return
        }

        scanner = adapter.bluetoothLeScanner
        if (scanner == null) {
            replyOnce(result, errorCode = "NO_SCANNER", errorMessage = "BLE scanner unavailable")
            return
        }

        val filters = listOf(ScanFilter.Builder().setServiceUuid(ParcelUuid(CLASS_A_UUID)).build())
        val settings = ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build()

        scanCallback = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, scanResult: ScanResult) {
                val manu = scanResult.scanRecord?.manufacturerSpecificData?.get(MANUFACTURER_ID)
                val marker = manu?.toString(StandardCharsets.UTF_8) ?: return
                if (marker != TEACHER_MARKER && marker != RELAY_MARKER) return

                val rssi = scanResult.rssi
                rssiSamples.add(rssi)
                if (rssiSamples.size < RSSI_SAMPLE_COUNT) return

                val avg = rssiSamples.sum() / rssiSamples.size
                rssiSamples.clear()

                if (avg < RSSI_THRESHOLD) return

                stopScanSafely()
                startRebroadcast(
                    onSuccess = { replyOnce(result, successValue = "FOUND_AND_RELAYING") },
                    onFailure = { code, msg -> replyOnce(result, errorCode = code, errorMessage = msg) }
                )
            }

            override fun onScanFailed(errorCode: Int) {
                replyOnce(result, errorCode = "SCAN_FAILED", errorMessage = "Scan failed: $errorCode")
            }
        }

        scanner!!.startScan(filters, settings, scanCallback!!)
        handler.postDelayed({
            stopScanSafely()
            replyOnce(result, successValue = "NOT_FOUND")
        }, SCAN_TIMEOUT_MS)
    }

    private fun stopScanSafely() {
        try {
            if (scanner != null && scanCallback != null &&
                ContextCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_SCAN)
                == android.content.pm.PackageManager.PERMISSION_GRANTED
            ) {
                scanner?.stopScan(scanCallback!!)
            }
        } catch (e: Exception) {
            Log.w("MainActivity", "stopScan exception: ${e.message}")
        } finally {
            scanCallback = null
        }
    }

    /** ================= TEACHER BEACON ================= */
    private fun startTeacherBeacon(result: MethodChannel.Result) {
        val manager = getSystemService(BLUETOOTH_SERVICE) as BluetoothManager
        val adapter = manager.adapter ?: run {
            result.error("NO_BT", "Bluetooth not available", null)
            return
        }

        if (!adapter.isEnabled) {
            startActivity(Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE))
            result.error("BT_OFF", "Bluetooth is off", null)
            return
        }

        advertiser = adapter.bluetoothLeAdvertiser
        if (advertiser == null) {
            result.error("NO_ADVERTISER", "BLE advertiser unavailable", null)
            return
        }

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_ULTRA_LOW)
            .setConnectable(false)
            .build()

        val data = AdvertiseData.Builder()
            .addServiceUuid(ParcelUuid(CLASS_A_UUID))
            .addManufacturerData(MANUFACTURER_ID, TEACHER_MARKER.toByteArray(StandardCharsets.UTF_8))
            .setIncludeDeviceName(false)
            .build()

        advertiseCallback = object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
                handler.postDelayed({ stopRebroadcast() }, TEACHER_BEACON_DURATION_MS)
                result.success("TEACHER_BEACON_ACTIVE")
            }

            override fun onStartFailure(errorCode: Int) {
                result.error("ADVERTISE_FAILED", "Advertising failed: $errorCode", null)
            }
        }

        advertiser!!.startAdvertising(settings, data, advertiseCallback!!)
    }

    override fun onDestroy() {
        super.onDestroy()
        stopScanSafely()
        stopRebroadcast()
        handler.removeCallbacksAndMessages(null)
    }
}
