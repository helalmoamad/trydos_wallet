import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/src/screens/kyc/start_kyc_methods.dart';

/// Digital wallet home page.
class FirstPageKyc extends StatelessWidget {
  const FirstPageKyc({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffFFFDD0),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 288.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Text(
              "Identity Verification !",
              style: context.textTheme.titleLarge?.bq.copyWith(
                color: const Color(0xff1D1D1D),
                letterSpacing: 0.14,
                height: 1.43,
                fontSize: 30.sp,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Text(
              "Protect Your Account & Get Full Access",
              style: context.textTheme.titleLarge?.mq.copyWith(
                color: const Color(0xff1D1D1D),
                letterSpacing: 0.14,
                height: 1.1,
                fontSize: 16.sp,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Text(
              "We Need To Verify Your Identity Once To Protect Your Account From Fraud And Comply With Security Regulations One-Time Process To Confirm That You. It Helps Keep Your Account Secure, Prevents Fraud, And Ensures Safe Transactions Just Like Showing Your ID When Opening A Bank Account.",
              style: context.textTheme.titleLarge?.rq.copyWith(
                color: const Color(0xff1D1D1D),
                letterSpacing: 0.14,
                height: 1.1,
                fontSize: 12.sp,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: SizedBox(
              height: 25.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Mohamad Katmawi",
                    style: context.textTheme.titleLarge?.rq.copyWith(
                      color: const Color(0xff1D1D1D),
                      letterSpacing: 0.14,
                      height: 1.43,
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  SvgPicture.asset(
                    TrydosWalletAssets.nVerify,
                    package: TrydosWalletStyles.packageName,
                    height: 15.h,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 260.h),
          Center(
            child: SvgPicture.asset(
              TrydosWalletAssets.privacy,
              package: TrydosWalletStyles.packageName,
              height: 15.h,
            ),
          ),
          SizedBox(height: 10.h),
          Center(
            child: Text(
              "Your Privacy Is Completely Safe",
              style: context.textTheme.titleLarge?.rq.copyWith(
                color: const Color(0xff4D84FF),
                letterSpacing: 0.14,
                height: 1.43,
                fontSize: 12.sp,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: InkWell(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const StartKycMethods(),
                  ),
                );
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
                    color: const Color(0xffFCFCFC),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Center(
                    child: Text(
                      "Start Verification",
                      style: context.textTheme.displayMedium?.mq.copyWith(
                        color: const Color(0xff5D5C5D),
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

          SizedBox(height: 30.h),
          Center(
            child: InkWell(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              onTap: () async {},
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                child: Text(
                  "Later, Use The Limited Version",
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
        ],
      ),
    );
  }
}
