import 'dart:io';
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
class VideoCallRequest extends StatelessWidget {
  final Function()? onTapNextPage;
  final Function()? onSkip;
  final String? selfiePath;
  final String? backIdPath;
  const VideoCallRequest({
    super.key,
    this.onTapNextPage,
    this.onSkip,
    this.selfiePath,
    this.backIdPath,
  });

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
              child: Container(
                height: 400.h,
                width: 1.sw,
                margin: EdgeInsets.symmetric(horizontal: 40.w),

                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.3,
                      child: Container(
                        width: 1.sw,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xff34D317),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30.r),
                          child: selfiePath != null
                              ? Image.file(
                                  File(selfiePath!),
                                  height: 400.h,
                                  fit: BoxFit.fitWidth,
                                )
                              : Image.asset(
                                  TrydosWalletPngAssets.personImage,
                                  package: TrydosWalletStyles.packageName,
                                  height: 400.h,
                                  width: 1.sw,
                                  fit: BoxFit.fitWidth,
                                ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10.h,
                      child: Opacity(
                        opacity: 0.3,
                        child: Container(
                          height: 157.h,
                          width: 280.w,
                          margin: EdgeInsets.symmetric(horizontal: 40.w),

                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xff34D317),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30.r),
                            child: backIdPath != null
                                ? Image.file(
                                    File(backIdPath!),
                                    fit: BoxFit.fitWidth,
                                    height: 157.h,
                                    width: 280.w,
                                  )
                                : Image.asset(
                                    TrydosWalletPngAssets.backImage,
                                    package: TrydosWalletStyles.packageName,
                                    fit: BoxFit.fitWidth,
                                    height: 157.h,
                                    width: 280.w,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      child: Container(
                        height: 340.h,
                        width: 1.sw,
                        margin: EdgeInsets.symmetric(horizontal: 30.w),

                        decoration: BoxDecoration(
                          color: const Color(0xff000000),

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
                AppStrings.get(lang, 'kyc_ai_call_description'),
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
                    border: Border.all(color: const Color(0xff388CFF)),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Center(
                    child: Text(
                      AppStrings.get(lang, 'kyc_start_video_call'),
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
            SizedBox(height: 30.h),
            Center(
              child: InkWell(
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                onTap: () {
                  onSkip?.call();
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Text(
                    AppStrings.get(lang, 'kyc_later'),
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
            SizedBox(height: 35.h),
          ],
        );
      },
    );
  }
}
