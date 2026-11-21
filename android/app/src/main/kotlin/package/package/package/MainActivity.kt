package com.Ayoub.Usertaxista

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine


class MainActivity: FlutterFragmentActivity() {
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        CardFillBridge.register(flutterEngine)
        CallTones.register(flutterEngine)

        // Card scanner: on-device text recognition (ML Kit's bundled model). See CardOcr.kt.
        CardOcr.register(flutterEngine.dartExecutor.binaryMessenger, applicationContext)
    }
}
