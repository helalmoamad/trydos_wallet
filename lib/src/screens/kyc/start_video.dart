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
class StartVideo extends StatelessWidget {
  final Function()? onTapNextPage;
  const StartVideo({super.key, this.onTapNextPage});

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
              AppStrings.get(lang, 'kyc_video_call_from_our_side'),
              style: context.textTheme.titleLarge?.mq.copyWith(
                color: const Color(0xff1D1D1D),
                letterSpacing: 0.14,
                height: 1.1,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 12.h),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 1.sw,
                      height: 640.h,

                      decoration: BoxDecoration(
                        color: const Color(0xff000000),

                        borderRadius: BorderRadius.circular(30.r),
                      ),
                    ),
                    Positioned(
                      bottom: 5.h,
                      right: 5.w,
                      child: Container(
                        height: 200.h,
                        width: 140.w,

                        decoration: BoxDecoration(
                          color: const Color(0xff000000),
                          border: Border.all(color: const Color(0xffFCFCFC)),
                          borderRadius: BorderRadius.circular(25.r),
                        ),
                      ),
                    ),
                  ],
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
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: InkWell(
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                onTap: () {
                  onTapNextPage?.call();
                },
                child: Container(
                  width: 1.sw,
                  height: 60.h,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xffFF5F61)),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Center(
                    child: Text(
                      AppStrings.get(lang, 'kyc_end_video_call'),
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
            SizedBox(height: 35.h),
          ],
        );
      },
    );
  }
}
