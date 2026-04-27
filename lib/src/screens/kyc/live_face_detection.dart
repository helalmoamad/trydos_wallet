import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';

/// Digital wallet home page.
class LiveFaceDetection extends StatelessWidget {
  final Function()? onTapNextPage;
  const LiveFaceDetection({super.key, this.onTapNextPage});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 10), () {
      onTapNextPage?.call();
    });
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 100.h),
        Text(
          "Identity Verification !",
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
                  "Live Face Detection",
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
              color: const Color(0xff000000),
              border: Border.all(color: const Color(0xff388CFF), width: 0.5),
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Stack(
              children: [
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
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 60.w),
          child: Text(
            "Please Keep Your Face Centered On The Screen And Facing Forward",
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
          child: Stack(
            children: [
              Container(
                height: 5.h,
                width: 330.w,

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5.r),
                  border: Border.all(color: Color(0xff388CFF), width: 0.5),
                ),
              ),
              Container(
                height: 5.h,
                width: 50.w,

                decoration: BoxDecoration(
                  color: Color(0xff388CFF),
                  borderRadius: BorderRadius.circular(5.r),
                  border: Border.all(color: Color(0xff388CFF), width: 0.5),
                ),
              ),
            ],
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
          "Your Privacy Is Completely Safe",
          style: context.textTheme.titleLarge?.rq.copyWith(
            color: const Color(0xff4D84FF),
            letterSpacing: 0.14,
            height: 1.43,
            fontSize: 12.sp,
          ),
        ),

        SizedBox(height: 35.h),
      ],
    );
  }
}
