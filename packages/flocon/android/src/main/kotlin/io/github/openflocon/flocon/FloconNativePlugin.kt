package io.github.openflocon.flocon

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.util.Base64
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayOutputStream
import kotlin.math.min

/** Reads the app icon and encodes it as a base64 PNG, at most [MAX_SIZE] pixels wide. */
class FloconNativePlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "io.github.openflocon/flocon")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getAppIcon" -> result.success(appIconBase64())
            else -> result.notImplemented()
        }
    }

    private fun appIconBase64(): String? = try {
        val drawable = context.packageManager.getApplicationIcon(context.packageName)
        val width = drawable.intrinsicWidth.takeIf { it > 0 } ?: MAX_SIZE
        val height = drawable.intrinsicHeight.takeIf { it > 0 } ?: MAX_SIZE
        val scale = min(1f, min(MAX_SIZE.toFloat() / width, MAX_SIZE.toFloat() / height))
        val w = (width * scale).toInt().coerceAtLeast(1)
        val h = (height * scale).toInt().coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, w, h)
        drawable.draw(canvas)
        val out = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        Base64.encodeToString(out.toByteArray(), Base64.NO_WRAP)
    } catch (e: Exception) {
        null
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private companion object {
        const val MAX_SIZE = 300
    }
}
