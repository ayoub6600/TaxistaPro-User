package com.Ayoub.Usertaxista

import android.media.AudioManager
import android.media.ToneGenerator
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * What the caller hears, with the phone's own telephone tones (425 Hz, the European standard
 * used in Libya and Egypt) on the call's audio stream:
 *  - connecting: a short "pip" every 2 s while the call is on its way to the other phone;
 *  - ringback:   the long ring (1 s on, 4 s off) once the other phone really rings;
 *  - busy:       declined or no answer;
 *  - ended:      the other side hung up (three falling tones);
 *  - failed:     the network dropped the call.
 */
object CallTones {
    private val main = Handler(Looper.getMainLooper())
    private var generator: ToneGenerator? = null
    private var looping: Runnable? = null

    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, "taxista/call_tones").setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    play(call.argument<String>("tone") ?: "")
                    result.success(null)
                }
                "stop" -> {
                    stop()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun tones(): ToneGenerator? {
        if (generator == null) {
            generator = try {
                ToneGenerator(AudioManager.STREAM_VOICE_CALL, 70)
            } catch (e: RuntimeException) {
                null
            }
        }
        return generator
    }

    private fun play(tone: String) {
        stop()
        val g = tones() ?: return
        when (tone) {
            "connecting" -> {
                val pip = object : Runnable {
                    override fun run() {
                        g.startTone(ToneGenerator.TONE_SUP_PIP, 260)
                        main.postDelayed(this, 2000)
                    }
                }
                looping = pip
                main.post(pip)
            }
            "ringback" -> g.startTone(ToneGenerator.TONE_SUP_RINGTONE)
            "busy" -> g.startTone(ToneGenerator.TONE_SUP_BUSY, 2400)
            "ended" -> g.startTone(ToneGenerator.TONE_CDMA_CALLDROP_LITE, 1200)
            "failed" -> g.startTone(ToneGenerator.TONE_SUP_CONGESTION, 1800)
        }
    }

    private fun stop() {
        looping?.let { main.removeCallbacks(it) }
        looping = null
        try {
            generator?.stopTone()
        } catch (_: RuntimeException) {
        }
    }
}
