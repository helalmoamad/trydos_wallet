import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';

/// Digital wallet home page.
class IdMatchingWithPhoto extends StatelessWidget {
  final Function()? onTapNextPage;
  const IdMatchingWithPhoto({super.key, this.onTapNextPage});

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

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              TrydosWalletAssets.liveFace,
              package: TrydosWalletStyles.packageName,
              height: 20.h,
            ),
            SizedBox(width: 10.w),
            SvgPicture.asset(
              TrydosWalletAssets.identity,
              package: TrydosWalletStyles.packageName,
              height: 20.h,
            ),
            SizedBox(width: 10.w),
            Text(
              "ID Matching With Your Photo Not Correct",
              style: context.textTheme.titleLarge?.mq.copyWith(
                color: const Color(0xff1D1D1D),
                letterSpacing: 0.14,
                height: 1.1,
                fontSize: 16.sp,
              ),
            ),
          ],
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
              border: Border.all(color: const Color(0xffFF5F61), width: 2),
              borderRadius: BorderRadius.circular(30.r),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 10.h,
                  child: Container(
                    height: 157.h,
                    width: 280.w,
                    margin: EdgeInsets.symmetric(horizontal: 40.w),

                    decoration: BoxDecoration(
                      color: const Color(0xff000000),
                      border: Border.all(
                        color: const Color(0xffFF5F61),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Text(
            "We Noticed A Discrepancy In The Image And There Is Also Doubt About The Personal Identity.",
            textAlign: TextAlign.center,
            style: context.textTheme.titleLarge?.rq.copyWith(
              color: const Color(0xff1D1D1D),
              letterSpacing: 0.14,
              height: 1.43,
              fontSize: 14.sp,
            ),
          ),
        ),

        Spacer(),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: InkWell(
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            onTap: () {
              onTapNextPage?.call();
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
                    "Try Again With The Correction",
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
        SizedBox(height: 25.h),
        Center(
          child: InkWell(
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            onTap: () async {
              onTapNextPage?.call();
            },
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: Text(
                "Rematch",
                style: context.textTheme.titleLarge?.rq.copyWith(
                  color: const Color(0xff4D84FF),
                  letterSpacing: 0.14,
                  height: 1.43,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: 30.h),
      ],
    );
  }
}
