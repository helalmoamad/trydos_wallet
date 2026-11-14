import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/src/screens/kyc/widgets/face_mesh_overlay.dart';
import 'package:trydos_wallet/src/services/face_tracker.dart';
import 'package:trydos_wallet/src/utils/face_framing_guide.dart';
import 'package:trydos_wallet/src/utils/kyc_trace.dart';
import 'package:trydos_wallet/src/utils/face_light_gate.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

/// The liveness step: two short stages in the app's own design, then the AWS
/// challenge, then a green hold before the ID comparison.
///
/// Stage one reads the room's light; stage two finds the face and asks the
/// user to frame and hold it, drawing a web over it so they can see they have
/// been found. Both run off one camera stream — the same frames feed the
/// luma reading and the face detector.
///
/// The challenge in between belongs to AWS: the native Amplify component owns
/// its whole screen, and the selfie of record comes back from the server
/// rather than from this camera.
class LiveFaceDetection extends StatefulWidget {
  final Function(String selfiePath)? onSuccessTap;
  final bool isActive;
  const LiveFaceDetection({super.key, this.onSuccessTap, this.isActive = true});

  @override
  State<LiveFaceDetection> createState() => _LiveFaceDetectionState();
}

enum _Stage {
  /// "Checking the lighting…" — stage one.
  checkingLight,

  /// Finding and framing the face — stage two, the web is drawn here.
  framing,

  /// The shutter has fired and the shot is being prepared.
  capturing,

  /// Captured. The face holds inside a green frame before the flow moves on.
  passed,

  failed,
}

class _LiveFaceDetectionState extends State<LiveFaceDetection> {
  CameraController? _cameraController;
  CameraDescription? _cameraDescription;
  static const double _defaultFrontZoomLevel = 1.15;

  bool _isCameraInitialized = false;
  bool _isCameraError = false;
  bool _isCameraTimedOut = false;
  bool _isStreaming = false;
  Timer? _cameraInactivityTimer;

  _Stage _stage = _Stage.checkingLight;
  String? _capturedSelfiePath;
  String? _failureMessage;
  bool _didNotifySuccess = false;
  int _flowToken = 0;

  final FaceLightGate _lightGate = FaceLightGate();
  final FaceFramingGuide _framingGuide = FaceFramingGuide();
  final FaceTracker _faceTracker = FaceTracker();

  /// What the overlay draws, one polyline per contour. Empty until a face is
  /// found.
  List<List<Offset>> _meshContours = const [];
  Size _meshSourceSize = Size.zero;
  double _progress = 0;

  /// Throttles light sampling: the stream runs at camera rate, and the light
  /// does not change thirty times a second.
  DateTime _lastLightSample = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _lightSampleInterval = Duration(milliseconds: 150);

  /// Stage one is held briefly even when the light passes at once, so the
  /// message is read rather than flashed.
  DateTime? _lightStageSince;
  static const Duration _minLightStage = Duration(milliseconds: 1200);

  static const Duration _greenHold = Duration(seconds: 3);
  static const Duration _cameraInactivityTimeout = Duration(seconds: 45);

  static const Color _ink = Color(0xff1D1D1D);
  static const Color _blue = Color(0xff388CFF);
  static const Color _green = Color(0xffA3FF38);
  static const Color _red = Color(0xffFF6B6B);
  static const Color _webPink = Color(0xFFFF8E8E);

  @override
  void initState() {
    super.initState();
    WalletAnalytics.screen(WalletScreens.kycLiveness);
    // AWS refuses the challenge in landscape (MOBILE_LANDSCAPE_ERROR), so the
    // whole step is pinned upright.
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    if (widget.isActive) _initCamera();
  }

