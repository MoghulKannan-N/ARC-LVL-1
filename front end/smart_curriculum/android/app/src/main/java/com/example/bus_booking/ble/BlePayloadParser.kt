package com.example.bus_booking.ble

import android.util.Log
import java.nio.ByteBuffer
import java.util.UUID

/**
 * Parses manufacturer data payloads used by the attendance system.
 *
 * Exact format (MUST match):
 * [marker:1][sessionId:16]
 *
 * marker:
 *   0x01 = TEACHER
 *   0x02 = RELAY
 */
object BlePayloadParser {

    data class Payload(
        val marker: Byte,
        val sessionId: UUID
    )

    fun parse(manufacturerData: ByteArray?): Payload? {
        // Enforce exact payload size
        if (manufacturerData == null || manufacturerData.size != 17) {
            return null
        }

        val marker = manufacturerData[0]

        // Enforce valid marker values only
        if (marker != 0x01.toByte() && marker != 0x02.toByte()) {
            return null
        }

        return try {
            val uuidBytes = manufacturerData.copyOfRange(1, 17)
            val buffer = ByteBuffer.wrap(uuidBytes)
            val msb = buffer.long
            val lsb = buffer.long
            Payload(marker, UUID(msb, lsb))
        } catch (e: Exception) {
            Log.w("BlePayloadParser", "Failed to parse BLE payload: ${e.message}")
            null
        }
    }
}
