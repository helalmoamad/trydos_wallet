package com.trydos.trydos_wallet

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.content.ContextCompat
import com.amplifyframework.auth.AWSCredentials
import com.amplifyframework.auth.AWSCredentialsProvider
import com.amplifyframework.auth.AWSTemporaryCredentials
import com.amplifyframework.auth.AuthException
import com.amplifyframework.core.Consumer
import com.amplifyframework.ui.liveness.ui.FaceLivenessDetector
// The SDK wants Smithy's Instant, not java.time's. Aliased so the difference
// is visible at the call site rather than hidden behind the same short name.
import aws.smithy.kotlin.runtime.time.Instant as SmithyInstant

/**
 * Hosts the Amplify UI Face Liveness challenge full screen.
 *
 * Full screen is not a layout preference. The challenge detects a live person
 * partly by casting a sequence of coloured lights on their face and reading
 * the reflection, so shrinking it into a card inside the app would dim that
 * light and push the pass rate down. The app's own design resumes either side
 * of this screen.
 *
 * The activity finishes as soon as the challenge ends. It never decides
 * whether the person passed — Dart reads that verdict from the server.
 */
class FaceLivenessActivity : ComponentActivity() {

    private lateinit var sessionId: String
    private lateinit var region: String

    private val cameraPermission =
        registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted ->
            if (granted) {
                showChallenge()
            } else {
                finishWithError(
                    TrydosWalletPlugin.ERROR_CAMERA,
                    "Camera permission is required for the liveness check."
                )
            }
        }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        sessionId = intent.getStringExtra(EXTRA_SESSION_ID).orEmpty()
        region = intent.getStringExtra(EXTRA_REGION).orEmpty()
        if (sessionId.isEmpty() || region.isEmpty()) {
            finishWithError(
                TrydosWalletPlugin.ERROR_SETUP,
                "Missing liveness session details."
            )
            return
        }

        val granted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.CAMERA
        ) == PackageManager.PERMISSION_GRANTED

        if (granted) showChallenge() else cameraPermission.launch(Manifest.permission.CAMERA)
    }

    private fun showChallenge() {
        setContent {
            FaceLivenessDetector(
                sessionId = sessionId,
                region = region,
                credentialsProvider = DartCredentialsProvider(),
                onComplete = {
                    // The challenge ran to the end. The verdict lives on the
                    // server; Dart fetches it next.
                    setResult(Activity.RESULT_OK)
                    finish()
                },
                onError = { error ->
                    finishWithError(mapErrorCode(error), error.toString())
                }
            )
        }
    }

    /**
     * Serves the SDK from Dart, which holds the user's token and the Worker's
     * address. Called again whenever the ~900 s credentials lapse mid-run.
     */
    private inner class DartCredentialsProvider : AWSCredentialsProvider<AWSCredentials> {
        override fun fetchAWSCredentials(
            onSuccess: Consumer<AWSCredentials>,
            onError: Consumer<AuthException>
        ) {
            val plugin = TrydosWalletPlugin.instance
            if (plugin == null) {
                onError.accept(credentialsError("The wallet plugin is not attached."))
                return
            }

            plugin.fetchCredentials { map, failure ->
                if (map == null) {
                    onError.accept(
                        credentialsError(failure ?: "Could not issue liveness credentials.")
                    )
                    return@fetchCredentials
                }

                val accessKeyId = map["accessKeyId"] as? String
                val secretAccessKey = map["secretAccessKey"] as? String
                val sessionToken = map["sessionToken"] as? String
                if (accessKeyId.isNullOrEmpty() ||
                    secretAccessKey.isNullOrEmpty() ||
                    sessionToken.isNullOrEmpty()
                ) {
                    onError.accept(credentialsError("Incomplete STS credentials."))
                    return@fetchCredentials
                }

                // An unparsable or absent expiry is treated as "already past",
                // so the SDK refreshes rather than trusting credentials whose
                // lifetime we cannot vouch for.
                val expiration = (map["expiration"] as? String)
                    ?.let { runCatching { SmithyInstant.fromIso8601(it) }.getOrNull() }
                    ?: SmithyInstant.now()

                onSuccess.accept(
                    AWSTemporaryCredentials(
                        accessKeyId,
                        secretAccessKey,
                        sessionToken,
                        expiration
                    )
                )
            }
        }

        private fun credentialsError(message: String) =
            AuthException(message, "Check the liveness credentials endpoint.")
    }

    /// Maps the SDK's failures onto the codes Dart branches on.
    ///
    /// Takes [Any] rather than the SDK's own exception type: that type is not
    /// a Throwable, and naming it here would tie this file to a class the
    /// Amplify version is free to move.
    private fun mapErrorCode(error: Any): String {
        val text = error.toString().lowercase()
        return when {
            "landscape" in text -> TrydosWalletPlugin.ERROR_LANDSCAPE
            "framerate" in text || "frame rate" in text ->
                TrydosWalletPlugin.ERROR_FRAMERATE
            "permission" in text || "camera" in text ->
                TrydosWalletPlugin.ERROR_CAMERA
            else -> TrydosWalletPlugin.ERROR_SETUP
        }
    }

    private fun finishWithError(code: String, message: String) {
        setResult(
            Activity.RESULT_CANCELED,
            Intent().apply {
                putExtra(EXTRA_ERROR_CODE, code)
                putExtra(EXTRA_ERROR_MESSAGE, message)
            }
        )
        finish()
    }

    companion object {
        const val EXTRA_SESSION_ID = "sessionId"
        const val EXTRA_REGION = "region"
        const val EXTRA_ERROR_CODE = "errorCode"
        const val EXTRA_ERROR_MESSAGE = "errorMessage"
    }
}
