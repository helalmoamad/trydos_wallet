import 'dart:async';

import 'package:anam_flutter_sdk/anam_flutter_sdk.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:trydos_wallet/src/bloc/wallet_bloc.dart';
import 'package:trydos_wallet/src/bloc/wallet_state.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/src/localization/app_strings.dart';

/// Digital wallet home page.
class StartVideo extends StatefulWidget {
  final Function()? onTapNextPage;
  const StartVideo({super.key, this.onTapNextPage});

  @override
  State<StartVideo> createState() => _StartVideoState();
}

class _StartVideoState extends State<StartVideo> {
  static const int _recordDurationSec = 15;
  static const Duration _avatarConnectTimeout = Duration(seconds: 12);
  static const String _anamApiKey =
      'YTJlOTMyNDktODE4MC00OTAwLWE1MTMtNjM3MGJkNjc5YjRjOnoyc1VmVm55UWhBNEk5akZoSTVZWjU5dVlyM04yd2tsL3Q4VHlScldVeGM9';

  CameraController? _cameraController;
  bool _cameraReady = false;
  bool _recordingStarted = false;
  bool _recordingFinished = false;
  int _remainingSeconds = _recordDurationSec;
  Timer? _recordTimer;

  AnamClient? _anamClient;
  RTCVideoRenderer? _avatarRenderer;
  bool _avatarReady = false;
  bool _avatarLoading = true;
  bool _avatarFailed = false;
  String _statusText = '';

  @override
  void initState() {
    super.initState();
    _initFlow();
  }

  Future<void> _initFlow() async {
    await Future.wait([_initAvatar(), _initCameraAndRecord()]);
  }

  String _anamLanguageCode(String lang) {
    switch (lang) {
      case 'ar':
        return 'ar';
      case 'tr':
        return 'tr';
      case 'ku':
        return 'ku';
      default:
        return 'en';
    }
  }

  List<String> _scriptedQuestions(String lang) {
    switch (lang) {
      case 'ar':
        return const [
          'مرحباً، من فضلك ما اسمك الكامل؟',
          'ما تاريخ ميلادك؟',
          'الآن أمسك الهوية بشكل واضح أمام الكاميرا.',
        ];
      case 'tr':
        return const [
          'Merhaba, lütfen tam adınızı söyler misiniz?',
          'Doğum tarihiniz nedir?',
          'Şimdi lütfen kimliğinizi kameraya net şekilde tutun.',
        ];
      case 'ku':
        return const [
          'سڵاو، تکایە ناوی تەواوت بڵێ؟',
          'بەرواری لەدایکبوونت چییە؟',
          'ئێستا تکایە ناسنامەکەت بە ڕوونی لەبەردەم کامێرا بگرە.',
        ];
      default:
        return const [
          'Hello, please tell me your full name.',
          'What is your date of birth?',
          'Now please hold your ID clearly in front of the camera.',
        ];
    }
  }

  Future<void> _initAvatar() async {
    final lang = context.read<WalletBloc>().state.languageCode;
    _statusText = _scriptedQuestions(lang).first;
    _avatarLoading = true;
    _avatarFailed = false;
    if (mounted) setState(() {});

    try {
      final renderer = RTCVideoRenderer();
      await renderer.initialize();
      _avatarRenderer = renderer;

      final streamReady = Completer<void>();

      final client = AnamClientFactory.unsafeCreateClientWithApiKey(
        apiKey: _anamApiKey,
        enableLogging: false,
      );

      _anamClient = client;
      final questions = _scriptedQuestions(lang);
      final personaConfig = PersonaConfig(
        personaId: 'default',
        name: 'Trydos KYC Assistant',
        avatarId: '071b0286-4cce-4808-bee2-e642f1062de3',
        voiceId: 'default_voice',
        languageCode: _anamLanguageCode(lang),
        systemPrompt:
            'You are a KYC assistant. Ask exactly these 3 questions one by one and stay brief: '
            '${questions[0]} ${questions[1]} ${questions[2]}',
      );

      await client.talk(
        personaConfig: personaConfig,
        onStreamReady: (stream) {
          if (stream != null && _avatarRenderer != null) {
            _avatarRenderer!.srcObject = stream;
            _avatarReady = true;
            _avatarLoading = false;
            if (!streamReady.isCompleted) streamReady.complete();
            if (mounted) setState(() {});
          }
        },
      );

      await streamReady.future.timeout(_avatarConnectTimeout);

      for (final message in questions) {
        client.sendUserMessage(
          'Please ask this exact question now in ${_anamLanguageCode(lang)}: $message',
        );
        _statusText = message;
        if (mounted) setState(() {});
        await Future.delayed(const Duration(seconds: 4));
      }
    } catch (_) {
      _avatarReady = false;
      _avatarLoading = false;
      _avatarFailed = true;
      _statusText = lang == 'ar'
          ? 'تعذر الاتصال بالمساعد، اضغط إعادة المحاولة.'
          : 'Avatar connection failed. Tap retry.';
      if (mounted) setState(() {});
    }
  }

