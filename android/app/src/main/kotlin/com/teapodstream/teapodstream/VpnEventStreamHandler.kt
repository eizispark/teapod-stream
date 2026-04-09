package com.teapodstream.teapodstream

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

/**
 * Singleton EventChannel stream handler.
 * The VpnService calls sendEvent() to push events to Flutter.
 */
object VpnEventStreamHandler : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    fun sendEvent(event: Map<String, Any?>) {
        handler.post {
            try {
                eventSink?.success(event)
            } catch (e: Exception) {
                android.util.Log.e("VpnEventStreamHandler", "Error sending event: ${e.message}")
            }
        }
    }

    fun sendStateEvent(state: String) {
        sendEvent(mapOf("type" to "state", "value" to state))
    }

    fun sendLogEvent(level: String, message: String) {
        sendEvent(mapOf("type" to "log", "level" to level, "message" to message))
    }

    fun sendStatsEvent(
        upload: Long,
        download: Long,
        uploadSpeed: Long,
        downloadSpeed: Long,
    ) {
        sendEvent(
            mapOf(
                "type" to "stats",
                "upload" to upload,
                "download" to download,
                "uploadSpeed" to uploadSpeed,
                "downloadSpeed" to downloadSpeed,
            )
        )
    }
}
