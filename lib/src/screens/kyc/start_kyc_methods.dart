import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trydos_wallet/src/bloc/wallet_bloc.dart';
import 'package:trydos_wallet/src/bloc/wallet_event.dart';
import 'package:trydos_wallet/src/bloc/wallet_state.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/localization/app_strings.dart';
import 'package:trydos_wallet/src/screens/kyc/id_matching_with_photo.dart';
import 'package:trydos_wallet/src/screens/kyc/identity_verification.dart';
import 'package:trydos_wallet/src/screens/kyc/live_face_detection.dart';
// Video interview disabled — imports kept commented for easy re-enable.
// import 'package:trydos_wallet/src/screens/kyc/start_video.dart';
import 'package:trydos_wallet/src/screens/kyc/success_id_card.dart';
import 'package:trydos_wallet/src/screens/kyc/success_verification.dart';
// import 'package:trydos_wallet/src/screens/kyc/video_call_request.dart';
import 'package:trydos_wallet/src/screens/home_page.dart';

/// Digital wallet home page.
class StartKycMethods extends StatelessWidget {
  const StartKycMethods({super.key});

  @override
  Widget build(BuildContext context) {
    WalletBloc? existingBloc;
    try {
      existingBloc = BlocProvider.of<WalletBloc>(context);
    } catch (_) {
      existingBloc = null;
    }

    if (existingBloc != null) {
      return BlocProvider.value(
        value: existingBloc,
        child: const _StartKycMethodsContent(),
      );
    }

    return BlocProvider(
      create: (context) => WalletBloc(),
      child: const _StartKycMethodsContent(),
    );
  }
}

class _StartKycMethodsContent extends StatefulWidget {
  const _StartKycMethodsContent();

  @override
  State<_StartKycMethodsContent> createState() =>
      _StartKycMethodsContentState();
}

