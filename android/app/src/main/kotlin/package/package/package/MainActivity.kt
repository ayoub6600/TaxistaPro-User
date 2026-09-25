package com.Ayoub.Usertaxista

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import android.net.Uri
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File


class MainActivity: FlutterFragmentActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Optional "scan card": on-device text recognition with ML Kit's bundled
        // Latin model (no network, no download). The photo is read from the path
        // Dart passes and deleted by Dart straight afterwards.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "taxista/card_ocr")
            .setMethodCallHandler { call, result ->
                val path = call.argument<String>("path")
                if (call.method != "recognize" || path == null) {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    val image = InputImage.fromFilePath(this, Uri.fromFile(File(path)))
                    val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)
                    recognizer.process(image)
                        .addOnSuccessListener { text ->
                            result.success(text.textBlocks.flatMap { block -> block.lines.map { it.text } })
                            recognizer.close()
                        }
                        .addOnFailureListener {
                            result.error("ocr_failed", "Text recognition failed", null)
                            recognizer.close()
                        }
                } catch (e: Exception) {
                    result.error("ocr_failed", "Text recognition failed", null)
                }
            }
    }
}
