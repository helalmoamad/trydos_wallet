import 'package:flutter/services.dart';

import '../models/kyc/kyc_aws_liveness.dart';
import 'face_liveness_detector.dart';

/// [FaceLivenessDetector] backed by the Amplify UI components this package
/// ships natively — `FaceLivenessDetector` on Android (Compose) and
/// `FaceLivenessDetectorView` on iOS (SwiftUI).
///
/// The native side presents the challenge full screen and calls back here for
/// credentials, so the STS fetch keeps running through the app's own Dart API
/// client — the native code never learns the user's token or the Worker's URL.
class PlatformFaceLivenessDetector implements FaceLivenessDetector {
  PlatformFaceLivenessDetector({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  /// Must match the channel name registered by the Android and iOS plugins.
  static const String channelName = 'trydos_wallet/face_liveness';

  final MethodChannel _channel;

  /// Set for the duration of one [present] call. The native side may ask for
  /// credentials more than once — the SDK refreshes them when the ~900 s STS
  /// window closes mid-challenge.
  FaceLivenessCredentialsProvider? _activeProvider;
  bool _handlerInstalled = false;

  @override
  Future<bool> isAvailable() async {
    try {
      final available = await _channel.invokeMethod<bool>('isAvailable');
      return available ?? false;
    } on MissingPluginException {
      // Host built without the native side (or a platform we do not ship).
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> present({
    required String sessionId,
    required String region,
    required FaceLivenessCredentialsProvider credentialsProvider,
  }) async {
    _installHandler();
    _activeProvider = credentialsProvider;
    try {
      await _channel.invokeMethod<void>('present', <String, dynamic>{
        'sessionId': sessionId,
        'region': region,
      });
    } on MissingPluginException catch (e) {
      throw FaceLivenessException(
        FaceLivenessErrorKind.setupFailed,
        message: e.message,
      );
    } on PlatformException catch (e) {
      throw FaceLivenessException(
        _kindFromCode(e.code),
        code: e.code,
        message: e.message,
      );
    } finally {
      _activeProvider = null;
    }
  }

  void _installHandler() {
    if (_handlerInstalled) return;
    _handlerInstalled = true;
    _channel.setMethodCallHandler(_onNativeCall);
  }

  /// Serves the native `AWSCredentialsProvider`.
  Future<Object?> _onNativeCall(MethodCall call) async {
    if (call.method != 'getCredentials') {
      throw MissingPluginException('Unknown method ${call.method}');
    }

    final provider = _activeProvider;
    if (provider == null) {
      // The detector asked after the run ended — nothing legitimate to serve.
      throw PlatformException(
        code: 'NO_PROVIDER',
        message: 'No liveness run is active.',
      );
    }

    final KycAwsCredentials credentials;
    try {
      credentials = await provider();
    } catch (e) {
      // Surfaces to the SDK as a credentials failure, which ends the run and
      // comes back to present() as an error rather than hanging the camera.
      throw PlatformException(
        code: 'CREDENTIALS_FAILED',
        message: e.toString(),
      );
    }

    if (!credentials.isComplete) {
      throw PlatformException(
        code: 'CREDENTIALS_FAILED',
        message: 'Incomplete STS credentials.',
      );
    }
    return credentials.toChannelMap();
  }

  /// Maps the codes the two plugins raise onto the shared error kinds.
  static FaceLivenessErrorKind _kindFromCode(String code) {
    switch (code) {
      case 'CAMERA_PERMISSION':
      case 'CAMERA_BLOCKED':
        return FaceLivenessErrorKind.cameraBlocked;
      case 'CAMERA_TOO_SLOW':
      case 'FRAMERATE':
        return FaceLivenessErrorKind.cameraTooSlow;
      case 'LANDSCAPE':
      case 'MOBILE_LANDSCAPE_ERROR':
        return FaceLivenessErrorKind.landscape;
      case 'CANCELLED':
        return FaceLivenessErrorKind.cancelled;
      default:
        return FaceLivenessErrorKind.setupFailed;
    }
  }
}
