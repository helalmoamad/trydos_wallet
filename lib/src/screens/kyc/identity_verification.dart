import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:shimmer/shimmer.dart';
import 'package:trydos_wallet/src/bloc/wallet_bloc.dart';
import 'package:trydos_wallet/src/bloc/wallet_event.dart';
import 'package:trydos_wallet/src/bloc/wallet_state.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/src/localization/app_strings.dart';

enum _ScanStep { front, back, done }

enum _DistanceStatus { ok, tooFar, tooClose }

/// KYC identity verification — auto-detects & captures front then back of ID
/// using Google ML Kit Object Detection on both iOS and Android.
class IdentityVerification extends StatefulWidget {
  final Function(String frontPath, String backPath)? onSuccessTap;
  final bool isActive;
  const IdentityVerification({
    super.key,
    this.onSuccessTap,
    this.isActive = true,
  });

  @override
  State<IdentityVerification> createState() => _IdentityVerificationState();
}

class _IdentityVerificationState extends State<IdentityVerification> {
  CameraController? _cameraController;
  ObjectDetector? _objectDetector;

  bool _isCameraInitialized = false;
  bool _isCameraError = false;
  bool _isLowLight = false;
  bool _isProcessing = false;
  bool _isStreamActive = false;
  bool _isCapturing = false;
  int _frameCounter = 0;

  _DistanceStatus _distanceStatus = _DistanceStatus.tooFar;

  _ScanStep _step = _ScanStep.front;
  double _detectProgress = 0.0;

  String? _frontImagePath;
  String? _backImagePath;
  late final String _sessionHint;
  WalletStatus _lastFrontAnalyzeStatus = WalletStatus.initial;
  WalletStatus _lastBackAnalyzeStatus = WalletStatus.initial;

  Rect? _lastBoundingBox;
  // Effective (display-oriented) stream size — ML Kit bbox is in this space.
  // For sensorOrientation 90°/270° the raw axes are swapped.
  Size? _lastEffectiveStreamSize;

  // Consecutive document-like frames needed before progress starts
  static const int _kConsecutiveRequired = 3;
  static const int _kProcessEveryNFrames = 3;
  int _consecutiveDocFrames = 0;

  @override
  void initState() {
    super.initState();
    _sessionHint = DateTime.now().millisecondsSinceEpoch.toString();
    context.read<WalletBloc>().add(const WalletKycAnalyzeIdResetRequested());
    _initDetector();
    if (widget.isActive) {
      _initCamera();
    }
  }

