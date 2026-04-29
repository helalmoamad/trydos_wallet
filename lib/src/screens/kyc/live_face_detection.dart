import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:trydos_wallet/src/bloc/wallet_bloc.dart';
import 'package:trydos_wallet/src/bloc/wallet_state.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/src/localization/app_strings.dart';

/// Digital wallet home page.
class LiveFaceDetection extends StatefulWidget {
  final Function(String selfiePath)? onSuccessTap;
  const LiveFaceDetection({super.key, this.onSuccessTap});

  @override
  State<LiveFaceDetection> createState() => _LiveFaceDetectionState();
}

enum _LivenessChallenge { lookLeft, lookRight, blink }

class _LiveFaceDetectionState extends State<LiveFaceDetection> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;

  bool _isCameraInitialized = false;
  bool _isCameraError = false;
  bool _isProcessing = false;
  bool _isStreamActive = false;
  bool _isCompleted = false;
  bool _hasFailed = false;

  final List<_LivenessChallenge> _challenges = [];
  int _currentChallengeIndex = 0;
  int _failedChallengeCount = 0;
  double _progress = 0.0;
  DateTime? _holdStart;
  DateTime? _challengeStart;

  // Selfie captured right after the blink challenge (eyes reopen = best photo)
  String? _capturedSelfiePath;
  bool _selfieCapturing = false; // true while takePicture is in progress

  // Face confirmed = challenges may begin (set synchronously on first face frame)
  bool _selfieCaptured = false;

  static const int _totalChallenges = 3;
  static const int _maxFailedChallenges = 2;
  static const Duration _holdDuration = Duration(milliseconds: 800);
  static const Duration _challengeTimeout = Duration(seconds: 8);

  @override
  void initState() {
    super.initState();
    _setupChallenges();
    _initDetector();
    _initCamera();
  }

  void _setupChallenges() {
    final all = [
      _LivenessChallenge.lookLeft,
      _LivenessChallenge.lookRight,
      _LivenessChallenge.blink,
    ];
    all.shuffle(Random());
    _challenges
      ..clear()
      ..addAll(all.take(_totalChallenges));
    _challengeStart = DateTime.now();
  }

  void _initDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableClassification: true, // needed for eye open probability (blink)
        enableLandmarks: false,
        enableContours: false,
      ),
    );
  }

  Future<void> _initCamera() async {
    try {
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
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _isCameraInitialized = true);

      await _cameraController!.startImageStream(_onCameraImage);
      _isStreamActive = true;
    } catch (_) {
      if (mounted) setState(() => _isCameraError = true);
    }
  }

  Future<void> _onCameraImage(CameraImage image) async {
    if (_isProcessing || _isCompleted || _hasFailed) return;
    _isProcessing = true;
    try {
      // Timeout check only runs once challenges have actually started
      if (_selfieCaptured &&
          _challengeStart != null &&
          DateTime.now().difference(_challengeStart!) >= _challengeTimeout) {
        await _registerChallengeFailure();
        return;
      }

      final input = _convertToInputImage(image);
      if (input == null || _faceDetector == null) return;

      final faces = await _faceDetector!.processImage(input);
      if (!mounted) return;

      if (faces.isEmpty) {
        _holdStart = null;
        return;
      }

      // Confirm face presence synchronously — no photo needed here
      if (!_selfieCaptured) {
        _selfieCaptured = true;
        _challengeStart = DateTime.now();
        if (mounted) setState(() {});
        return;
      }

      final face = faces.first;
      final ok = _isChallengeSatisfied(face);
      if (ok) {
        _holdStart ??= DateTime.now();
        final held = DateTime.now().difference(_holdStart!);
        if (held >= _holdDuration) {
          final justCompleted = _challenges[_currentChallengeIndex];
          _holdStart = null;
          _currentChallengeIndex++;
          final isLast = _currentChallengeIndex >= _totalChallenges;

          // After blink: wait 1 s then take photo (eyes fully reopen = best frame)
          if (justCompleted == _LivenessChallenge.blink &&
              !_selfieCapturing &&
              _capturedSelfiePath == null) {
            _selfieCapturing = true;
            Future.microtask(
              () => _capturePostBlinkSelfie(proceedToComplete: isLast),
            );
            if (isLast)
              return; // _capturePostBlinkSelfie will call _completeLiveness
          }

          if (isLast) {
            await _completeLiveness();
            return;
          }
          _challengeStart = DateTime.now();
        }
      } else {
        _holdStart = null;
      }

      final baseProgress = _currentChallengeIndex / _totalChallenges;
      final holdPart = _holdStart == null
          ? 0.0
          : (DateTime.now().difference(_holdStart!).inMilliseconds /
                        _holdDuration.inMilliseconds)
                    .clamp(0.0, 1.0) /
                _totalChallenges;
      final next = (baseProgress + holdPart).clamp(0.0, 1.0);
      if ((_progress - next).abs() > 0.001) {
        setState(() => _progress = next);
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _registerChallengeFailure() async {
    _failedChallengeCount++;
    _holdStart = null;

    if (_failedChallengeCount >= _maxFailedChallenges) {
      await _failLiveness();
      return;
    }

    _challengeStart = DateTime.now();
    setState(() {
      _progress = (_currentChallengeIndex / _totalChallenges).clamp(0.0, 1.0);
    });
  }

  Future<void> _failLiveness() async {
    if (_hasFailed || _isCompleted) return;
    _hasFailed = true;

    if (_isStreamActive) {
      await _cameraController?.stopImageStream();
      _isStreamActive = false;
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _restartLiveness() async {
    _holdStart = null;
    _challengeStart = null;
    _currentChallengeIndex = 0;
    _failedChallengeCount = 0;
    _capturedSelfiePath = null;
    _selfieCaptured = false;
    _selfieCapturing = false;

    setState(() {
      _hasFailed = false;
      _isCompleted = false;
      _progress = 0.0;
    });

    _setupChallenges();

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      await _initCamera();
      return;
    }

    if (!_isStreamActive) {
      await _cameraController!.startImageStream(_onCameraImage);
      _isStreamActive = true;
    }
  }

  bool _isChallengeSatisfied(Face face) {
    if (_currentChallengeIndex >= _challenges.length) return false;
    final challenge = _challenges[_currentChallengeIndex];
    final yaw = face.headEulerAngleY ?? 0.0;

    switch (challenge) {
      case _LivenessChallenge.lookLeft:
        return yaw > 15;
      case _LivenessChallenge.lookRight:
        return yaw < -15;
      case _LivenessChallenge.blink:
        // Both eyes closed: open probability < 0.3
        final leftOpen = face.leftEyeOpenProbability ?? 1.0;
        final rightOpen = face.rightEyeOpenProbability ?? 1.0;
        return leftOpen < 0.3 && rightOpen < 0.3;
    }
  }

  /// Stops the stream, waits 1 s for eyes to fully reopen after blink,
  /// takes the selfie, then restarts stream (or completes liveness if last).
  Future<void> _capturePostBlinkSelfie({
    required bool proceedToComplete,
  }) async {
    try {
      if (_isStreamActive) {
        await _cameraController?.stopImageStream();
        _isStreamActive = false;
      }
      // Let eyes fully reopen before capturing
      await Future.delayed(const Duration(seconds: 1));
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final xFile = await _cameraController!.takePicture();
        _capturedSelfiePath = xFile.path;
      }
    } catch (_) {
      // selfie stays null — completeLiveness has a fallback
    } finally {
      _selfieCapturing = false;
      if (proceedToComplete) {
        await _completeLiveness();
      } else if (!_isCompleted &&
          !_hasFailed &&
          _cameraController != null &&
          _cameraController!.value.isInitialized) {
        try {
          await _cameraController!.startImageStream(_onCameraImage);
          _isStreamActive = true;
          _challengeStart = DateTime.now();
        } catch (_) {}
      }
    }
  }

  Future<void> _completeLiveness() async {
    if (_isCompleted) return;
    _isCompleted = true;
    setState(() => _progress = 1.0);

    if (_isStreamActive) {
      await _cameraController?.stopImageStream();
      _isStreamActive = false;
    }

    // Use the pre-challenge selfie if available; fallback to capturing now
    if (_capturedSelfiePath == null) {
      try {
        if (_cameraController != null &&
            _cameraController!.value.isInitialized) {
          final xFile = await _cameraController!.takePicture();
          _capturedSelfiePath = xFile.path;
        }
      } catch (_) {}
    }

    if (mounted) setState(() {}); // show captured photo in green frame
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) widget.onSuccessTap?.call(_capturedSelfiePath ?? '');
  }

  InputImage? _convertToInputImage(CameraImage image) {
    if (_cameraController == null) return null;
    final camera = _cameraController!.description;
    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    );
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    final bytes = _concatenatePlanes(image.planes);
    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final allBytes = WriteBuffer();
    for (final plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  String _currentChallengeText(String lang) {
    if (_hasFailed) {
      return AppStrings.get(lang, 'kyc_liveness_failed');
    }
    if (_isCompleted) {
      return AppStrings.get(lang, 'kyc_liveness_done');
    }
    if (_currentChallengeIndex >= _challenges.length) {
      return AppStrings.get(lang, 'kyc_liveness_verifying');
    }
    final challenge = _challenges[_currentChallengeIndex];
    switch (challenge) {
      case _LivenessChallenge.lookLeft:
        return AppStrings.get(lang, 'kyc_liveness_turn_left');
      case _LivenessChallenge.lookRight:
        return AppStrings.get(lang, 'kyc_liveness_turn_right');
      case _LivenessChallenge.blink:
        return AppStrings.get(lang, 'kyc_liveness_blink');
    }
  }

  @override
  void dispose() {
    if (_isStreamActive) {
      _cameraController?.stopImageStream();
    }
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
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
                          // Show the captured photo (not live camera) in success frame
                          : _isCompleted && _capturedSelfiePath != null
                          ? SizedBox.expand(
                              child: Image.file(
                                File(_capturedSelfiePath!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : _isCameraInitialized && _cameraController != null
                          ? SizedBox.expand(
                              child: CameraPreview(_cameraController!),
                            )
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
              // ---- Phase 1: waiting for face / capturing selfie ----
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
                if (_selfieCapturing)
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
                // ---- Phase 2: challenges ----
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
            ],
          ],
        );
      },
    );
  }
}