  Future<void> _retryAvatar() async {
    try {
      await _anamClient?.stopStreaming();
    } catch (_) {}
    _avatarRenderer?.srcObject = null;
    _avatarReady = false;
    _avatarLoading = true;
    _avatarFailed = false;
    if (mounted) setState(() {});
    await _initAvatar();
  }

  Future<void> _initCameraAndRecord() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();

      _cameraController = controller;
      _cameraReady = true;
      if (mounted) setState(() {});

      await _startRecordingFor15s();
    } catch (_) {}
  }

  Future<void> _startRecordingFor15s() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    if (_recordingStarted) return;

    try {
      await controller.startVideoRecording();
      _recordingStarted = true;
      _remainingSeconds = _recordDurationSec;
      if (mounted) setState(() {});

      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_remainingSeconds <= 1) {
          timer.cancel();
          await _stopRecording();
          return;
        }

        setState(() {
          _remainingSeconds -= 1;
        });
      });
    } catch (_) {}
  }

  Future<void> _stopRecording() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isRecordingVideo) return;

    try {
      final recorded = await controller.stopVideoRecording();
      _statusText =
          'Video saved: ${recorded.path.split(RegExp(r'[\\/]')).last}';
      _recordingFinished = true;
      _remainingSeconds = 0;
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    if (_cameraController?.value.isRecordingVideo == true) {
      _cameraController?.stopVideoRecording();
    }
    _cameraController?.dispose();
    _anamClient?.stopStreaming();
    _avatarRenderer?.srcObject = null;
    _avatarRenderer?.dispose();
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
              AppStrings.get(lang, 'kyc_video_call_from_our_side'),
              style: context.textTheme.titleLarge?.mq.copyWith(
                color: const Color(0xff1D1D1D),
                letterSpacing: 0.14,
                height: 1.1,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 12.h),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30.r),
                      child: SizedBox(
                        width: 1.sw,
                        height: 640.h,
                        child: _avatarReady && _avatarRenderer != null
                            ? RTCVideoView(
                                _avatarRenderer!,
                                objectFit: RTCVideoViewObjectFit
                                    .RTCVideoViewObjectFitCover,
                              )
                            : Container(
                                color: const Color(0xff000000),
                                alignment: Alignment.center,
                                child: _avatarLoading
                                    ? CircularProgressIndicator(
                                        color: const Color(0xff388CFF),
                                        strokeWidth: 2.w,
                                      )
                                    : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.videocam_off,
                                            color: const Color(0xffffffff),
                                            size: 26.sp,
                                          ),
                                          SizedBox(height: 8.h),
                                          Text(
                                            lang == 'ar'
                                                ? 'تعذر عرض الفيديو'
                                                : 'Avatar unavailable',
                                            style: context
                                                .textTheme
                                                .titleLarge
                                                ?.rq
                                                .copyWith(
                                                  color: const Color(
                                                    0xffffffff,
                                                  ),
                                                  fontSize: 13.sp,
                                                ),
                                          ),
                                          SizedBox(height: 8.h),
                                          if (_avatarFailed)
                                            InkWell(
                                              onTap: _retryAvatar,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 12.w,
                                                  vertical: 7.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xff388CFF,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        10.r,
                                                      ),
                                                ),
                                                child: Text(
                                                  lang == 'ar'
                                                      ? 'إعادة المحاولة'
                                                      : 'Retry',
                                                  style: context
                                                      .textTheme
                                                      .titleLarge
                                                      ?.rq
                                                      .copyWith(
                                                        color: const Color(
                                                          0xffffffff,
                                                        ),
                                                        fontSize: 12.sp,
                                                      ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 15.h,
                      left: 12.w,
                      right: 12.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xcc000000),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          _statusText,
                          textAlign: TextAlign.center,
                          style: context.textTheme.titleLarge?.rq.copyWith(
                            color: const Color(0xffffffff),
                            fontSize: 12.sp,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 5.h,
                      right: 5.w,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25.r),
                        child: SizedBox(
                          height: 200.h,
                          width: 140.w,
                          child: _cameraReady && _cameraController != null
                              ? CameraPreview(_cameraController!)
                              : Container(color: const Color(0xff000000)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12.h,
                      left: 12.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 7.h,
                        ),
                        decoration: BoxDecoration(
                          color: _recordingFinished
                              ? const Color(0xff34D317)
                              : const Color(0xcc000000),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Text(
                          _recordingFinished
                              ? '15s done'
                              : '$_remainingSeconds s',
                          style: context.textTheme.titleLarge?.mq.copyWith(
                            color: _recordingFinished
                                ? const Color(0xff1D1D1D)
                                : const Color(0xffffffff),
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Spacer(),
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
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: InkWell(
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                onTap: () {
                  if (!_recordingFinished) return;
                  widget.onTapNextPage?.call();
                },
                child: Container(
                  width: 1.sw,
                  height: 60.h,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xffFF5F61)),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Center(
                    child: Text(
                      _recordingFinished
                          ? AppStrings.get(lang, 'kyc_end_video_call')
                          : 'Recording... $_remainingSeconds s',
                      style: context.textTheme.displayMedium?.mq.copyWith(
                        color: const Color(0xff1D1D1D),
                        letterSpacing: 0.16,
                        height: 1.25,
                        fontSize: 16.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 35.h),
          ],
        );
      },
    );
  }
}
