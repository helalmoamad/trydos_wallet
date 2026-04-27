import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';

/// Digital wallet home page.
class IdentityVerification extends StatelessWidget {
  final Function()? onSuccessTap;
  const IdentityVerification({super.key, this.onSuccessTap});

  @override
  Widget build(BuildContext context) {
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
                  TrydosWalletAssets.identity,
                  package: TrydosWalletStyles.packageName,
                  height: 20.h,
                ),
                SizedBox(width: 10.w),
                Text(
                  "Live Detection Your ID",
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
        SizedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 153.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          TrydosWalletAssets.frontSide,
                          package: TrydosWalletStyles.packageName,
                          width: 22.h,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          "Front Side ",
                          style: context.textTheme.titleLarge?.mq.copyWith(
                            color: const Color(0xff388CFF),
                            letterSpacing: 0.14,
                            height: 1.43,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Container(
                      height: 5.h,
                      width: 153.w,

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5.r),
                        border: Border.all(
                          color: Color(0xff388CFF),
                          width: 0.5,
                        ),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.all(5.h),
                      child: Container(
                        height: 96.h,
                        width: 153.w,

                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.r),
                          border: Border.all(
                            color: Color.fromARGB(255, 142, 144, 146),
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 5.w),
              SizedBox(
                width: 153.w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          TrydosWalletAssets.backSide,
                          package: TrydosWalletStyles.packageName,
                          width: 22.h,
                          // ignore: deprecated_member_use
                          color: const Color(0xff1D1D1D),
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          "Back Side ",
                          style: context.textTheme.titleLarge?.mq.copyWith(
                            color: const Color(0xff1D1D1D),
                            letterSpacing: 0.14,
                            height: 1.43,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Container(
                      height: 5.h,
                      width: 153.w,

                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5.r),
                        border: Border.all(
                          color: const Color(0xff1D1D1D),
                          width: 0.5,
                        ),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.all(5.h),
                      child: Container(
                        height: 96.h,
                        width: 153.w,

                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.r),
                          border: Border.all(
                            color: Color.fromARGB(255, 142, 144, 146),
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
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
        SizedBox(height: 12.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: InkWell(
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            onTap: () {
              onSuccessTap?.call();
            },
            child: DottedBorder(
              padding: EdgeInsets.zero,
              borderType: BorderType.RRect,
              strokeCap: StrokeCap.round,
              strokeWidth: 0.5,
              dashPattern: const [3, 3],
              radius: Radius.circular(20.r),
              color: const Color(0xff5D5C5D),
              child: Container(
                width: 1.sw,
                height: 60.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Center(
                  child: Text(
                    "Start Live Detection Your ID",
                    style: context.textTheme.displayMedium?.mq.copyWith(
                      color: const Color(0xff1D1D1D),
                      letterSpacing: 0.16,
                      height: 1.25,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 35.h),
      ],
    );
  }
}
