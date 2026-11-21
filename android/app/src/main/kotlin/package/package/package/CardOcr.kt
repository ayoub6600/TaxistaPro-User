package com.Ayoub.Usertaxista

import android.content.Context
import android.graphics.Rect
import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.Text
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * On-device text recognition for the card scanner: ML Kit's BUNDLED Latin model (shipped in
 * the app, no download, no network). One path for the live camera ("recognizeFrame") and the
 * photo fallback ("recognizeFile").
 *
 * Camera frames arrive as NV21 bytes and are read in memory only: nothing is written to
 * disk, uploaded or logged here. A photo is only read from the path Dart passes (Dart deletes
 * it straight afterwards). Only the recognised lines (with their position, normalised to the
 * upright image, top-left origin) go back to Dart.
 */
object CardOcr {
    private val recognizer by lazy { TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS) }

    fun register(messenger: BinaryMessenger, context: Context) {
        MethodChannel(messenger, "taxista/card_ocr").setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "recognizeFrame" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val width = call.argument<Int>("width") ?: 0
                        val height = call.argument<Int>("height") ?: 0
                        val rotation = call.argument<Int>("rotation") ?: 0
                        val roi = call.argument<List<Double>>("roi") ?: listOf(0.0, 0.0, 1.0, 1.0)
                        if (bytes == null || width <= 0 || height <= 0 || call.argument<String>("format") != "nv21" || bytes.size < width * height) {
                            result.error("bad_frame", "Unsupported frame", null)
                            return@setMethodCallHandler
                        }
                        val luma = averageLuma(bytes, width, height, rotation, roi)
                        val image = InputImage.fromByteArray(bytes, width, height, rotation, InputImage.IMAGE_FORMAT_NV21)
                        val uprightW = if (rotation % 180 == 0) width else height
                        val uprightH = if (rotation % 180 == 0) height else width
                        recognizer.process(image)
                            .addOnSuccessListener { text -> result.success(mapOf("lines" to lines(text, uprightW, uprightH), "luma" to luma)) }
                            .addOnFailureListener { result.success(mapOf("lines" to emptyList<Any>(), "luma" to luma)) }
                    }
                    "recognizeFile" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("bad_file", "No file", null)
                            return@setMethodCallHandler
                        }
                        val image = InputImage.fromFilePath(context, Uri.fromFile(File(path)))
                        recognizer.process(image)
                            .addOnSuccessListener { text -> result.success(mapOf("lines" to lines(text, image.width, image.height))) }
                            .addOnFailureListener { result.success(mapOf("lines" to emptyList<Any>())) }
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("ocr_failed", "Text recognition failed", null)
            }
        }
    }

    private fun lines(text: Text, w: Int, h: Int): List<Map<String, Any>> {
        if (w <= 0 || h <= 0) return emptyList()
        val out = ArrayList<Map<String, Any>>()
        for (block in text.textBlocks) {
            for (line in block.lines) {
                val box: Rect = line.boundingBox ?: continue
                out.add(
                    mapOf(
                        "text" to line.text,
                        "conf" to (line.confidence.toDouble()),
                        "alts" to emptyList<String>(),
                        "box" to listOf(box.left.toDouble() / w, box.top.toDouble() / h, box.width().toDouble() / w, box.height().toDouble() / h),
                    )
                )
            }
        }
        return out
    }

    /** Brightness of the card area from the Y plane, so the screen can suggest the torch. */
    private fun averageLuma(nv21: ByteArray, width: Int, height: Int, rotation: Int, roi: List<Double>): Double {
        if (roi.size != 4) return 0.0
        var total = 0.0
        var count = 0
        for (i in 0 until 16) {
            for (j in 0 until 10) {
                val ux = roi[0] + roi[2] * (i + 0.5) / 16
                val uy = roi[1] + roi[3] * (j + 0.5) / 10
                val (bx, by) = when (((rotation % 360) + 360) % 360) {
                    90 -> Pair(uy, 1 - ux)
                    180 -> Pair(1 - ux, 1 - uy)
                    270 -> Pair(1 - uy, ux)
                    else -> Pair(ux, uy)
                }
                val px = (bx * width).toInt().coerceIn(0, width - 1)
                val py = (by * height).toInt().coerceIn(0, height - 1)
                total += (nv21[py * width + px].toInt() and 0xFF)
                count++
            }
        }
        return if (count > 0) total / count else 0.0
    }
}
