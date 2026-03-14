import 'dart:async';
import 'package:trydos_wallet/src/config/trydos_wallet_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/screens/home_page.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/bloc/bloc.dart';
import 'package:trydos_wallet/src/localization/app_strings.dart';

/// Wallet splash screen. Preloads home page data during 5 seconds.
class TrydosWalletWelcomeScreen extends StatefulWidget {
  const TrydosWalletWelcomeScreen({super.key});

  @override
  State<TrydosWalletWelcomeScreen> createState() =>
      _TrydosWalletWelcomeScreenState();
}

class _TrydosWalletWelcomeScreenState extends State<TrydosWalletWelcomeScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  late Timer _timer;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    if (TrydosWallet.config.skipSplash) {
      _showSplash = false;
    } else {
      _startSteppedProgress();
    }
  }

  /// Stepped progress over 5 seconds while data loads in background
  void _startSteppedProgress() {
    const totalSteps = 10;
    const stepDuration = Duration(milliseconds: 500); // 500ms * 10 = 5 seconds
    int currentStep = 0;

    _timer = Timer.periodic(stepDuration, (timer) {
      setState(() {
        currentStep++;
        _progress = currentStep / totalSteps;
      });

      if (currentStep >= totalSteps) {
        timer.cancel();
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  void dispose() {
    if (!TrydosWallet.config.skipSplash) {
      _timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (TrydosWallet.config.skipSplash) {
      return const TrydosWalletHomePage();
    }

    return Stack(
      children: [
        const TrydosWalletHomePage(),
        AnimatedOpacity(
          opacity: _showSplash ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          onEnd: () {},
          child: IgnorePointer(
            ignoring: !_showSplash,
            child: _SplashOverlay(progress: _progress),
          ),
        ),
      ],
    );
  }
}

class _SplashOverlay extends StatelessWidget {
  final double progress;

  const _SplashOverlay({required this.progress});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        return Directionality(
          textDirection: state.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // Logo section
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          TrydosWalletAssets.rdb,
                          package: TrydosWalletStyles.packageName,
                        ),
                        const SizedBox(height: 12),
                        SvgPicture.asset(
                          TrydosWalletAssets.rammazDigitalBanking,
                          package: TrydosWalletStyles.packageName,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 4),

                  // Progress bar and Safe text
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Custom progress bar
                        Container(
                          width: 180,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: const Color(0xFF707070),
                              width: 0.8,
                            ),
                          ),
                          padding: const EdgeInsets.all(1.5),
                          child: Stack(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                                width: 177 * progress,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3066CC),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.get(state.languageCode, 'safe'),
                          textAlign: TextAlign.center,
                          style: TrydosWalletStyles.bodyLarge.copyWith(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Powered By section
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Center(
                      child: IntrinsicWidth(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.get(state.languageCode, 'powered_by'),
                              style: TextStyle(
                                fontFamily: TrydosWalletStyles.fontFamily,
                                package: TrydosWalletStyles.packageName,
                                fontSize: 8,
                                color: const Color(0xff404040),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                SvgPicture.asset(
                                  TrydosWalletAssets.rammaz,
                                  package: TrydosWalletStyles.packageName,
                                ),
                                Positioned(
                                  top: -5,
                                  left: 44,
                                  child: SvgPicture.asset(
                                    TrydosWalletAssets.bracket,
                                    package: TrydosWalletStyles.packageName,
                                  ),
                                ),
                                Positioned(
                                  top: -5,
                                  right: -5,
                                  child: SvgPicture.asset(
                                    TrydosWalletAssets.rLetter,
                                    package: TrydosWalletStyles.packageName,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
