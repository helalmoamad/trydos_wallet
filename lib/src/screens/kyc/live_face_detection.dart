import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/src/services/face_liveness_controller.dart';
import 'package:trydos_wallet/src/services/face_liveness_detector.dart';
import 'package:trydos_wallet/src/services/platform_face_liveness_detector.dart';
import 'package:trydos_wallet/src/utils/face_light_gate.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

/// The liveness step of the KYC flow.
///
/// The challenge itself is AWS Face Liveness, presented full screen by the
/// native Amplify UI component — its oval, countdown and light sequence are
/// not ours to restyle, and shrinking it into this page's card would dim the
/// light it reads off the user's face.
///
/// So this screen is everything around it, in the app's own design: the
/// preview, the light gate that turns a likely failure into an instruction
/// before a billed AWS session is spent, and the result. The selfie of record
/// is the reference image AWS returns — the device captures none of its own.
class LiveFaceDetection extends StatefulWidget {
  final Function(String selfiePath)? onSuccessTap;
  final bool isActive;
  const LiveFaceDetection({super.key, this.onSuccessTap, this.isActive = true});

  @override
  State<LiveFaceDetection> createState() => _LiveFaceDetectionState();
}

/// What the screen is doing, which is also what the user is being told.
enum _Stage {
  /// Reading the light before offering to start.
  checking,

  /// Light is good — holding green briefly, then starting.
  ready,

  /// The native detector is on screen.
  running,

  /// AWS judged the person live.
  completed,

  /// The attempt ended without a verdict, or with a failing one.
  failed,
}

class _LiveFaceDetectionState extends State<LiveFaceDetection> {
  CameraController? _cameraController;
  static const double _defaultFrontZoomLevel = 1.15;

  bool _isCameraInitialized = false;
  bool _isCameraError = false;
  bool _isCameraTimedOut = false;
  Timer? _cameraInactivityTimer;

  _Stage _stage = _Stage.checking;
  double _progress = 0.0;
  String? _capturedSelfiePath;
  String? _failureMessage;
  bool _didNotifySuccess = false;

  /// Guards the light-gate sampling loop and the attempt against a page the
  /// user has already left.
  int _flowToken = 0;

  final FaceLightGate _lightGate = FaceLightGate();
  late final FaceLivenessController _controller = FaceLivenessController(
    detector: _detector,
  );
  final FaceLivenessDetector _detector = PlatformFaceLivenessDetector();

  /// False on a build whose host never wired the native side. Checked up
  /// front so the user is told before photographing anything, not after.
  bool _detectorAvailable = true;

  Timer? _lightTimer;
  bool _isSamplingLight = false;
  DateTime? _checkingSince;

  /// The guide holds the "checking" state for at least this long, so a gate
  /// that passes instantly does not flash past unread.
  static const Duration _minCheckingTime = Duration(milliseconds: 1200);

  /// And holds green this long once it passes, before the detector opens.
  static const Duration _readyHold = Duration(milliseconds: 1000);

