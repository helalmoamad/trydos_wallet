import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trydos_wallet/src/bloc/wallet_bloc.dart';
import 'package:trydos_wallet/src/bloc/wallet_state.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/src/localization/app_strings.dart';

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
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        return Stack(
          children: [
            AnimatedOpacity(
              opacity: _showSplash ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_showSplash,
                child: _SplashOverlay(
                  progress: _controller.value,
                  languageCode: state.languageCode,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SplashOverlay extends StatelessWidget {
  final double progress;
  final String languageCode;

  const _SplashOverlay({required this.progress, required this.languageCode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(flex: 5),

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
                    height: 72.h,
                  ),
                  SizedBox(height: 20.h),
                  SvgPicture.asset(
                    TrydosWalletAssets.rammazDigitalBanking,
                    package: TrydosWalletStyles.packageName,
                    height: 13.h,
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
                    width: 146.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15.r),
                      border: Border.all(
                        color: const Color(0xFF707070),
                        width: 0.8.h,
                      ),
                    ),
                    padding: EdgeInsets.all(1.h),
                    child: Stack(
                      children: [
                        Container(
                          height: 5.h,
                          width: (146.w) * progress,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3066CC),
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _getWord(progress, languageCode),
                      key: ValueKey<String>(_getWord(progress, languageCode)),
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.rq.copyWith(
                        fontSize: 13.sp,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Powered By section
            Padding(
              padding: EdgeInsets.only(bottom: 40.h),
              child: Center(
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.get(languageCode, 'powered_by'),
                        style: context.textTheme.bodyMedium?.lq.copyWith(
                          fontSize: 8.sp,
                          color: const Color(0xff404040),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SvgPicture.asset(
                            TrydosWalletAssets.rammaz,
                            package: TrydosWalletStyles.packageName,
                            height: 10.h,
                          ),
                          Positioned(
                            top: -5.h,
                            left: 44.w,
                            child: SvgPicture.asset(
                              TrydosWalletAssets.bracket,
                              package: TrydosWalletStyles.packageName,
                              height: 5.h,
                            ),
                          ),
                          Positioned(
                            top: -5.h,
                            right: -5.w,
                            child: SvgPicture.asset(
                              TrydosWalletAssets.rLetter,
                              package: TrydosWalletStyles.packageName,
                              height: 7.h,
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
    );
  }

  String _getWord(double progress, String lang) {
    if (progress < 0.30) {
      return AppStrings.get(lang, 'splash_safe');
    }
    if (progress < 0.55) {
      return AppStrings.get(lang, 'splash_easy');
    }
    if (progress < 0.80) {
      return AppStrings.get(lang, 'splash_transaction');
    }
    return AppStrings.get(lang, 'splash_payment');
  }
}
