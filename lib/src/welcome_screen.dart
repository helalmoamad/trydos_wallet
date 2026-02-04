import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trydos_wallet/src/home_page.dart';
import 'styles.dart';
import 'assets.dart';

/// الشاشة الافتتاحية (Splash Screen) للمحفظة.
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

  @override
  void initState() {
    super.initState();
    _startSteppedProgress();
  }

  /// محاكاة للتحميل على دفعات خلال 5 ثوانٍ
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
        _navigateToMain();
      }
    });
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TrydosWalletHomePage()),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

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

            // الجزء العلوي: الشعار والنص
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

            // الجزء الأوسط: شريط التحميل وكلمة Safe
            SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // شريط التحميل المخصص
                  Container(
                    width: 180, // عرض الشاشة كما في الصورة
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.white, // قلبه أبيض
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFF707070), // اللون الخارجي
                        width: 0.8,
                      ),
                    ),
                    padding: const EdgeInsets.all(1.5), // مسافة الحشو الداخلية
                    child: Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          width: 177 * _progress,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3066CC), // اللون الأزرق
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Safe',
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

            // الجزء السفلي: Powered By
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Center(
                child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Powered By',
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
    );
  }
}