  static const Duration _lightSampleInterval = Duration(milliseconds: 150);
  static const Duration _cameraInactivityTimeout = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WalletAnalytics.screen(WalletScreens.kycLiveness);
    // AWS refuses the challenge in landscape (MOBILE_LANDSCAPE_ERROR), so the
    // whole step is pinned upright.
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    _checkDetector();
    if (widget.isActive) {
      _initCamera();
    }
  }

  Future<void> _checkDetector() async {
    final available = await _detector.isAvailable();
    if (!mounted || available) return;
    setState(() {
      _detectorAvailable = false;
      _stage = _Stage.failed;
      _failureMessage = null;
    });
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
      return;
    }

    _startLightGate();
  }

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
      setState(() => _isCameraInitialized = true);
      _resetCameraInactivityTimer();

      _startLightGate();
    } catch (_) {
      if (mounted) setState(() => _isCameraError = true);
    }
  }

  /// Hands the camera back to the system.
  ///
  /// Required before the detector opens: the native component takes the front
  /// camera for itself, and a preview still holding it makes that fail.
  Future<void> _releaseCamera() async {
    _lightTimer?.cancel();
    _lightTimer = null;
    final controller = _cameraController;
    _cameraController = null;
    try {
      await controller?.dispose();
    } catch (_) {}
  }

  void _resetCameraInactivityTimer() {
    _cameraInactivityTimer?.cancel();
    if (!widget.isActive ||
        _stage == _Stage.completed ||
        _stage == _Stage.running ||
        _isCameraError) {
      return;
    }

    _cameraInactivityTimer = Timer(
      _cameraInactivityTimeout,
      _handleCameraInactivityTimeout,
    );
  }

  Future<void> _handleCameraInactivityTimeout() async {
    if (!mounted || !widget.isActive || _stage == _Stage.completed) return;

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
    if (!widget.isActive || _stage == _Stage.completed) return;

    if (mounted) {
      setState(() {
        _isCameraTimedOut = false;
        _isCameraError = false;
      });
    }
    await _initCamera();
  }

  Future<void> _applyDefaultCameraZoom() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();
      final targetZoom = _defaultFrontZoomLevel
          .clamp(minZoom, maxZoom)
          .toDouble();
      await controller.setZoomLevel(targetZoom);
    } catch (_) {
      // Keep default device zoom if zoom levels are unavailable.
    }
  }

  // ── Light gate ────────────────────────────────────────────────────────────

  void _startLightGate() {
    if (!mounted || !widget.isActive || !_detectorAvailable) return;
    if (_stage == _Stage.running || _stage == _Stage.completed) return;
    if (!_isCameraInitialized) return;

    _lightGate.reset();
    _checkingSince = DateTime.now();
    _lightTimer?.cancel();
    setState(() {
      _stage = _Stage.checking;
      _progress = 0;
      _failureMessage = null;
    });
    _resetCameraInactivityTimer();

    final token = ++_flowToken;
    _lightTimer = Timer.periodic(_lightSampleInterval, (_) {
      _sampleLight(token);
    });
  }

  Future<void> _sampleLight(int token) async {
    if (!_isTokenValid(token) || _isSamplingLight) return;
    if (_stage != _Stage.checking) return;

    _isSamplingLight = true;
    try {
      final sample = await _readLight();
      if (!_isTokenValid(token) || _stage != _Stage.checking) return;

      // A camera that will not give a reading should not strand the user: the
      // guide waives the gate rather than blocking the flow on it.
      final passed = sample == null ? true : _lightGate.accept(sample);
      final since = _checkingSince ?? DateTime.now();
      final heldLongEnough =
          DateTime.now().difference(since) >= _minCheckingTime;

      setState(() {
        _progress = passed
            ? 1.0
            : (_progress + 0.06).clamp(0.0, 0.9).toDouble();
      });

      if (passed && heldLongEnough) {
        _lightTimer?.cancel();
        await _onLightGatePassed(token);
      }
    } finally {
      _isSamplingLight = false;
    }
  }

  /// Reads one frame's luminance and sharpness.
  ///
  /// Returns null when no reading could be taken, which the caller treats as
  /// "waive the gate" rather than "fail".
  Future<FaceLightSample?> _readLight() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return null;

    try {
      final shot = await controller.takePicture();
      final bytes = await File(shot.path).readAsBytes();
      // The probe frame is a measurement, not evidence — delete it rather
      // than leaving face images around the temp directory.
      unawaited(File(shot.path).delete().catchError((_) => File(shot.path)));
      return await _measure(bytes);
    } catch (_) {
      return null;
    }
  }

  Future<FaceLightSample?> _measure(Uint8List jpeg) =>
      compute(measureFaceLight, jpeg);

  Future<void> _onLightGatePassed(int token) async {
    if (!_isTokenValid(token)) return;
    setState(() => _stage = _Stage.ready);

    // Hold green so the pass is seen before the screen is taken over.
    await Future<void>.delayed(_readyHold);
    if (!_isTokenValid(token)) return;

    await _runChallenge(token);
  }

  // ── The challenge ─────────────────────────────────────────────────────────

  Future<void> _runChallenge(int token) async {
    if (!_isTokenValid(token)) return;

    final bloc = context.read<WalletBloc>();
    _cameraInactivityTimer?.cancel();
    setState(() => _stage = _Stage.running);

    // The native detector claims the front camera; ours must let go first.
    await _releaseCamera();
    if (mounted) setState(() => _isCameraInitialized = false);

    final outcome = await _controller.run(
      kycSessionId: bloc.state.kycSessionId,
      onSessionChanged: (sessionId) {
        if (!mounted) return;
        bloc.add(WalletKycSessionIdChanged(sessionId));
      },
    );

    if (!mounted || !widget.isActive) return;

    if (!outcome.succeeded) {
      await _failLiveness(outcome);
      return;
    }

    bloc.add(
      WalletKycAwsLivenessSucceeded(
        selfieImageData: outcome.selfieImageData!,
        confidence: outcome.confidence,
      ),
    );
    await _completeLivenessSuccessfully(outcome.selfieImageData!);
  }

  Future<void> _completeLivenessSuccessfully(String selfieImageData) async {
    if (_stage == _Stage.completed) return;

    // The downstream pages preview the selfie with Image.file, so the data URL
    // AWS returned is written out once here.
    final savedPath = await _saveFaceImageToFile(selfieImageData);
    if (!mounted) return;

    setState(() {
      _stage = _Stage.completed;
      _progress = 1.0;
      _capturedSelfiePath = savedPath;
    });

    // Stay on the green frame long enough for the user to register the pass.
    await Future<void>.delayed(const Duration(seconds: 3));

    if (!_didNotifySuccess && mounted) {
      _didNotifySuccess = true;
      widget.onSuccessTap?.call(_capturedSelfiePath ?? '');
    }
  }

  Future<void> _failLiveness(FaceLivenessOutcome outcome) async {
    if (!mounted) return;
    setState(() {
      _stage = _Stage.failed;
      _progress = 0;
      _failureMessage = outcome.errorKind == null
          ? null
          : _errorText(outcome.errorKind!);
    });
  }

  /// Maps a detector failure onto the one thing the user can act on.
  String? _errorText(FaceLivenessErrorKind kind) {
    final lang = context.read<WalletBloc>().state.languageCode;
    switch (kind) {
      case FaceLivenessErrorKind.cameraBlocked:
        return AppStrings.get(lang, 'kyc_camera_error');
      case FaceLivenessErrorKind.landscape:
        return AppStrings.get(lang, 'kyc_align_face');
      case FaceLivenessErrorKind.cancelled:
        return null;
      case FaceLivenessErrorKind.cameraTooSlow:
      case FaceLivenessErrorKind.setupFailed:
        return null;
    }
  }

  Future<void> _restartLiveness() async {
    _flowToken++;
    _didNotifySuccess = false;
    _capturedSelfiePath = null;
    _cameraInactivityTimer?.cancel();
    _lightGate.reset();

    context.read<WalletBloc>().add(const WalletKycLivenessResetRequested());

    if (!mounted) return;
    setState(() {
      _stage = _Stage.checking;
      _progress = 0.0;
      _failureMessage = null;
    });

    // Each retry is a brand-new AWS session; the old one is never reused.
    await _initCamera();
  }

  Future<String?> _saveFaceImageToFile(String rawFaceImageData) async {
    if (rawFaceImageData.trim().isEmpty) return null;

    try {
      final commaIndex = rawFaceImageData.indexOf(',');
      final base64Part = commaIndex >= 0
          ? rawFaceImageData.substring(commaIndex + 1)
          : rawFaceImageData;

      final bytes = base64Decode(base64Part);
      final path =
          '${Directory.systemTemp.path}${Platform.pathSeparator}'
          'kyc_liveness_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  bool _isTokenValid(int token) =>
      mounted && widget.isActive && _flowToken == token;

  /// Color of the face-guide oval: yellow while checking, green once the
  /// light is good or the person passed, red on a failure.
  Color _faceOvalColor() {
    switch (_stage) {
      case _Stage.ready:
      case _Stage.completed:
        return const Color(0xffA3FF38);
      case _Stage.failed:
        return const Color(0xffFF6B6B);
      case _Stage.checking:
      case _Stage.running:
        return const Color(0xffF5C518);
    }
  }

  String _statusText(String lang) {
    if (!_detectorAvailable) {
      return AppStrings.get(lang, 'kyc_camera_error');
    }
    switch (_stage) {
      case _Stage.completed:
        return AppStrings.get(lang, 'kyc_liveness_done');
      case _Stage.failed:
        return _failureMessage ?? AppStrings.get(lang, 'kyc_liveness_failed');
      case _Stage.running:
        return AppStrings.get(lang, 'kyc_liveness_verifying');
      case _Stage.ready:
        return AppStrings.get(lang, 'kyc_align_face');
      case _Stage.checking:
        return _lightGateText(lang);
    }
  }

  /// What is wrong with the light, in the one sentence that fixes it.
  String _lightGateText(String lang) {
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
        return AppStrings.get(lang, 'kyc_align_face');
    }
  }

  Widget _buildCameraPreview() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return Container(color: const Color(0xffF5F5F5));
    }

    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return CameraPreview(controller);
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: previewSize.height,
        height: previewSize.width,
        child: CameraPreview(controller),
      ),
    );
  }

  @override
  void dispose() {
    _flowToken++;
    _lightTimer?.cancel();
    _cameraInactivityTimer?.cancel();
    _cameraController?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        final lang = state.languageCode;
        final isCompleted = _stage == _Stage.completed;
        final hasFailed = _stage == _Stage.failed;

        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 100.h),
            Text(
              AppStrings.get(lang, 'kyc_identity_verification'),
              style: context.textTheme.titleLarge?.bq.copyWith(
                color: const Color(0xff1D1D1D),
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
                  crossAxisAlignment: CrossAxisAlignment.center,
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
                        color: const Color(0xff1D1D1D),
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
                    color: isCompleted
                        ? const Color(0xffA3FF38)
                        : hasFailed
                        ? const Color(0xffFF6B6B)
                        : const Color(0xff388CFF),
                    width: isCompleted ? 2 : 0.5,
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30.r),
                      child: _isCameraError
                          ? Container(
                              color: const Color(0xffF5F5F5),
                              alignment: Alignment.center,
                              child: Text(
                                AppStrings.get(lang, 'kyc_camera_error'),
                                textAlign: TextAlign.center,
                                style: context.textTheme.titleLarge?.rq
                                    .copyWith(
                                      color: const Color(0xff1D1D1D),
                                      fontSize: 14.sp,
                                    ),
                              ),
                            )
                          : _isCameraTimedOut
                          ? Container(
                              color: Colors.black,
                              alignment: Alignment.center,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      AppStrings.get(
                                        lang,
                                        'kyc_camera_auto_closed',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: context.textTheme.titleLarge?.rq
                                          .copyWith(
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
                                          color: const Color(0xff388CFF),
                                          borderRadius: BorderRadius.circular(
                                            10.r,
                                          ),
                                        ),
                                        child: Text(
                                          AppStrings.get(
                                            lang,
                                            'kyc_reopen_camera',
                                          ),
                                          style: context
                                              .textTheme
                                              .titleLarge
                                              ?.rq
                                              .copyWith(
                                                color: Colors.white,
                                                fontSize: 12.sp,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : isCompleted && _capturedSelfiePath != null
                          ? SizedBox.expand(
                              child: Image.file(
                                File(_capturedSelfiePath!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : _isCameraInitialized && _cameraController != null
                          ? SizedBox.expand(child: _buildCameraPreview())
                          : Container(color: const Color(0xffF5F5F5)),
                    ),
                    Positioned(
                      left: 15.w,
                      top: 20.h,
                      child: SvgPicture.asset(
                        TrydosWalletAssets.topLeft,
                        package: TrydosWalletStyles.packageName,
                        height: 18.h,
                      ),
                    ),
                    Positioned(
                      right: 15.w,
                      top: 20.h,
                      child: SvgPicture.asset(
                        TrydosWalletAssets.topRight,
                        package: TrydosWalletStyles.packageName,
                        height: 18.h,
                      ),
                    ),
                    Positioned(
                      left: 15.w,
                      bottom: 20.h,
                      child: SvgPicture.asset(
                        TrydosWalletAssets.bottomLeft,
                        package: TrydosWalletStyles.packageName,
                        height: 18.h,
                      ),
                    ),
                    Positioned(
                      right: 15.w,
                      bottom: 20.h,
                      child: SvgPicture.asset(
                        TrydosWalletAssets.bottomRight,
                        package: TrydosWalletStyles.packageName,
                        height: 18.h,
                      ),
                    ),
                    // Face-guide oval: keep the face inside it while the light
                    // is read. Hidden once completed (the selfie shows alone).
                    if (!_isCameraError && !_isCameraTimedOut && !isCompleted)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Center(
                            child: DottedBorder(
                              borderType: BorderType.Oval,
                              color: _faceOvalColor(),
                              strokeWidth: 2.5,
                              dashPattern: const [8, 6],
                              child: SizedBox(width: 190.w, height: 250.h),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 60.w),
              child: Text(
                _statusText(lang),
                textAlign: TextAlign.center,
                style: context.textTheme.titleLarge?.rq.copyWith(
                  color: hasFailed
                      ? const Color(0xffFF6B6B)
                      : const Color(0xff1D1D1D),
                  letterSpacing: 0.14,
                  height: 1.43,
                  fontSize: 14.sp,
                ),
              ),
            ),
            SizedBox(height: 10.h),
            if (_stage == _Stage.running)
              SizedBox(
                width: 22.r,
                height: 22.r,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xff388CFF),
                ),
              ),
            if (hasFailed && _detectorAvailable) ...[
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
                      letterSpacing: 0.14,
                      height: 1.43,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
            ],
            if (!isCompleted && !hasFailed)
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
                            border: Border.all(
                              color: const Color(0xff388CFF),
                              width: 0.5,
                            ),
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: _progress),
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: value,
                              child: child,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xff388CFF),
                              borderRadius: BorderRadius.circular(5.r),
                              border: Border.all(
                                color: const Color(0xff388CFF),
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
}
