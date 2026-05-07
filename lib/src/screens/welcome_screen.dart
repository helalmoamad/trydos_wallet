import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:trydos_wallet/src/config/trydos_wallet_config.dart';
import 'package:flutter/material.dart';
import 'package:trydos_wallet/src/constent/constant_design.dart';
import 'package:trydos_wallet/src/screens/home_page.dart';
import 'package:trydos_wallet/src/screens/widgets/splash_widget.dart';

/// Wallet splash screen. Preloads home page data during 5 seconds.
class TrydosWalletWelcomeScreen extends StatefulWidget {
  //////1.0.3
  const TrydosWalletWelcomeScreen({super.key});

  @override
  State<TrydosWalletWelcomeScreen> createState() =>
      _TrydosWalletWelcomeScreenState();
}

class _TrydosWalletWelcomeScreenState extends State<TrydosWalletWelcomeScreen>
    with SingleTickerProviderStateMixin {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    if (TrydosWallet.config.skipSplash) {
      _showSplash = false;
    }
  }

  /// Stepped progress over 5 seconds while data loads in background

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: kDesignSize,
      minTextAdapt: true,
      builder: (context, child) {
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
                child: SplashWidget(),
              ),
            ),
          ],
        );
      },
    );
  }
}