class _StartKycMethodsContentState extends State<_StartKycMethodsContent> {
  late final ValueNotifier<int> _pageContent;
  late final PageController _pageController;
  Timer? _sessionExpiryTimer;
  bool _sessionExpiredHandled = false;
  bool _isTransitioning = false;
  String? _frontImagePath;
  String? _backImagePath;
  String? _selfiePath;
  int _idCaptureAttempts = 0;
  int _identitySession = 0;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageContent = ValueNotifier(0);
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scheduleSessionExpiry(),
    );
  }

  @override
  void dispose() {
    _sessionExpiryTimer?.cancel();
    _pageController.dispose();
    _pageContent.dispose();
    super.dispose();
  }

  /// Arms a timer against the session's `expiresAt`. When it fires the flow is
  /// abandoned with a translated message (the single-use session is gone).
  void _scheduleSessionExpiry() {
    if (!mounted) return;
    _sessionExpiryTimer?.cancel();
    final expiresAt = context.read<WalletBloc>().state.kycSessionExpiresAt;
    if (expiresAt == null) return;
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _onSessionExpired();
      return;
    }
    _sessionExpiryTimer = Timer(remaining, _onSessionExpired);
  }

  Future<void> _onSessionExpired() async {
    if (!mounted || _sessionExpiredHandled) return;
    _sessionExpiredHandled = true;
    _sessionExpiryTimer?.cancel();

    final bloc = context.read<WalletBloc>();
    bloc.add(const WalletKycSessionResetRequested());
    final lang = bloc.state.languageCode;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Text(AppStrings.get(lang, 'kyc_session_expired')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppStrings.get(lang, 'ok')),
          ),
        ],
      ),
    );

    _exitToHome();
  }

  /// Leaves the KYC flow back to the host's first route (or home as fallback).
  void _exitToHome() {
    if (!mounted) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    try {
      if (navigator.canPop()) {
        navigator.popUntil((route) => route.isFirst);
      } else {
        navigator.push(
          MaterialPageRoute(builder: (_) => const TrydosWalletHomePage()),
        );
      }
    } catch (_) {
      Navigator.of(
        context,
        rootNavigator: true,
      ).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _goToNextPage() async {
    if (_isTransitioning || !_pageController.hasClients || !mounted) return;
    _isTransitioning = true;
    try {
      await _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } finally {
      _isTransitioning = false;
    }
  }

  Future<void> _goToPreviousPage() async {
    if (_isTransitioning || !_pageController.hasClients || !mounted) return;
    _isTransitioning = true;
    try {
      await _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } finally {
      _isTransitioning = false;
    }
  }

  Future<void> _goToFirstPageAndReset() async {
    if (!_pageController.hasClients || !mounted) return;
    context.read<WalletBloc>().add(const WalletKycAnalyzeIdResetRequested());
    context.read<WalletBloc>().add(const WalletKycLivenessResetRequested());
    context.read<WalletBloc>().add(const WalletKycCompareFaceResetRequested());
    // Restarting the flow needs a fresh single-use session — the previous one
    // may have been spent (e.g. on a rejected submit).
    context.read<WalletBloc>().add(const WalletKycSessionStartRequested());
    setState(() {
      _isTransitioning = false;
      _frontImagePath = null;
      _backImagePath = null;
      _selfiePath = null;
      _idCaptureAttempts = 0;
      _identitySession++;
    });
    _pageController.jumpToPage(0);
  }

  Future<void> _onIdCaptured(String frontPath, String backPath) async {
    setState(() {
      _frontImagePath = frontPath;
      _backImagePath = backPath.isNotEmpty ? backPath : null;
      _idCaptureAttempts++;
    });
    await _goToNextPage();
  }

  Future<void> _retryIdCapture() async {
    setState(() {
      _frontImagePath = null;
      _backImagePath = null;
      _identitySession++;
    });
    await _goToPreviousPage();
  }

  Future<void> _onLivenessDone(String selfiePath) async {
    setState(() => _selfiePath = selfiePath);
    await _goToNextPage();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletBloc, WalletState>(
      // A new session (e.g. after a restart) carries a fresh expiry — re-arm
      // the timer and clear the handled flag so it can fire again.
      listenWhen: (prev, curr) =>
          prev.kycSessionExpiresAt != curr.kycSessionExpiresAt,
      listener: (context, state) {
        if (state.kycSessionExpiresAt != null) {
          _sessionExpiredHandled = false;
        }
        _scheduleSessionExpiry();
      },
      builder: (context, state) {
        final isRtl = state.languageCode == 'ar' || state.languageCode == 'ku';
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: Color(0xffFFFFFF),
            body: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 1.sh,
                  width: 1.sw,
                  // ignore: deprecated_member_use
                  child: WillPopScope(
                    child: PageView(
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (value) {
                        _pageContent.value = value;
                        setState(() => _currentPage = value);
                      },
                      controller: _pageController,
                      children: [
                        IdentityVerification(
                          key: ValueKey(_identitySession),
                          isActive: _currentPage == 0,
                          onSuccessTap: _onIdCaptured,
                        ),
                        SuccessIdCard(
                          onTapNextPage: _idCaptureAttempts >= 3
                              ? null
                              : _goToNextPage,
                          onTapRetry: _retryIdCapture,
                          isFinalAttempt: _idCaptureAttempts >= 3,
                          frontImagePath: _frontImagePath,
                          backImagePath: _backImagePath,
                        ),
                        LiveFaceDetection(
                          isActive: _currentPage == 2,
                          onSuccessTap: _onLivenessDone,
                        ),
                        IdMatchingWithPhoto(
                          // Face match is now the terminal verification step.
                          // On success it advances straight to SuccessVerification
                          // (the video interview steps below are disabled).
                          onTapNextPage: _goToNextPage,
                          onMatchError: (_) => _goToFirstPageAndReset(),
                          selfiePath: _selfiePath,
                          frontIdPath: _frontImagePath,
                        ),
                        // ── Video interview removed (KYC ends at face-match). ──
                        // Kept commented (not deleted) per integration guide
                        // "KYC_FLUTTER_INTEGRATION.md (No Video Interview)".
                        /*
                        VideoCallRequest(
                          onTapNextPage: _goToNextPage,
                          onSkip: () {
                            final navigator = Navigator.of(
                              context,
                              rootNavigator: true,
                            );
                            try {
                              if (navigator.canPop()) {
                                navigator.popUntil((route) => route.isFirst);
                              } else {
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const TrydosWalletHomePage(),
                                  ),
                                );
                              }
                            } catch (_) {
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).popUntil((route) => route.isFirst);
                            }
                          },
                          selfiePath: _selfiePath,
                          backIdPath: _backImagePath,
                        ),
                        StartVideo(onTapNextPage: _goToNextPage),
                        */
                        SuccessVerification(
                          onDone: () {
                            final navigator = Navigator.of(
                              context,
                              rootNavigator: true,
                            );
                            try {
                              if (navigator.canPop()) {
                                navigator.popUntil((route) => route.isFirst);
                              } else {
                                navigator.push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const TrydosWalletHomePage(),
                                  ),
                                );
                              }
                            } catch (_) {
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).popUntil((route) => route.isFirst);
                            }
                          },
                        ),
                      ],
                    ),
                    onWillPop: () async {
                      return false;
                    },
                  ),
                ),
                PositionedDirectional(
                  top: 10.w,
                  end: 0,
                  child: ValueListenableBuilder<int>(
                    valueListenable: _pageContent,
                    builder: (context, index, _) {
                      return index > 3
                          ? SizedBox.shrink()
                          : InkWell(
                              highlightColor: Colors.transparent,
                              splashColor: Colors.transparent,
                              onTap: () async {
                                final navigator = Navigator.of(
                                  context,
                                  rootNavigator: true,
                                );
                                try {
                                  if (navigator.canPop()) {
                                    navigator.popUntil(
                                      (route) => route.isFirst,
                                    );
                                  } else {
                                    navigator.push(
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const TrydosWalletHomePage(),
                                      ),
                                    );
                                  }
                                } catch (_) {
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).popUntil((route) => route.isFirst);
                                }
                                //////////////////////////
                              },
                              child: Padding(
                                padding: EdgeInsetsGeometry.only(
                                  top: 60.h,
                                  right: 30.w,
                                  left: 30.w,
                                  bottom: 60.h,
                                ),
                                child: SvgPicture.asset(
                                  TrydosWalletAssets.closePage,
                                  package: TrydosWalletStyles.packageName,
                                  height: 15.h,
                                ),
                              ),
                            );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
