import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

/// Digital wallet home page.
class LiveFaceDetection extends StatefulWidget {
  final Function(String selfiePath)? onSuccessTap;
  final bool isActive;
  const LiveFaceDetection({super.key, this.onSuccessTap, this.isActive = true});

  @override
  State<LiveFaceDetection> createState() => _LiveFaceDetectionState();
}

enum _LivenessChallenge { lookStraight, turnRight, turnLeft }

class _LiveFaceDetectionState extends State<LiveFaceDetection> {
  CameraController? _cameraController;
  static const double _defaultFrontZoomLevel = 1.15;

  bool _isCameraInitialized = false;
  bool _isCameraError = false;
  bool _isCameraTimedOut = false;
  bool _isCompleted = false;
  bool _hasFailed = false;
  bool _isRequestInFlight = false;
  bool _selfieCaptured = false;
  Timer? _cameraInactivityTimer;

  final List<_LivenessChallenge> _challenges = <_LivenessChallenge>[
    _LivenessChallenge.lookStraight,
    _LivenessChallenge.turnRight,
    _LivenessChallenge.turnLeft,
  ];

  int _currentChallengeIndex = 0;
  double _progress = 0.0;

  String? _capturedSelfiePath;
  String? _firstChallengeFaceImageData;
  String? _firstChallengeSelfiePath;
  WalletStatus _lastKycLivenessStatus = WalletStatus.initial;

  int _flowToken = 0;
  bool _isFlowRunning = false;
  bool _didNotifySuccess = false;

