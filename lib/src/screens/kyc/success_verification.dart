import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';

/// Digital wallet home page.
class SuccessVerification extends StatelessWidget {
  const SuccessVerification({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 288.h),

        Text(
          "Success Verification !",
          style: context.textTheme.titleLarge?.bq.copyWith(
            color: const Color(0xff1D1D1D),
            letterSpacing: 0.14,
            height: 1.1,
            fontSize: 30.sp,
          ),
        ),
        SizedBox(height: 15.h),
        Text(
          "You Have Enjoy With Our Full Access",
          style: context.textTheme.titleLarge?.mq.copyWith(
            color: const Color(0xff1D1D1D),
            letterSpacing: 0.14,
            height: 1.1,
            fontSize: 16.sp,
          ),
        ),
        SizedBox(height: 30.h),
        SvgPicture.asset(
          TrydosWalletAssets.successVerification,
          package: TrydosWalletStyles.packageName,
          height: 150.h,
        ),
        SizedBox(height: 20.h),
        Text(
          "Mohamad Katmawi",
          style: context.textTheme.titleLarge?.mq.copyWith(
            color: const Color(0xff1D1D1D),
            letterSpacing: 0.14,
            height: 1.1,
            fontSize: 18.sp,
          ),
        ),
      ],
    );
  }
}