  @override
  void didUpdateWidget(covariant LiveFaceDetection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _handlePageActivityChange(widget.isActive);
    }
  }

  Future<void> _handlePageActivityChange(bool isActive) async {
    if (!mounted) return;

    if (!isActive) {
      _flowToken++;
      _cameraInactivityTimer?.cancel();
      await _releaseCamera();
      if (mounted) setState(() => _isCameraInitialized = false);
      return;
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      await _initCamera();
    }
  }

  // ── Camera ────────────────────────────────────────────────────────────────

  Future<void> _initCamera() async {
    try {
      _cameraInactivityTimer?.cancel();
      if (_isCameraTimedOut && mounted) {
        setState(() => _isCameraTimedOut = false);
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _isCameraError = true);
        return;
      }

      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cameraDescription = frontCamera;

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      await _applyDefaultCameraZoom();
      if (!mounted) return;

      _lightGate.reset();
      _framingGuide.reset();
      _lightStageSince = DateTime.now();
      setState(() {
        _isCameraInitialized = true;
        _stage = _Stage.checkingLight;
        _progress = 0;
        _meshContours = const [];
        _failureMessage = null;
      });
      _resetCameraInactivityTimer();
      await _startStream();
    } catch (_) {
      if (mounted) setState(() => _isCameraError = true);
    }
  }

  Future<void> _startStream() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (_isStreaming) return;

    final token = ++_flowToken;
    _isStreaming = true;
    try {
      await controller.startImageStream((image) => _onFrame(image, token));
    } catch (_) {
      _isStreaming = false;
      if (mounted) setState(() => _isCameraError = true);
    }
  }

  /// Hands the camera back to the system.
  ///
  /// Required before the AWS detector opens: the native component takes the
  /// front camera for itself, and a stream still holding it makes that fail.
  Future<void> _releaseCamera() async {
    final controller = _cameraController;
    _cameraController = null;
    if (controller == null) return;

    try {
      if (_isStreaming) {
        _isStreaming = false;
        await controller.stopImageStream();
      }
    } catch (_) {}
    try {
      await controller.dispose();
    } catch (_) {}
  }

  Future<void> _applyDefaultCameraZoom() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();
      await controller.setZoomLevel(
        _defaultFrontZoomLevel.clamp(minZoom, maxZoom).toDouble(),
      );
    } catch (_) {
      // Keep the device default when zoom levels are unavailable.
    }
  }

  void _resetCameraInactivityTimer() {
    _cameraInactivityTimer?.cancel();
    if (!widget.isActive ||
        _stage == _Stage.passed ||
        _stage == _Stage.capturing ||
        _isCameraError) {
      return;
    }
    _cameraInactivityTimer = Timer(
      _cameraInactivityTimeout,
      _handleCameraInactivityTimeout,
    );
  }

  Future<void> _handleCameraInactivityTimeout() async {
    if (!mounted || !widget.isActive || _stage == _Stage.passed) return;
    _flowToken++;
    _cameraInactivityTimer?.cancel();
    await _releaseCamera();
    if (!mounted) return;
    setState(() {
      _isCameraInitialized = false;
      _isCameraTimedOut = true;
      _isCameraError = false;
    });
  }

  Future<void> _reopenCameraAfterTimeout() async {
    if (!widget.isActive || _stage == _Stage.passed) return;
    if (mounted) {
      setState(() {
        _isCameraTimedOut = false;
        _isCameraError = false;
      });
    }
    await _initCamera();
  }

  // ── One stream, both stages ───────────────────────────────────────────────

  Future<void> _onFrame(CameraImage image, int token) async {
    if (!_isTokenValid(token)) return;

    switch (_stage) {
      case _Stage.checkingLight:
        _readLight(image);
        return;
      case _Stage.framing:
        await _trackFace(image, token);
        return;
      case _Stage.capturing:
      case _Stage.passed:
      case _Stage.failed:
        return;
    }
  }

  /// Stage one: is the room lit well enough to be worth a billed attempt?
  void _readLight(CameraImage image) {
    final now = DateTime.now();
    if (now.difference(_lastLightSample) < _lightSampleInterval) return;
    _lastLightSample = now;

    final sample = measureLumaPlane(
      luma: image.planes.first.bytes,
      width: image.width,
      height: image.height,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    // A frame that yields no reading waives the gate rather than stranding a
    // user whose camera will not give one.
    final passed = sample == null ? true : _lightGate.accept(sample, now: now);
    final since = _lightStageSince ?? now;
    final heldLongEnough = now.difference(since) >= _minLightStage;

    if (!mounted) return;
    setState(() {
      _progress = passed ? 1.0 : (_progress + 0.05).clamp(0.0, 0.9).toDouble();
    });

    if (passed && heldLongEnough) _enterFramingStage();
  }

  void _enterFramingStage() {
    if (_stage != _Stage.checkingLight || !mounted) return;
    _framingGuide.reset();
    setState(() {
      _stage = _Stage.framing;
      _progress = 0;
    });
    _resetCameraInactivityTimer();
  }

  /// Stage two: find the face, draw the web on it, and wait for it to settle.
  Future<void> _trackFace(CameraImage image, int token) async {
    final camera = _cameraDescription;
    if (camera == null) return;

    final result = await _faceTracker.process(image, camera, 0);
    // Null means the previous frame is still in flight — skipped, not failed.
    if (result == null || !_isTokenValid(token)) return;
    if (_stage != _Stage.framing) return;

    final ready = _framingGuide.accept(result.frame);

    if (!mounted) return;
    setState(() {
      _meshContours = result.contours;
      _meshSourceSize = result.sourceSize;
      _progress = _framingGuide.progress;
    });

    if (ready) await _captureSelfie(token);
  }

  // ── The selfie ────────────────────────────────────────────────────────────

  /// Takes the selfie the rest of the flow compares against the ID.
  ///
  /// Fired by the framing guide, not by a button: the user has already held
  /// still long enough to satisfy it, and asking them to then press something
  /// would move the face they just steadied.
  Future<void> _captureSelfie(int token) async {
    if (!_isTokenValid(token) || _stage != _Stage.framing) return;

    final bloc = context.read<WalletBloc>();
    _cameraInactivityTimer?.cancel();
    setState(() => _stage = _Stage.capturing);

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _failCapture();
      return;
    }

    try {
      // takePicture cannot run while the stream is on; the stream has done
      // its job anyway now that the face is framed.
      if (_isStreaming) {
        _isStreaming = false;
        await controller.stopImageStream();
      }

      final shot = await controller.takePicture();
      if (!_isTokenValid(token)) return;

      await _bakeOrientation(shot.path);
      final bytes = await File(shot.path).readAsBytes();
      if (!_isTokenValid(token)) return;

      final dataUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      bloc.add(WalletKycSelfieCaptured(dataUrl));

      await _completeWithSelfie(shot.path);
    } catch (e) {
      KycTrace.fail('selfie capture', {'error': e.toString()});
      _failCapture();
    }
  }

  /// Writes the JPEG's EXIF rotation into its pixels.
  ///
  /// The server crops the face from these bytes and never reads EXIF, so a
  /// front-camera shot left at 90° would be compared sideways against the ID.
  Future<void> _bakeOrientation(String path) async {
    try {
      final file = File(path);
      final decoded = img.decodeImage(await file.readAsBytes());
      if (decoded == null) return;
      await file.writeAsBytes(
        img.encodeJpg(img.bakeOrientation(decoded), quality: 92),
        flush: true,
      );
    } catch (_) {
      // Keep the original capture if processing fails — a sideways image
      // still beats no image.
    }
  }

  Future<void> _completeWithSelfie(String path) async {
    if (_stage == _Stage.passed || !mounted) return;

    setState(() {
      _stage = _Stage.passed;
      _progress = 1;
      _capturedSelfiePath = path;
    });

    // The face holds inside the green frame long enough to register before
    // the flow moves on to the ID comparison.
    await Future<void>.delayed(_greenHold);

    if (!_didNotifySuccess && mounted) {
      _didNotifySuccess = true;
      widget.onSuccessTap?.call(_capturedSelfiePath ?? '');
    }
  }

  void _failCapture() {
    if (!mounted) return;
    setState(() {
      _stage = _Stage.failed;
      _progress = 0;
      _meshContours = const [];
      _failureMessage = null;
    });
  }

  Future<void> _restartLiveness() async {
    _flowToken++;
    _didNotifySuccess = false;
    _capturedSelfiePath = null;
    _cameraInactivityTimer?.cancel();
    _lightGate.reset();
    _framingGuide.reset();

    context.read<WalletBloc>().add(const WalletKycLivenessResetRequested());
    if (!mounted) return;

    setState(() {
      _stage = _Stage.checkingLight;
      _progress = 0;
      _meshContours = const [];
      _failureMessage = null;
    });

    // Every retry opens a brand-new AWS session; the old one is never reused.
    await _initCamera();
  }

  bool _isTokenValid(int token) =>
      mounted && widget.isActive && _flowToken == token;

  // ── What the user is told ─────────────────────────────────────────────────

  String _statusText(String lang) {
    switch (_stage) {
      case _Stage.passed:
        return AppStrings.get(lang, 'kyc_liveness_done');
      case _Stage.failed:
        return _failureMessage ?? AppStrings.get(lang, 'kyc_liveness_failed');
      case _Stage.capturing:
        return AppStrings.get(lang, 'kyc_liveness_verifying');
      case _Stage.checkingLight:
        return _lightText(lang);
      case _Stage.framing:
        return _framingText(lang);
    }
  }

  String _lightText(String lang) {
    switch (_lightGate.verdict) {
      case FaceLightVerdict.tooBright:
        return AppStrings.get(lang, 'kyc_light_too_bright');
      case FaceLightVerdict.backlit:
        return AppStrings.get(lang, 'kyc_light_backlit');
      case FaceLightVerdict.tooDark:
        return AppStrings.get(lang, 'kyc_light_too_dark');
      case FaceLightVerdict.tooBlurry:
        return AppStrings.get(lang, 'kyc_light_too_blurry');
      case FaceLightVerdict.ok:
        return AppStrings.get(lang, 'kyc_light_ok');
    }
  }

  String _framingText(String lang) {
    switch (_framingGuide.hint) {
      case FaceFramingHint.noFace:
        return AppStrings.get(lang, 'kyc_face_not_found');
      case FaceFramingHint.moveCloser:
        return AppStrings.get(lang, 'kyc_face_move_closer');
      case FaceFramingHint.moveBack:
        return AppStrings.get(lang, 'kyc_face_move_back');
      case FaceFramingHint.centreFace:
        return AppStrings.get(lang, 'kyc_face_centre');
      case FaceFramingHint.holdSteady:
        return AppStrings.get(lang, 'kyc_face_hold_steady');
      case FaceFramingHint.ready:
        return AppStrings.get(lang, 'kyc_face_ready');
    }
  }

  /// Pink while finding the face, green once AWS has passed the person.
  Color get _webColor => _stage == _Stage.passed ? _green : _webPink;

  Color get _borderColor {
    switch (_stage) {
      case _Stage.passed:
        return _green;
      case _Stage.failed:
        return _red;
      case _Stage.checkingLight:
      case _Stage.framing:
      case _Stage.capturing:
        return _blue;
    }
  }

  @override
  void dispose() {
    _flowToken++;
    _cameraInactivityTimer?.cancel();
    unawaited(_releaseCamera());
    unawaited(_faceTracker.close());
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  // ── Layout ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        final lang = state.languageCode;
        final passed = _stage == _Stage.passed;
        final failed = _stage == _Stage.failed;

        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 100.h),
            Text(
              AppStrings.get(lang, 'kyc_identity_verification'),
              style: context.textTheme.titleLarge?.bq.copyWith(
                color: _ink,
                letterSpacing: 0.14,
                height: 1.43,
                fontSize: 30.sp,
              ),
            ),
            SizedBox(height: 15.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: SizedBox(
                height: 20.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      TrydosWalletAssets.liveFace,
                      package: TrydosWalletStyles.packageName,
                      height: 20.h,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      AppStrings.get(lang, 'kyc_live_face_detection'),
                      style: context.textTheme.titleLarge?.mq.copyWith(
                        color: _ink,
                        letterSpacing: 0.14,
                        height: 1.1,
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Container(
                height: 400.h,
                width: 1.sw,
                margin: EdgeInsets.symmetric(horizontal: 40.w),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _borderColor,
                    width: passed ? 2 : 0.5,
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30.r),
                      child: _buildCardBody(lang, context),
                    ),
                    ..._corners(),
                    // The web: the user watches it find their face, grow as
                    // they lean in, and turn green when they pass.
                    if (!_isCameraError && !_isCameraTimedOut)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 14.h,
                        child: Center(child: _hintPill(lang, context)),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
            if (!passed && !failed)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 45.w),
                child: SizedBox(
                  height: 5.h,
                  width: 330.w,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5.r),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.r),
                            border: Border.all(color: _blue, width: 0.5),
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: _progress),
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                          builder: (context, value, child) =>
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: value,
                                child: child,
                              ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _blue,
                              borderRadius: BorderRadius.circular(5.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (failed) ...[
              SizedBox(height: 6.h),
              InkWell(
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                onTap: _restartLiveness,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  child: Text(
                    AppStrings.get(lang, 'kyc_incorrect_try_again'),
                    style: context.textTheme.titleLarge?.rq.copyWith(
                      color: const Color(0xff4D84FF),
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
            const Spacer(),
            SvgPicture.asset(
              TrydosWalletAssets.privacy,
              package: TrydosWalletStyles.packageName,
              height: 15.h,
            ),
            SizedBox(height: 10.h),
            Text(
              AppStrings.get(lang, 'kyc_privacy_safe'),
              style: context.textTheme.titleLarge?.rq.copyWith(
                color: const Color(0xff4D84FF),
                letterSpacing: 0.14,
                height: 1.43,
                fontSize: 12.sp,
              ),
            ),
            SizedBox(height: 35.h),
          ],
        );
      },
    );
  }

  Widget _buildCardBody(String lang, BuildContext context) {
    if (_isCameraError) {
      return Container(
        color: const Color(0xffF5F5F5),
        alignment: Alignment.center,
        child: Text(
          AppStrings.get(lang, 'kyc_camera_error'),
          textAlign: TextAlign.center,
          style: context.textTheme.titleLarge?.rq.copyWith(
            color: _ink,
            fontSize: 14.sp,
          ),
        ),
      );
    }

    if (_isCameraTimedOut) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.get(lang, 'kyc_camera_auto_closed'),
                textAlign: TextAlign.center,
                style: context.textTheme.titleLarge?.rq.copyWith(
                  color: Colors.white,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 12.h),
              InkWell(
                onTap: _reopenCameraAfterTimeout,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  decoration: BoxDecoration(
                    color: _blue,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    AppStrings.get(lang, 'kyc_reopen_camera'),
                    style: context.textTheme.titleLarge?.rq.copyWith(
                      color: Colors.white,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_stage == _Stage.passed && _capturedSelfiePath != null) {
      return SizedBox.expand(
        child: Image.file(File(_capturedSelfiePath!), fit: BoxFit.cover),
      );
    }

    if (_isCameraInitialized && _cameraController != null) {
      return SizedBox.expand(child: _buildCameraPreview());
    }
    return Container(color: const Color(0xffF5F5F5));
  }

  /// The instruction, on a dark pill over the preview where the eye already
  /// is — rather than below the card, where it would be missed.
  Widget _hintPill(String lang, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: _ink.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        _statusText(lang),
        textAlign: TextAlign.center,
        style: context.textTheme.titleLarge?.rq.copyWith(
          color: Colors.white,
          fontSize: 12.sp,
          height: 1.2,
        ),
      ),
    );
  }

  List<Widget> _corners() {
    final corners = <(String, double?, double?, double?, double?)>[
      (TrydosWalletAssets.topLeft, 15.w, null, 20.h, null),
      (TrydosWalletAssets.topRight, null, 15.w, 20.h, null),
      (TrydosWalletAssets.bottomLeft, 15.w, null, null, 20.h),
      (TrydosWalletAssets.bottomRight, null, 15.w, null, 20.h),
    ];
    return [
      for (final (asset, left, right, top, bottom) in corners)
        Positioned(
          left: left,
          right: right,
          top: top,
          bottom: bottom,
          child: SvgPicture.asset(
            asset,
            package: TrydosWalletStyles.packageName,
            height: 18.h,
          ),
        ),
    ];
  }

  Widget _buildCameraPreview() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return Container(color: const Color(0xffF5F5F5));
    }

    final previewSize = controller.value.previewSize;
    if (previewSize == null) return CameraPreview(controller);

    // The mesh lives inside this FittedBox, not beside it.
    //
    // Drawn as a sibling it had to re-derive the same "cover" transform from
    // the stream frame's size — and on Android the preview surface and the
    // image stream are routinely handed different resolutions for one preset.
    // Two sources, two transforms, and the web sat a little below the face.
    // Inside the box there is one transform, applied to both.
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: previewSize.height,
        height: previewSize.width,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(controller),
            if (_meshContours.isNotEmpty)
              FaceMeshOverlay(
                contours: _meshContours,
                sourceSize: _meshSourceSize,
                color: _webColor,
              ),
          ],
        ),
      ),
    );
  }
}
