import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constent/assets.dart';
import '../constent/constant_design.dart';
import '../constent/styles.dart';

/// Full-screen overlay shown when internet connectivity is lost.
/// Cannot be dismissed — disappears automatically when connectivity returns.
class NoInternetScreen extends StatefulWidget {
  const NoInternetScreen({super.key, required this.languageCode});

  final String languageCode;

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool get _isRtl => widget.languageCode == 'ar' || widget.languageCode == 'ku';

  String _title() {
    switch (widget.languageCode) {
      case 'ar':
        return 'لا يوجد اتصال بالإنترنت';
      case 'ku':
        return 'هیچ پەیوەندییەکی ئینتەرنێت نییە';
      case 'tr':
        return 'İnternet Bağlantısı Yok';
      default:
        return 'No Internet Connection';
    }
  }

  String _subtitle() {
    switch (widget.languageCode) {
      case 'ar':
        return 'يرجى التحقق من اتصالك بالإنترنت والتأكد من اتصالك بشبكة Wi-Fi أو بيانات الجوال.';
      case 'ku':
        return 'تکایە پەیوەندی ئینتەرنێتەکەت بپشکنە و دڵنیابە کە بە Wi-Fi یان داتای مۆبایل پەیوەندیت هەیە.';
      case 'tr':
        return 'Lütfen internet bağlantınızı kontrol edin ve Wi-Fi veya mobil veriye bağlı olduğunuzdan emin olun.';
      default:
        return 'Please check your internet connection and make sure you are connected to Wi-Fi or mobile data.';
    }
  }

  String _reconnecting() {
    switch (widget.languageCode) {
      case 'ar':
        return 'في انتظار إعادة الاتصال...';
      case 'ku':
        return 'چاوەڕوانی دووبارە پەیوەندیکردنەوە...';
      case 'tr':
        return 'Yeniden bağlanmayı bekliyorum...';
      default:
        return 'Waiting for connection...';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Material(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // Animated icon container
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 120.r,
                    height: 120.r,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F5F5),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        TrydosWalletAssets.reload,
                        width: 52.r,
                        height: 52.r,
                        colorFilter: const ColorFilter.mode(
                          Color(0xff2C2A2A),
                          BlendMode.srcIn,
                        ),
                        package: TrydosWalletStyles.packageName,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: ksh32),
                // Title
                Text(
                  _title(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: TrydosWalletStyles.fontFamily,
                    package: TrydosWalletStyles.packageName,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff2C2A2A),
                  ),
                ),
                SizedBox(height: ksh16),
                // Subtitle
                Text(
                  _subtitle(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: TrydosWalletStyles.fontFamily,
                    package: TrydosWalletStyles.packageName,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xff585858),
                    height: 1.6,
                  ),
                ),
                SizedBox(height: ksh40),
                // Reconnecting indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xff0080FF),
                        ),
                      ),
                    ),
                    SizedBox(width: ksw8),
                    Text(
                      _reconnecting(),
                      style: TextStyle(
                        fontFamily: TrydosWalletStyles.fontFamily,
                        package: TrydosWalletStyles.packageName,
                        fontSize: 13.sp,
                        color: const Color(0xff0080FF),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