  @override
  void didUpdateWidget(covariant IdentityVerification oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _handlePageActivityChange(widget.isActive);
    }
  }

  Future<void> _handlePageActivityChange(bool isActive) async {
    if (!mounted) return;
    if (isActive) {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        await _initCamera();
        return;
      }
      if (!_isStreamActive && !_isCapturing && _step != _ScanStep.done) {
        try {
          await _cameraController!.startImageStream(_onCameraImage);
          _isStreamActive = true;
        } catch (_) {}
      }
      return;
    }

    if (_isStreamActive) {
      try {
        await _cameraController?.stopImageStream();
      } catch (_) {}
      _isStreamActive = false;
    }
  }

  void _initDetector() {
    _objectDetector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.stream,
        classifyObjects: false,
        multipleObjects: false,
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
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() => _isCameraInitialized = true);
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted || !widget.isActive) return;
      await _cameraController!.startImageStream(_onCameraImage);
      _isStreamActive = true;
    } catch (_) {
      if (mounted) setState(() => _isCameraError = true);
    }
  }

  void _onCameraImage(CameraImage image) async {
    if (!widget.isActive) return;
    if (_isProcessing || _isCapturing || _step == _ScanStep.done) return;
    _frameCounter++;
    if (_frameCounter % _kProcessEveryNFrames != 0) return;
    _isProcessing = true;
    try {
      _checkLuminance(image);
      if (_isLowLight) {
        if (_detectProgress > 0 && mounted) {
          setState(
            () => _detectProgress = (_detectProgress - 0.05).clamp(0.0, 1.0),
          );
        }
        return;
      }
      final inputImage = _convertToInputImage(image);
      if (inputImage == null) return;
      final objects = await _objectDetector!.processImage(inputImage);
      if (!mounted) return;
      if (objects.isNotEmpty &&
          _isDocumentLike(objects.first, image.width, image.height)) {
        _consecutiveDocFrames++;
        if (_consecutiveDocFrames >= _kConsecutiveRequired) {
          _lastBoundingBox = objects.first.boundingBox;
          // ML Kit rotates the image internally and returns bbox in the
          // rotated (display-oriented) space. For 90°/270° sensors swap axes.
          final orient = _cameraController!.description.sensorOrientation;
          final swapAxes = orient == 90 || orient == 270;
          _lastEffectiveStreamSize = swapAxes
              ? Size(image.height.toDouble(), image.width.toDouble())
              : Size(image.width.toDouble(), image.height.toDouble());
          final next = (_detectProgress + 0.09).clamp(0.0, 1.0);
          setState(() => _detectProgress = next);
          if (next >= 1.0 && !_isCapturing) {
            _isCapturing = true;
            _captureAndAdvance();
          }
        }
      } else {
        _consecutiveDocFrames = 0;
        // Update distance only if no object at all (already set inside _isDocumentLike)
        if (objects.isEmpty) {
          if (_distanceStatus != _DistanceStatus.tooFar && mounted) {
            setState(() => _distanceStatus = _DistanceStatus.tooFar);
          }
        }
        if (_detectProgress > 0) {
          setState(
            () => _detectProgress = (_detectProgress - 0.10).clamp(0.0, 1.0),
          );
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  /// Returns true only when the detected object looks like a document:
  /// - covers 18%–80% of the frame
  /// - aspect ratio 1.2–2.2 (ID cards portrait/landscape, passports, driving licences)
  /// - bounding box sides each ≥ 60px in stream space
  ///
  /// Also updates [_distanceStatus] as a side-effect for UI feedback.
  bool _isDocumentLike(DetectedObject obj, int imgW, int imgH) {
    final bbox = obj.boundingBox;
    if (bbox.width < 60 || bbox.height < 60) {
      if (_distanceStatus != _DistanceStatus.tooFar && mounted) {
        setState(() => _distanceStatus = _DistanceStatus.tooFar);
      }
      return false;
    }
    final imgArea = imgW * imgH;
    if (imgArea == 0) return false;
    final coverageRatio = (bbox.width * bbox.height) / imgArea;

    // Distance feedback
    final newStatus = coverageRatio < 0.10
        ? _DistanceStatus.tooFar
        : coverageRatio > 0.85
        ? _DistanceStatus.tooClose
        : _DistanceStatus.ok;
    if (newStatus != _distanceStatus && mounted) {
      setState(() => _distanceStatus = newStatus);
    }

    if (coverageRatio < 0.10 || coverageRatio > 0.85) return false;

    // Always use long/short so both orientations are accepted
    final long = bbox.width >= bbox.height ? bbox.width : bbox.height;
    final short = bbox.width >= bbox.height ? bbox.height : bbox.width;
    if (short == 0) return false;
    final ratio = long / short;
    return ratio >= 1.2 && ratio <= 2.2;
  }

  void _checkLuminance(CameraImage image) {
    if (image.planes.isEmpty) return;
    final bytes = image.planes[0].bytes;
    if (bytes.isEmpty) return;
    int total = 0;
    final step = (bytes.length ~/ 200).clamp(1, bytes.length);
    int count = 0;
    for (int i = 0; i < bytes.length; i += step) {
      total += bytes[i];
      count++;
    }
    final avg = count > 0 ? total / count : 128.0;
    final lowLight = avg < 60;
    if (lowLight != _isLowLight && mounted) {
      setState(() => _isLowLight = lowLight);
    }
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
    if (image.planes.length == 1) {
      return InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    }
    final WriteBuffer buffer = WriteBuffer();
    for (final Plane plane in image.planes) {
      buffer.putUint8List(plane.bytes);
    }
    return InputImage.fromBytes(
      bytes: buffer.done().buffer.asUint8List(),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  /// Crops the captured JPEG to the detected document bounding box.
  ///
  /// ML Kit returns bbox in display-oriented (rotated) space matching
  /// [_lastEffectiveStreamSize]. After [img.bakeOrientation] the captured
  /// photo is in the same display orientation — direct proportional mapping.
  Future<void> _cropToDocument(String imagePath) async {
    if (_lastBoundingBox == null || _lastEffectiveStreamSize == null) return;
    try {
      final bytes = await File(imagePath).readAsBytes();
      var photo = img.decodeImage(bytes);
      if (photo == null) return;
      photo = img.bakeOrientation(photo);

      final effW = _lastEffectiveStreamSize!.width;
      final effH = _lastEffectiveStreamSize!.height;
      final bbox = _lastBoundingBox!;

      // Both bbox and photo are in display orientation — direct mapping.
      final nL = (bbox.left / effW).clamp(0.0, 1.0);
      final nT = (bbox.top / effH).clamp(0.0, 1.0);
      final nR = (bbox.right / effW).clamp(0.0, 1.0);
      final nB = (bbox.bottom / effH).clamp(0.0, 1.0);

      // Sanity check: crop must be non-trivial and a valid rectangle
      if (nR - nL < 0.05 || nB - nT < 0.05) return;

      // Use a relative margin (2% of each dimension) with a floor of 20px
      // so the full document edge is always included regardless of resolution.
      final mX = (photo.width * 0.02).toInt().clamp(20, 80);
      final mY = (photo.height * 0.02).toInt().clamp(20, 80);

      final x = ((nL * photo.width).toInt() - mX).clamp(0, photo.width - 1);
      final y = ((nT * photo.height).toInt() - mY).clamp(0, photo.height - 1);
      final w = ((nR - nL) * photo.width).toInt() + mX * 2;
      final h = ((nB - nT) * photo.height).toInt() + mY * 2;
      final safeW = w.clamp(1, photo.width - x);
      final safeH = h.clamp(1, photo.height - y);

      final cropped = img.copyCrop(
        photo,
        x: x,
        y: y,
        width: safeW,
        height: safeH,
      );
      await File(imagePath).writeAsBytes(img.encodeJpg(cropped, quality: 92));
    } catch (_) {
      // Cropping failed — keep original photo
    }
  }

  Future<void> _captureAndAdvance() async {
    try {
      if (_isStreamActive) {
        await _cameraController!.stopImageStream();
        _isStreamActive = false;
      }
      await Future.delayed(const Duration(milliseconds: 200));
      final xFile = await _cameraController!.takePicture();
      await _cropToDocument(xFile.path);
      if (!mounted) return;
      if (_step == _ScanStep.front) {
        setState(() {
          _frontImagePath = xFile.path;
          _detectProgress = 0.0;
        });
        context.read<WalletBloc>().add(
          WalletKycAnalyzeIdRequested(
            imagePath: xFile.path,
            side: 'front',
            sessionHint: _sessionHint,
          ),
        );
      } else if (_step == _ScanStep.back) {
        setState(() {
          _backImagePath = xFile.path;
          _detectProgress = 0.0;
        });
        context.read<WalletBloc>().add(
          WalletKycAnalyzeIdRequested(
            imagePath: xFile.path,
            side: 'back',
            sessionHint: _sessionHint,
          ),
        );
      }
    } catch (_) {
      if (mounted &&
          _cameraController != null &&
          _cameraController!.value.isInitialized &&
          !_isStreamActive) {
        try {
          await _cameraController!.startImageStream(_onCameraImage);
          _isStreamActive = true;
        } catch (_) {}
      }
    } finally {
      if (mounted) _isCapturing = false;
    }
  }

  Future<void> _retryUpload(_ScanStep side) async {
    final imagePath = side == _ScanStep.front
        ? _frontImagePath
        : _backImagePath;
    if (imagePath == null) return;
    context.read<WalletBloc>().add(
      WalletKycAnalyzeIdRequested(
        imagePath: imagePath,
        side: side == _ScanStep.front ? 'front' : 'back',
        sessionHint: _sessionHint,
      ),
    );
  }

  Future<void> _handleFrontAnalyzeSuccess(String imagePath) async {
    if (!mounted) return;
    setState(() {
      _frontImagePath = imagePath;
      _step = _ScanStep.back;
      _detectProgress = 0.0;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      if (!_isStreamActive) {
        if (!widget.isActive) return;
        await _cameraController!.startImageStream(_onCameraImage);
        _isStreamActive = true;
      }
    }
  }

  Future<void> _handleBackAnalyzeSuccess(String imagePath) async {
    if (!mounted) return;
    setState(() {
      _backImagePath = imagePath;
      _step = _ScanStep.done;
      _detectProgress = 1.0;
    });
    await Future.delayed(const Duration(seconds: 1));
    if (mounted && _frontImagePath != null && _backImagePath != null) {
      widget.onSuccessTap?.call(_frontImagePath!, _backImagePath!);
    }
  }

  @override
  void dispose() {
    if (_isStreamActive) {
      _cameraController?.stopImageStream();
    }
    _cameraController?.dispose();
    _objectDetector?.close();
    super.dispose();
  }

  Widget _buildThumbnail({
    required String? imagePath,
    required WalletStatus uploadStatus,
    required _ScanStep side,
    required String? errorText,
    required String lang,
  }) {
    if (uploadStatus == WalletStatus.loading) {
      return Shimmer.fromColors(
        baseColor: const Color(0xffE6E6E6),
        highlightColor: const Color(0xffF7F7F7),
        child: Container(
          height: 96.h,
          width: 153.w,
          color: const Color(0xffEDEDED),
        ),
      );
    }

    if (uploadStatus == WalletStatus.failure) {
      return Container(
        color: const Color(0xffF8F8F8),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (errorText != null) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Text(
                    errorText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xffD64B4B),
                      fontSize: 10.sp,
                    ),
                  ),
                ),
                SizedBox(height: 6.h),
              ],
              InkWell(
                onTap: () => _retryUpload(side),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff4D84FF),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    AppStrings.get(lang, 'retry'),
                    style: TextStyle(color: Colors.white, fontSize: 11.sp),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (imagePath != null) {
      return Image.file(
        File(imagePath),
        height: 96.h,
        width: 153.w,
        fit: BoxFit.cover,
      );
    }
    return SizedBox.shrink();
  }

  /// Animated progress bar — blue fill grows as [_detectProgress] increases.
  Widget _buildProgressBar({required bool isActive, required bool isDone}) {
    return SizedBox(
      height: 5.h,
      width: 153.w,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5.r),
              border: Border.all(
                color: isActive || isDone
                    ? const Color(0xff388CFF)
                    : const Color(0xff1D1D1D),
                width: 0.5,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(5.r),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: isDone
                    ? 153.w
                    : isActive
                    ? 153.w * _detectProgress
                    : 0.0,
                height: 5.h,
                color: const Color(0xff388CFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletBloc, WalletState>(
      listener: (context, state) {
        final frontStatus = state.kycFrontAnalyzeStatus;
        final backStatus = state.kycBackAnalyzeStatus;

        if (frontStatus != _lastFrontAnalyzeStatus) {
          _lastFrontAnalyzeStatus = frontStatus;
          if (frontStatus == WalletStatus.success &&
              _step == _ScanStep.front &&
              state.kycFrontImagePath != null) {
            // Check if nextStep requires back side
            final nextStep = state.kycNextStep?.toUpperCase() ?? '';
            if (nextStep == 'REQUIRE_BACK') {
              // Normal flow: proceed to back side
              _handleFrontAnalyzeSuccess(state.kycFrontImagePath!);
            } else {
              // Single-document flow: skip back, go directly to done
              setState(() {
                _frontImagePath = state.kycFrontImagePath;
                _step = _ScanStep.done;
                _detectProgress = 1.0;
              });
              Future.delayed(const Duration(seconds: 1)).then((_) {
                if (mounted && _frontImagePath != null) {
                  // Single-document (passport): pass empty string for back
                  widget.onSuccessTap?.call(_frontImagePath!, '');
                }
              });
            }
          }
        }

        if (backStatus != _lastBackAnalyzeStatus) {
          _lastBackAnalyzeStatus = backStatus;
          if (backStatus == WalletStatus.success &&
              _step == _ScanStep.back &&
              state.kycBackImagePath != null) {
            _handleBackAnalyzeSuccess(state.kycBackImagePath!);
          }
        }
      },
      builder: (context, state) {
        final lang = state.languageCode;
        final isScanningFront = _step == _ScanStep.front;
        final isScanningBack = _step == _ScanStep.back;
        final frontDone = _frontImagePath != null;
        final backDone = _backImagePath != null;
        final instruction = _isLowLight
            ? AppStrings.get(lang, 'kyc_low_light_warning')
            : _distanceStatus == _DistanceStatus.tooFar
            ? AppStrings.get(lang, 'kyc_too_far')
            : _distanceStatus == _DistanceStatus.tooClose
            ? AppStrings.get(lang, 'kyc_too_close')
            : isScanningFront
            ? AppStrings.get(lang, 'kyc_align_id')
            : isScanningBack
            ? AppStrings.get(lang, 'kyc_flip_to_back')
            : '';

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
                      TrydosWalletAssets.identity,
                      package: TrydosWalletStyles.packageName,
                      height: 20.h,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      AppStrings.get(lang, 'kyc_live_detection_id'),
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
            // ─── Camera Frame ──────────────────────────────────────────────
            Directionality(
              textDirection: TextDirection.ltr,
              child: Container(
                height: 400.h,
                width: 1.sw,
                margin: EdgeInsets.symmetric(horizontal: 40.w),
                decoration: BoxDecoration(
                  color: const Color(0xff000000),
                  borderRadius: BorderRadius.circular(30.r),
                  border: Border.all(
                    color: const Color(0xff388CFF),
                    width: 0.5,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Live camera preview
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30.r),
                        child: _isCameraInitialized && _cameraController != null
                            ? CameraPreview(_cameraController!)
                            : _isCameraError
                            ? Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                  ),
                                  child: Text(
                                    AppStrings.get(lang, 'kyc_camera_error'),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xff388CFF),
                                ),
                              ),
                      ),
                    ),
                    // Low-light warning overlay
                    if (_isLowLight)
                      Positioned(
                        top: 48.h,
                        left: 20.w,
                        right: 20.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: Colors.orange.withOpacity(0.88),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.wb_sunny_outlined,
                                color: Colors.white,
                                size: 16.h,
                              ),
                              SizedBox(width: 6.w),
                              Flexible(
                                child: Text(
                                  AppStrings.get(lang, 'kyc_low_light_warning'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.sp,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    // Instruction guide text
                    if (instruction.isNotEmpty && !_isLowLight)
                      Positioned(
                        bottom: 48.h,
                        left: 20.w,
                        right: 20.w,
                        child: Text(
                          instruction,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.sp,
                            shadows: const [
                              Shadow(blurRadius: 4, color: Colors.black54),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    // Corner SVG overlays
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
            // ─── Thumbnails ────────────────────────────────────────────────
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Front side
                SizedBox(
                  width: 153.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            TrydosWalletAssets.frontSide,
                            package: TrydosWalletStyles.packageName,
                            width: 22.h,
                            // ignore: deprecated_member_use
                            color: isScanningFront
                                ? const Color(0xff388CFF)
                                : const Color(0xff1D1D1D),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            AppStrings.get(lang, 'kyc_front_side'),
                            style: context.textTheme.titleLarge?.mq.copyWith(
                              color: isScanningFront
                                  ? const Color(0xff388CFF)
                                  : const Color(0xff1D1D1D),
                              letterSpacing: 0.14,
                              height: 1.43,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      _buildProgressBar(
                        isActive: isScanningFront,
                        isDone: frontDone,
                      ),
                      Padding(
                        padding: EdgeInsets.all(5.h),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15.r),
                          child: SizedBox(
                            height: 96.h,
                            width: 153.w,
                            child: _buildThumbnail(
                              imagePath: _frontImagePath,
                              uploadStatus: state.kycFrontAnalyzeStatus,
                              side: _ScanStep.front,
                              errorText: state.kycFrontAnalyzeErrorMessage,
                              lang: lang,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 5.w),
                // Back side
                SizedBox(
                  width: 153.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            TrydosWalletAssets.backSide,
                            package: TrydosWalletStyles.packageName,
                            width: 22.h,
                            // ignore: deprecated_member_use
                            color: isScanningBack
                                ? const Color(0xff388CFF)
                                : const Color(0xff1D1D1D),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            AppStrings.get(lang, 'kyc_back_side'),
                            style: context.textTheme.titleLarge?.mq.copyWith(
                              color: isScanningBack
                                  ? const Color(0xff388CFF)
                                  : const Color(0xff1D1D1D),
                              letterSpacing: 0.14,
                              height: 1.43,
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      _buildProgressBar(
                        isActive: isScanningBack,
                        isDone: backDone,
                      ),
                      Padding(
                        padding: EdgeInsets.all(5.h),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15.r),
                          child: SizedBox(
                            height: 96.h,
                            width: 153.w,
                            child: _buildThumbnail(
                              imagePath: _backImagePath,
                              uploadStatus: state.kycBackAnalyzeStatus,
                              side: _ScanStep.back,
                              errorText: state.kycBackAnalyzeErrorMessage,
                              lang: lang,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
