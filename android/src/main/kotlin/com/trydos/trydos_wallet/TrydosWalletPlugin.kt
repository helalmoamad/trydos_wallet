package com.trydos.trydos_wallet

import android.app.Activity
import android.content.Intent
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Native half of the AWS Face Liveness step.
 *
 * Dart drives the whole flow — it opens the KYC session, creates the AWS
 * session and reads the verdict. This side does one thing: present the Amplify
 * UI challenge full screen and say whether it ran.
 *
 * It deliberately knows nothing about the user's token or the Worker's URL:
 * when the SDK needs credentials, the request goes back over the channel and
 * Dart fetches them. Nothing secret is stored here.
 */
class TrydosWalletPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware,
    PluginRegistry.ActivityResultListener {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null

    /** Pending `present` call, answered from [onActivityResult]. */
    private var pendingResult: MethodChannel.Result? = null

    private val main = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
        instance = this
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        if (instance === this) instance = null
        // An engine torn down mid-challenge must not leave Dart waiting.
        finishPending(ERROR_CANCELLED, "Engine detached during the liveness challenge.")
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        activity = binding.activity
        binding.addActivityResultListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) =
        onAttachedToActivity(binding)

    override fun onDetachedFromActivityForConfigChanges() = onDetachedFromActivity()

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
        activity = null
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "isAvailable" -> result.success(true)
            "present" -> present(call, result)
            else -> result.notImplemented()
        }
    }

    private fun present(call: MethodCall, result: MethodChannel.Result) {
        val host = activity
        if (host == null) {
            result.error(ERROR_SETUP, "No activity to present the challenge on.", null)
            return
        }
        if (pendingResult != null) {
            result.error(ERROR_SETUP, "A liveness challenge is already running.", null)
            return
        }

        val sessionId = call.argument<String>("sessionId")
        val region = call.argument<String>("region")
        if (sessionId.isNullOrEmpty() || region.isNullOrEmpty()) {
            result.error(ERROR_SETUP, "sessionId and region are required.", null)
            return
        }

        pendingResult = result
        val intent = Intent(host, FaceLivenessActivity::class.java).apply {
            putExtra(FaceLivenessActivity.EXTRA_SESSION_ID, sessionId)
            putExtra(FaceLivenessActivity.EXTRA_REGION, region)
        }
        host.startActivityForResult(intent, REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false

        val pending = pendingResult ?: return true
        pendingResult = null

        when (resultCode) {
            // The challenge ran. Whether the person passed is AWS's verdict,
            // read by Dart from the result endpoint — not decided here.
            Activity.RESULT_OK -> pending.success(null)
            else -> {
                val code = data?.getStringExtra(FaceLivenessActivity.EXTRA_ERROR_CODE)
                    ?: ERROR_CANCELLED
                val message = data?.getStringExtra(FaceLivenessActivity.EXTRA_ERROR_MESSAGE)
                pending.error(code, message, null)
            }
        }
        return true
    }

    private fun finishPending(code: String, message: String) {
        val pending = pendingResult ?: return
        pendingResult = null
        pending.error(code, message, null)
    }

    /**
     * Asks Dart for fresh STS credentials.
     *
     * Called by the activity's credentials provider, which the SDK may invoke
     * more than once — the ~900 s window can close mid-challenge. [onResult]
     * runs on the main thread.
     */
    internal fun fetchCredentials(onResult: (Map<*, *>?, String?) -> Unit) {
        main.post {
            channel.invokeMethod(
                "getCredentials",
                null,
                object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        onResult(result as? Map<*, *>, null)
                    }

                    override fun error(code: String, message: String?, details: Any?) {
                        onResult(null, message ?: code)
                    }

                    override fun notImplemented() {
                        onResult(null, "Credentials provider is not implemented.")
                    }
                }
            )
        }
    }

    companion object {
        private const val CHANNEL = "trydos_wallet/face_liveness"
        private const val REQUEST_CODE = 0x11FE

        const val ERROR_SETUP = "SETUP_FAILED"
        const val ERROR_CANCELLED = "CANCELLED"
        const val ERROR_CAMERA = "CAMERA_PERMISSION"
        const val ERROR_LANDSCAPE = "LANDSCAPE"
        const val ERROR_FRAMERATE = "CAMERA_TOO_SLOW"

        /**
         * The attached plugin, so the hosted activity can reach the channel.
         *
         * Volatile rather than synchronised: it is written on attach/detach and
         * read from the activity, both on the main thread, and a stale read
         * would hand the SDK a dead channel.
         */
        @Volatile
        internal var instance: TrydosWalletPlugin? = null
    }
}
