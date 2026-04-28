import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trydos_wallet/src/bloc/wallet_bloc.dart';
import 'package:trydos_wallet/src/bloc/wallet_state.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/src/localization/app_strings.dart';

/// Digital wallet home page.
class LiveFaceDetection extends StatefulWidget {
  final Function()? onTapNextPage;
  const LiveFaceDetection({super.key, this.onTapNextPage});

  @override
  State<LiveFaceDetection> createState() => _LiveFaceDetectionState();
}

class _LiveFaceDetectionState extends State<LiveFaceDetection> {
  bool _detected = false; // after 3s: green border + hide bottom widgets

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _detected = true);
    });
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        widget.onTapNextPage?.call();
      }
    });
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
                      TrydosWalletAssets.liveFace,
                      package: TrydosWalletStyles.packageName,
                      height: 20.h,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      AppStrings.get(lang, 'kyc_live_face_detection'),
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
            Directionality(
              textDirection: TextDirection.ltr,
              child: Container(
                height: 400.h,
                width: 1.sw,
                margin: EdgeInsets.symmetric(horizontal: 40.w),

                decoration: BoxDecoration(
                  border: Border.all(
                    color: _detected
                        ? const Color(0xffA3FF38)
                        : const Color(0xff388CFF),
                    width: _detected ? 2 : 0.5,
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30.r),
                      child: Image.asset(
                        TrydosWalletPngAssets.personImage,
                        package: TrydosWalletStyles.packageName,
                        height: 400.h,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
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
            SizedBox(height: 10.h),
            if (!_detected) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 60.w),
                child: Text(
                  AppStrings.get(lang, 'kyc_face_centered'),
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleLarge?.rq.copyWith(
                    color: const Color(0xff1D1D1D),
                    letterSpacing: 0.14,
                    height: 1.43,

                    fontSize: 14.sp,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 45.w),
                child: SizedBox(
                  height: 5.h,
                  width: 330.w,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5.r),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.r),
                            border: Border.all(
                              color: Color(0xff388CFF),
                              width: 0.5,
                            ),
                          ),
                        ),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(seconds: 3),
                          curve: Curves.linear,
                          builder: (context, value, child) {
                            return FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: value,
                              child: child,
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xff388CFF),
                              borderRadius: BorderRadius.circular(5.r),
                              border: Border.all(
                                color: Color(0xff388CFF),
                                width: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

              SizedBox(height: 35.h),
            ],
          ],
        );
      },
    );
  }
}
