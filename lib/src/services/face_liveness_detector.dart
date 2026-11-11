import '../models/kyc/kyc_aws_liveness.dart';

/// Why an AWS Face Liveness run ended without a verdict.
///
/// Mirrors the cases the web maps, so the UI can say something useful instead
/// of one generic failure.
enum FaceLivenessErrorKind {
  /// Camera permission refused or revoked.
  cameraBlocked,

  /// The device could not sustain the framerate AWS needs.
  cameraTooSlow,

  /// AWS refuses to run in landscape (`MOBILE_LANDSCAPE_ERROR`).
  landscape,

  /// The user backed out before the challenge finished.
  cancelled,

  /// Anything else — SDK setup, network, an unmapped AWS error.
  setupFailed,
}

/// A detector run that ended before AWS reached a verdict.
class FaceLivenessException implements Exception {
  const FaceLivenessException(this.kind, {this.message, this.code});

  final FaceLivenessErrorKind kind;

  /// Raw message from the native SDK, for logs — not for the user.
  final String? message;

  /// Raw SDK error code when it gave one.
  final String? code;

  @override
  String toString() =>
      'FaceLivenessException(${kind.name}${code != null ? ', $code' : ''}'
      '${message != null ? ': $message' : ''})';
}

/// Supplies fresh STS credentials to the native detector.
///
/// Called by the SDK whenever it needs credentials, including after the
/// ~900 s ones expire mid-flow, so it must fetch rather than return a cached
/// value it was handed once.
typedef FaceLivenessCredentialsProvider = Future<KycAwsCredentials> Function();

/// Runs the platform's AWS Face Liveness UI.
///
/// The library stops here on purpose. Everything up to this call — opening the
/// KYC session, creating the AWS session, minting credentials, reading the
/// verdict — is plain Dart in this package. The challenge itself needs the
/// native Amplify UI components (Jetpack Compose on Android, SwiftUI on iOS),
/// which a pure-Dart package cannot ship; an implementation is injected
/// instead, by a plugin or by the host app.
///
/// The detector owns its whole screen and its whole interaction: the oval, the
/// countdown, the light sequence. The app captures no image of its own — the
/// selfie of record comes back from the server in the result.
abstract class FaceLivenessDetector {
  /// Presents the detector for [sessionId] in [region] and returns when the
  /// challenge finishes.
  ///
  /// Completing normally means only that the challenge ran; the verdict is
  /// read afterwards from `GET /liveness-aws?sessionId=`. Throws a
  /// [FaceLivenessException] when the run ended without one.
  Future<void> present({
    required String sessionId,
    required String region,
    required FaceLivenessCredentialsProvider credentialsProvider,
  });

  /// Whether this build can actually run the challenge.
  ///
  /// False on a host that wired no native side, which lets the entry screen
  /// say so up front instead of failing after the user has photographed their
  /// ID.
  Future<bool> isAvailable();
}