  static const int _maxAttemptsPerChallenge = 3;
  static const Duration _initialDelay = Duration(seconds: 2);
  static const Duration _attemptInterval = Duration(seconds: 2);
  static const Duration _cameraInactivityTimeout = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      _initCamera();
    }
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
      _isFlowRunning = false;
      _cameraInactivityTimer?.cancel();
      try {
        await _cameraController?.dispose();
      } catch (_) {}
      _cameraController = null;
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
      return;
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      await _initCamera();
      return;
    }

    _startLivenessFlow();
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

      _startLivenessFlow();
    } catch (_) {
      if (mounted) setState(() => _isCameraError = true);
    }
  }

  void _resetCameraInactivityTimer() {
    _cameraInactivityTimer?.cancel();
    if (!widget.isActive || _isCompleted || _hasFailed || _isCameraError) {
      return;
    }

    _cameraInactivityTimer = Timer(
      _cameraInactivityTimeout,
      _handleCameraInactivityTimeout,
    );
  }

  Future<void> _handleCameraInactivityTimeout() async {
    if (!mounted || !widget.isActive || _isCompleted) return;

    _flowToken++;
    _isFlowRunning = false;
    _cameraInactivityTimer?.cancel();

    try {
      await _cameraController?.dispose();
    } catch (_) {}
    _cameraController = null;

    if (!mounted) return;
    setState(() {
      _isCameraInitialized = false;
      _isCameraTimedOut = true;
      _isCameraError = false;
      _isRequestInFlight = false;
    });
  }

  Future<void> _reopenCameraAfterTimeout() async {
    if (!widget.isActive || _isCompleted) return;

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
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

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

  void _startLivenessFlow() {
    if (!mounted || !widget.isActive) return;
    if (_isFlowRunning || _hasFailed || _isCompleted || !_isCameraInitialized) {
      return;
    }

    _resetCameraInactivityTimer();

    final token = ++_flowToken;
    _isFlowRunning = true;
    _runLivenessFlow(token);
  }

  Future<void> _runLivenessFlow(int token) async {
    await _delayWithToken(_initialDelay, token);
    if (!_isTokenValid(token)) {
      _isFlowRunning = false;
      return;
    }

    if (mounted) {
      setState(() {
        _selfieCaptured = true;
      });
    }

    for (
      var challengeIndex = _currentChallengeIndex;
      challengeIndex < _challenges.length;
      challengeIndex++
    ) {
      if (!_isTokenValid(token)) {
        _isFlowRunning = false;
        return;
      }

      var success = false;
      for (var attempt = 1; attempt <= _maxAttemptsPerChallenge; attempt++) {
        final attemptSuccess = await _executeChallengeAttempt(
          challenge: _challenges[challengeIndex],
          token: token,
        );

        if (!_isTokenValid(token)) {
          _isFlowRunning = false;
          return;
        }

        if (attemptSuccess) {
          success = true;
          break;
        }

        if (attempt < _maxAttemptsPerChallenge) {
          await _delayWithToken(_attemptInterval, token);
          if (!_isTokenValid(token)) {
            _isFlowRunning = false;
            return;
          }
        }
      }

      if (!success) {
        await _failLiveness();
        _isFlowRunning = false;
        return;
      }

      if (mounted) {
        setState(() {
          _currentChallengeIndex = challengeIndex + 1;
          _progress = (_currentChallengeIndex / _challenges.length).clamp(
            0.0,
            1.0,
          );
        });
      }

      if (_currentChallengeIndex < _challenges.length) {
        await _delayWithToken(_attemptInterval, token);
      }
    }

    if (_isTokenValid(token)) {
      await _completeLivenessSuccessfully();
    }
    _isFlowRunning = false;
  }

  Future<bool> _executeChallengeAttempt({
    required _LivenessChallenge challenge,
    required int token,
  }) async {
    if (!_isTokenValid(token)) return false;

    if (mounted) {
      setState(() => _isRequestInFlight = true);
    }

    try {
      final selfiePath = await _captureSelfie();
      if (selfiePath == null || !_isTokenValid(token)) {
        return false;
      }

      final bytes = await File(selfiePath).readAsBytes();
      final faceImageData = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final state = await _sendLivenessRequest(
        faceImageData: faceImageData,
        challengeStep: _apiChallengeStep(challenge),
      );

      if (!_isTokenValid(token)) return false;

      final success =
          state.kycLivenessStatus == WalletStatus.success &&
          state.selfieImageData != null;

      if (success) {
        _resetCameraInactivityTimer();
        if (_currentChallengeIndex == 0 &&
            _firstChallengeFaceImageData == null) {
          _firstChallengeFaceImageData = state.selfieImageData;
          _firstChallengeSelfiePath = selfiePath;
        }
      }

      return success;
    } catch (_) {
      return false;
    } finally {
      if (mounted) {
        setState(() => _isRequestInFlight = false);
      }
    }
  }

  Future<WalletState> _sendLivenessRequest({
    required String faceImageData,
    required String challengeStep,
  }) async {
    final bloc = context.read<WalletBloc>();
    bloc.add(const WalletKycLivenessResetRequested());
    bloc.add(
      WalletKycLivenessRequested(
        faceImageData: faceImageData,
        challengeStep: challengeStep,
      ),
    );

    return bloc.stream.firstWhere(
      (state) =>
          state.kycLivenessStatus == WalletStatus.success ||
          state.kycLivenessStatus == WalletStatus.failure,
    );
  }

  Future<void> _completeLivenessSuccessfully() async {
    if (_isCompleted || _hasFailed) return;

    final savedPath = await _saveApiFaceImageToFile(
      _firstChallengeFaceImageData,
    );
    if (savedPath != null) {
      _capturedSelfiePath = savedPath;
    } else if (_firstChallengeSelfiePath != null) {
      _capturedSelfiePath = _firstChallengeSelfiePath;
    }

    if (!mounted) return;

    setState(() {
      _isCompleted = true;
      _progress = 1.0;
    });

    final selfieToUpload = _capturedSelfiePath;
    if (selfieToUpload != null && selfieToUpload.isNotEmpty) {
      await _uploadSelfieAndAdvance(selfieToUpload);
    } else {
      // No image path available — advance without upload as fallback
      if (!_didNotifySuccess && mounted) {
        _didNotifySuccess = true;
        widget.onSuccessTap?.call(_capturedSelfiePath ?? '');
      }
    }
  }

  Future<void> _uploadSelfieAndAdvance(String selfiePath) async {
    if (!mounted) return;
    final bloc = context.read<WalletBloc>();
    bloc.add(const WalletKycSelfieUploadResetRequested());
    bloc.add(WalletKycSelfieUploadRequested(imagePath: selfiePath));

    try {
      final uploadState = await bloc.stream.firstWhere(
        (s) =>
            s.kycSelfieUploadStatus == WalletStatus.success ||
            s.kycSelfieUploadStatus == WalletStatus.failure,
      );

      if (!mounted) return;

      if (uploadState.kycSelfieUploadStatus == WalletStatus.success) {
        if (!_didNotifySuccess) {
          _didNotifySuccess = true;
          widget.onSuccessTap?.call(_capturedSelfiePath ?? '');
        }
      }
      // On failure: UI shows retry via kycSelfieUploadStatus in builder
    } catch (_) {
      // Stream closed before upload completed
    }
  }

  Future<void> _retrySelfieUpload() async {
    final selfieToUpload = _capturedSelfiePath;
    if (selfieToUpload == null || selfieToUpload.isEmpty) return;
    await _uploadSelfieAndAdvance(selfieToUpload);
  }

  Future<void> _failLiveness() async {
    if (_hasFailed || _isCompleted) return;
    if (!mounted) return;

    setState(() {
      _hasFailed = true;
      _progress = (_currentChallengeIndex / _challenges.length).clamp(0.0, 1.0);
    });
  }

  Future<void> _restartLiveness() async {
    _flowToken++;
    _isFlowRunning = false;
    _didNotifySuccess = false;
    _cameraInactivityTimer?.cancel();
    _firstChallengeFaceImageData = null;
    _firstChallengeSelfiePath = null;
    _capturedSelfiePath = null;

    context.read<WalletBloc>().add(const WalletKycLivenessResetRequested());
    context.read<WalletBloc>().add(const WalletKycSelfieUploadResetRequested());

    if (!mounted) return;

    setState(() {
      _isCompleted = false;
      _hasFailed = false;
      _selfieCaptured = false;
      _isRequestInFlight = false;
      _currentChallengeIndex = 0;
      _progress = 0.0;
    });

    _startLivenessFlow();
  }

  Future<String?> _captureSelfie() async {
    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        return null;
      }
      final file = await _cameraController!.takePicture();
      return file.path;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _saveApiFaceImageToFile(String? rawFaceImageData) async {
    if (rawFaceImageData == null || rawFaceImageData.trim().isEmpty) {
      return null;
    }

    try {
      final commaIndex = rawFaceImageData.indexOf(',');
      final base64Part = commaIndex >= 0
          ? rawFaceImageData.substring(commaIndex + 1)
          : rawFaceImageData;

      final bytes = base64Decode(base64Part);
      final path =
          '${Directory.systemTemp.path}${Platform.pathSeparator}kyc_liveness_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(path);
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  String _apiChallengeStep(_LivenessChallenge challenge) {
    switch (challenge) {
      case _LivenessChallenge.lookStraight:
        return 'look_straight';
      case _LivenessChallenge.turnRight:
        return 'turn_right';
      case _LivenessChallenge.turnLeft:
        return 'turn_left';
    }
  }

  bool _isTokenValid(int token) =>
      mounted && widget.isActive && _flowToken == token;

  Future<void> _delayWithToken(Duration duration, int token) async {
    await Future.delayed(duration);
    if (!_isTokenValid(token)) return;
  }

  String _currentChallengeText(String lang) {
    if (_hasFailed) {
      return AppStrings.get(lang, 'kyc_liveness_failed');
    }
    if (_isCompleted) {
      return AppStrings.get(lang, 'kyc_liveness_done');
    }
    if (_isRequestInFlight) {
      return AppStrings.get(lang, 'kyc_liveness_verifying');
    }
    if (_currentChallengeIndex >= _challenges.length) {
      return AppStrings.get(lang, 'kyc_liveness_verifying');
    }

    final challenge = _challenges[_currentChallengeIndex];
    switch (challenge) {
      case _LivenessChallenge.lookStraight:
        return AppStrings.get(lang, 'kyc_align_face');
      case _LivenessChallenge.turnRight:
        return AppStrings.get(lang, 'kyc_liveness_turn_right');
      case _LivenessChallenge.turnLeft:
        return AppStrings.get(lang, 'kyc_liveness_turn_left');
    }
  }

  @override
  void dispose() {
    _flowToken++;
    _cameraInactivityTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletBloc, WalletState>(
      listener: (context, state) {
        final livenessStatus = state.kycLivenessStatus;
        if (livenessStatus != _lastKycLivenessStatus) {
          _lastKycLivenessStatus = livenessStatus;
        }
      },
      builder: (context, state) {
        final lang = state.languageCode;
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
                    color: _isCompleted
                        ? const Color(0xffA3FF38)
                        : _hasFailed
                        ? const Color(0xffFF6B6B)
                        : const Color(0xff388CFF),
                    width: _isCompleted ? 2 : 0.5,
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
                          : _isCompleted && _capturedSelfiePath != null
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
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.h),
            if (!_isCompleted) ...[
              if (!_selfieCaptured) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 60.w),
                  child: Text(
                    AppStrings.get(lang, 'kyc_align_face'),
                    textAlign: TextAlign.center,
                    style: context.textTheme.titleLarge?.rq.copyWith(
                      color: const Color(0xff388CFF),
                      letterSpacing: 0.14,
                      height: 1.43,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                if (_isRequestInFlight)
                  SizedBox(
                    width: 22.r,
                    height: 22.r,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xff388CFF),
                    ),
                  ),
                const Spacer(),
              ] else ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 60.w),
                  child: Text(
                    _currentChallengeText(lang),
                    textAlign: TextAlign.center,
                    style: context.textTheme.titleLarge?.rq.copyWith(
                      color: const Color(0xff1D1D1D),
                      letterSpacing: 0.14,
                      height: 1.43,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                if (_hasFailed) ...[
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
            ] else ...[
              if (state.kycSelfieUploadStatus == WalletStatus.failure) ...[
                SizedBox(height: 10.h),
                InkWell(
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onTap: _retrySelfieUpload,
                  child: Text(
                    AppStrings.get(lang, 'kyc_incorrect_try_again'),
                    style: context.textTheme.titleLarge?.rq.copyWith(
                      color: const Color(0xffFF6B6B),
                      letterSpacing: 0.14,
                      height: 1.43,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ] else if (state.kycLivenessStatus == WalletStatus.failure) ...[
                SizedBox(height: 10.h),
                InkWell(
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onTap: _restartLiveness,
                  child: Text(
                    AppStrings.get(lang, 'kyc_incorrect_try_again'),
                    style: context.textTheme.titleLarge?.rq.copyWith(
                      color: const Color(0xffFF6B6B),
                      letterSpacing: 0.14,
                      height: 1.43,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }
}
