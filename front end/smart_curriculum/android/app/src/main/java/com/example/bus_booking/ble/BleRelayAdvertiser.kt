package com.example.bus_booking.ble

import android.Manifest
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import java.nio.ByteBuffer
import java.util.UUID

/**
 * Advertises a relay payload [marker=0x02][sessionId:16] for 20s.
 * Ensures relay happens only once per sessionId (persisted across restarts).
 */
class BleRelayAdvertiser(private val context: Context) {

    private val prefs =
        context.getSharedPreferences("attendance_prefs", Context.MODE_PRIVATE)
    private val PREF_KEY_RELAYS = "relayed_sessions"

    private val relayed = HashSet<UUID>()
    private val handler = Handler(Looper.getMainLooper())
    private var activeCallback: AdvertiseCallback? = null

    companion object {
        private const val MANUFACTURER_ID = 0xFFFF
        private const val RELAY_MARKER: Byte = 0x02
        private const val RELAY_DURATION_MS = 20_000L
    }

    init {
        // Load persisted relayed sessions
        prefs.getStringSet(PREF_KEY_RELAYS, emptySet())?.forEach {
            try {
                relayed.add(UUID.fromString(it))
            } catch (_: Exception) {
            }
        }
    }

    fun startRelay(
        sessionId: UUID,
        onStarted: () -> Unit,
        onFailure: (code: String, msg: String) -> Unit
    ) {
        if (relayed.contains(sessionId)) {
            onFailure("ALREADY_RELAYED", "Session already relayed")
            return
        }

        // 🔐 REQUIRED: Runtime permission guard (Android 12+)
        if (ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.BLUETOOTH_ADVERTISE
            ) != android.content.pm.PackageManager.PERMISSION_GRANTED
        ) {
            onFailure(
                "MISSING_PERMISSION",
                "BLUETOOTH_ADVERTISE permission not granted"
            )
            return
        }

        val advertiser =
            (context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager)
                .adapter?.bluetoothLeAdvertiser
                ?: run {
                    onFailure("NO_ADVERTISER", "BLE advertiser unavailable")
                    return
                }

        val payload = ByteBuffer.allocate(17).apply {
            put(RELAY_MARKER)
            putLong(sessionId.mostSignificantBits)
            putLong(sessionId.leastSignificantBits)
        }.array()

        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_ULTRA_LOW)
            .setConnectable(false)
            .build()

        val data = AdvertiseData.Builder()
            .addManufacturerData(MANUFACTURER_ID, payload)
            .setIncludeDeviceName(false)
            .build()

        val callback = object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings) {
                activeCallback = this
                relayed.add(sessionId)

                // Persist only new sessionId
                val updated =
                    prefs.getStringSet(PREF_KEY_RELAYS, emptySet())!!.toMutableSet()
                updated.add(sessionId.toString())
                prefs.edit().putStringSet(PREF_KEY_RELAYS, updated).apply()

                handler.postDelayed({ stopRelay() }, RELAY_DURATION_MS)

                onStarted()
            }

            override fun onStartFailure(errorCode: Int) {
                activeCallback = null
                onFailure("ADVERTISE_FAILED", "Advertising failed: $errorCode")
            }
        }

        try {
            advertiser.startAdvertising(settings, data, callback)
        } catch (e: Exception) {
            onFailure("ADVERTISE_ERROR", e.message ?: "Unknown advertise error")
        }
    }

    private fun stopRelay() {
        val advertiser =
            (context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager)
                .adapter?.bluetoothLeAdvertiser
                ?: return

        try {
            if (activeCallback != null &&
                ContextCompat.checkSelfPermission(
                    context,
                    Manifest.permission.BLUETOOTH_ADVERTISE
                ) == android.content.pm.PackageManager.PERMISSION_GRANTED
            ) {
                advertiser.stopAdvertising(activeCallback!!)
            }
        } catch (e: Exception) {
            Log.w("BleRelayAdvertiser", "stopAdvertising exception: ${e.message}")
        } finally {
            activeCallback = null
        }
    }
}
