package com.Ayoub.Usertaxista

import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.webkit.WebView
import androidx.webkit.JavaScriptExecutionWorld
import androidx.webkit.JavaScriptReplyProxy
import androidx.webkit.ScriptHandler
import androidx.webkit.WebMessageCompat
import androidx.webkit.WebViewCompat
import androidx.webkit.WebViewFeature
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.webviewflutter.WebViewFlutterAndroidExternalApi
import org.json.JSONObject

/**
 * Smart Fill: puts one saved card into the bank's payment form in one tap.
 *
 * The bank's card form lives in a cross-origin iframe the page around it can never reach. This host
 * can: it injects a script into every frame whose origin EXACTLY matches the allow-list
 * (`addJavaScriptOnEvent` at document start, in an isolated JavaScript world the page's own scripts
 * cannot see) and opens a web-message channel for those same origins. The script reports only
 * "a card form is on screen"; native code then answers THAT frame's message - through its own reply
 * proxy, so no other frame can receive it - after the customer's tap, and forgets the card. Where the
 * WebView cannot do frame-scoped injection in an isolated world, install() says so and the app keeps
 * its classic copy helper. The CVV never enters here.
 */
class CardFillBridge(private val engine: FlutterEngine, private val channel: MethodChannel) {
    private class Session(
        val id: Long,
        val webView: WebView,
        val origins: Set<String>,
        val world: JavaScriptExecutionWorld,
        val script: ScriptHandler,
    ) {
        var ready: JavaScriptReplyProxy? = null
        var pending: MethodChannel.Result? = null
        var timeout: Runnable? = null
    }

    private val sessions = HashMap<Long, Session>()
    private val main = Handler(Looper.getMainLooper())

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        val id = (call.argument<Number>("webViewId"))?.toLong()
        if (id == null) {
            result.success(if (call.method == "install") false else mapOf("ok" to false, "reason" to "unsupported"))
            return
        }
        when (call.method) {
            "install" -> result.success(install(id, call.argument<String>("script"), call.argument<List<String>>("origins")))
            "fill" -> fill(id, call, result)
            "dispose" -> { dispose(id); result.success(null) }
            else -> result.notImplemented()
        }
    }

    private fun install(id: Long, script: String?, origins: List<String>?): Boolean {
        if (script == null || origins.isNullOrEmpty()) return false
        val webView = WebViewFlutterAndroidExternalApi.getWebView(engine, id) ?: return false
        // Exact frame-scoped injection, in an isolated world, or nothing at all.
        if (!WebViewFeature.isFeatureSupported(WebViewFeature.WEB_MESSAGE_LISTENER) ||
            !WebViewFeature.isFeatureSupported(WebViewFeature.DOCUMENT_START_SCRIPT) ||
            !WebViewFeature.isFeatureSupported(WebViewFeature.JS_INJECTION_IN_FRAME_AND_WORLD)
        ) return false
        val rules = origins.toSet()
        if (rules.any { it == "*" || !it.startsWith("https://") && !it.startsWith("http://") }) return false
        dispose(id)
        return try {
            val world = JavaScriptExecutionWorld("taxista-card-fill", webView)
            val handler = WebViewCompat.addJavaScriptOnEvent(webView, script, WebViewCompat.INJECTION_EVENT_DOCUMENT_START, rules, world)
            val session = Session(id, webView, rules, world, handler)
            WebViewCompat.addWebMessageListener(webView, "taxistaFill", rules, world) { _, message, sourceOrigin, _, reply ->
                onMessage(session, message, sourceOrigin, reply)
            }
            sessions[id] = session
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun originOf(uri: Uri): String {
        val scheme = uri.scheme ?: return ""
        val host = uri.host ?: return ""
        val port = if (uri.port != -1) uri.port else if (scheme == "https") 443 else 80
        return "$scheme://$host:$port"
    }

    private fun normalized(origin: String): String {
        val uri = Uri.parse(origin)
        return originOf(uri)
    }

    private fun onMessage(session: Session, message: WebMessageCompat, sourceOrigin: Uri, reply: JavaScriptReplyProxy) {
        // Native re-checks who is talking: only an approved origin's frame counts.
        val approved = session.origins.map { normalized(it) }
        if (originOf(sourceOrigin) !in approved) return
        val data = message.data ?: return
        val body = try { JSONObject(data) } catch (e: Exception) { return }
        when (body.optString("t")) {
            "ready" -> { session.ready = reply; emit(session.id, "ready") }
            "gone" -> { session.ready = null; emit(session.id, "gone") }
            "result" -> finish(session, body.optJSONObject("r"))
        }
    }

    private fun emit(id: Long, state: String) {
        main.post { channel.invokeMethod("state", mapOf("webViewId" to id.toInt(), "state" to state)) }
    }

    private fun fill(id: Long, call: MethodCall, result: MethodChannel.Result) {
        val session = sessions[id]
        val frame = session?.ready
        if (session == null || frame == null || session.pending != null) {
            result.success(mapOf("ok" to false, "reason" to "no_ready_frame"))
            return
        }
        // Delivered once, as a message to the verified frame only; never in a URL, storage, log or global.
        val payload = JSONObject()
            .put("op", "fill")
            .put("pan", call.argument<String>("pan") ?: "")
            .put("exp", call.argument<String>("exp") ?: "")
            .put("name", call.argument<String>("name") ?: "")
            .put("terms", call.argument<Boolean>("terms") ?: false)
        session.pending = result
        val giveUp = Runnable { finish(session, null) }
        session.timeout = giveUp
        main.postDelayed(giveUp, 10_000)
        try {
            frame.postMessage(payload.toString())
        } catch (e: Exception) {
            finish(session, null)
        }
    }

    private fun finish(session: Session, outcome: JSONObject?) {
        val result = session.pending ?: return
        session.pending = null
        session.timeout?.let { main.removeCallbacks(it) }
        session.timeout = null
        // Hand back labels only, whatever the page context returned.
        val clean = HashMap<String, Any>()
        clean["ok"] = outcome?.optBoolean("ok", false) ?: false
        if (outcome == null) clean["reason"] = "no_ready_frame"
        for (key in listOf("pan", "exp", "name", "terms", "reason")) {
            val text = outcome?.optString(key, "") ?: ""
            if (text.isNotEmpty()) clean[key] = text
        }
        result.success(clean)
    }

    private fun dispose(id: Long) {
        val session = sessions.remove(id) ?: return
        session.timeout?.let { main.removeCallbacks(it) }
        try {
            WebViewCompat.removeWebMessageListener(session.webView, session.world, "taxistaFill")
            session.script.remove()
        } catch (e: Exception) { }
    }

    companion object {
        fun register(engine: FlutterEngine) {
            val channel = MethodChannel(engine.dartExecutor.binaryMessenger, "taxista/card_fill")
            val bridge = CardFillBridge(engine, channel)
            channel.setMethodCallHandler { call, result -> bridge.handle(call, result) }
        }
    }
}
