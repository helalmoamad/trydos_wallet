import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/styles.dart';

/// Wallet splash screen. Preloads home page data during 5 seconds.
class SplashWidget extends StatefulWidget {
  const SplashWidget({super.key});

  @override
  State<SplashWidget> createState() => _SplashWidgetState();
}

class _SplashWidgetState extends State<SplashWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 5500),
        )..addListener(() {
          setState(() {});
        });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _controller.forward().then((_) {
            if (mounted) {
              setState(() => _showSplash = false);
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedOpacity(
          opacity: _showSplash ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          onEnd: () {},
          child: IgnorePointer(
            ignoring: !_showSplash,
            child: _SplashOverlay(progress: _controller.value),
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
    return Scaffold(
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
                        Container(
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
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _getWord(progress),
                      key: ValueKey<String>(_getWord(progress)),
                      textAlign: TextAlign.center,
                      style: TrydosWalletStyles.bodySmall.copyWith(
                        fontSize: 16,
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Powered By section
            Directionality(
              textDirection: TextDirection.ltr,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Center(
                  child: IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Powered By",
                          style: TextStyle(
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
            ),
          ],
        ),
      ),
    );
  }

  String _getWord(double progress) {
    if (progress < 0.30) return 'safe...';
    if (progress < 0.55) return 'easy...';
    if (progress < 0.80) return 'transaction...';
    return 'payment...';
  }
}
