import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trydos_wallet/src/bloc/wallet_bloc.dart';
import 'package:trydos_wallet/src/bloc/wallet_state.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/screens/kyc/id_matching_with_photo.dart';
import 'package:trydos_wallet/src/screens/kyc/identity_verification.dart';
import 'package:trydos_wallet/src/screens/kyc/live_face_detection.dart';
import 'package:trydos_wallet/src/screens/kyc/start_video.dart';
import 'package:trydos_wallet/src/screens/kyc/success_id_card.dart';
import 'package:trydos_wallet/src/screens/kyc/success_verification.dart';
import 'package:trydos_wallet/src/screens/kyc/video_call_request.dart';
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
  bool _isTransitioning = false;
  String? _frontImagePath;
  String? _backImagePath;
  String? _selfiePath;
  int _idCaptureAttempts = 0;
  int _identitySession = 0;

  @override
  void initState() {
    super.initState();
    _pageContent = ValueNotifier(0);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pageContent.dispose();
    super.dispose();
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

  Future<void> _onIdCaptured(String frontPath, String backPath) async {
    setState(() {
      _frontImagePath = frontPath;
      _backImagePath = backPath;
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
    return BlocBuilder<WalletBloc, WalletState>(
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
                      },
                      controller: _pageController,
                      children: [
                        IdentityVerification(
                          key: ValueKey(_identitySession),
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
                        LiveFaceDetection(onSuccessTap: _onLivenessDone),
                        IdMatchingWithPhoto(
                          onTapNextPage: _goToNextPage,
                          selfiePath: _selfiePath,
                          frontIdPath: _frontImagePath,
                        ),
                        VideoCallRequest(
                          onTapNextPage: _goToNextPage,
                          selfiePath: _selfiePath,
                          backIdPath: _backImagePath,
                        ),
                        StartVideo(onTapNextPage: _goToNextPage),
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
