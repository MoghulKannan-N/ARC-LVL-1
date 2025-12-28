package com.example.bus_booking.ble

import android.util.Log
import java.util.UUID
import kotlin.collections.ArrayList
import kotlin.collections.HashMap
import kotlin.collections.HashSet

/**
 * Tracks RSSI samples per sessionId within a sliding time window.
 * Computes MEDIAN RSSI and accepts proximity once per session.
 *
 * Accept decision is final.
 * Reject allows retry while the window is active.
 */
class RssiSessionTracker(
    private val windowMs: Long = 15000L,
    private val sampleCount: Int = 3,
    private val thresholdRssi: Int = -75
) {

    private data class Sample(val ts: Long, val rssi: Int)

    private val samples = HashMap<UUID, MutableList<Sample>>()
    private val accepted = HashSet<UUID>()   // only accept is final

    /**
     * Adds an RSSI sample for a session.
     *
     * @return median RSSI if ACCEPTED, null otherwise
     */
    fun addSample(sessionId: UUID, rssi: Int): Int? {
        if (accepted.contains(sessionId)) return null

        val now = System.currentTimeMillis()
        val list = samples.getOrPut(sessionId) { ArrayList() }
        list.add(Sample(now, rssi))

        // Drop stale samples
        list.removeAll { now - it.ts > windowMs }

        // Hard cap to avoid unbounded growth
        if (list.size > sampleCount) {
            list.removeAt(0)
        }

        if (list.size < sampleCount) return null

        // Compute median RSSI
        val median = list.map { it.rssi }.sorted()[list.size / 2]

        return if (median >= thresholdRssi) {
            accepted.add(sessionId)
            samples.remove(sessionId)
            Log.d("RssiSessionTracker", "Session $sessionId ACCEPTED (median=$median)")
            median
        } else {
            // Reject for now, allow retry
            Log.d("RssiSessionTracker", "Session $sessionId REJECTED (median=$median), retry allowed")
            null
        }
    }
}
