import 'dart:io';

import 'package:dotted_border/dotted_border.dart';
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
class SuccessIdCard extends StatelessWidget {
  final Function()? onTapNextPage;
  final Function()? onTapRetry;
  final bool isFinalAttempt;
  final String? frontImagePath;
  final String? backImagePath;
  const SuccessIdCard({
    super.key,
    this.onTapNextPage,
    this.onTapRetry,
    this.isFinalAttempt = false,
    this.frontImagePath,
    this.backImagePath,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        final lang = state.languageCode;
        final extracted = state.kycExtractedData;
        final fullName = extracted?.name?.trim().isNotEmpty == true
            ? extracted!.name!.trim()
            : '${extracted?.firstName ?? ''} ${extracted?.lastName ?? ''}'
                  .trim();

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
                      TrydosWalletAssets.identity,
                      package: TrydosWalletStyles.packageName,
                      height: 20.h,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      AppStrings.get(lang, 'kyc_live_id_done'),
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
            Padding(
              padding: EdgeInsetsGeometry.symmetric(horizontal: 20.w),
              child: backImagePath != null
                  ? Row(
                      children: [
                        Container(
                          height: 109.h,
                          width: 192.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15.r),
                            child: frontImagePath != null
                                ? Image.file(
                                    File(frontImagePath!),
                                    height: 109.h,
                                    width: 192.w,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    TrydosWalletPngAssets.frontImage,
                                    package: TrydosWalletStyles.packageName,
                                    height: 109.h,
                                    width: 192.w,
                                    fit: BoxFit.fitWidth,
                                  ),
                          ),
                        ),
                        SizedBox(width: 5.w),
                        Container(
                          height: 109.h,
                          width: 192.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15.r),
                            child: Image.file(
                              File(backImagePath!),
                              height: 109.h,
                              width: 192.w,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Container(
                        height: 109.h,
                        width: 192.w,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15.r),
                          child: frontImagePath != null
                              ? Image.file(
                                  File(frontImagePath!),
                                  height: 109.h,
                                  width: 192.w,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  TrydosWalletPngAssets.frontImage,
                                  package: TrydosWalletStyles.packageName,
                                  height: 109.h,
                                  width: 192.w,
                                  fit: BoxFit.fitWidth,
                                ),
                        ),
                      ),
                    ),
            ),
            SizedBox(height: 10.h),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: SizedBox(
                height: 25.h,
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
                      AppStrings.get(lang, 'kyc_information_detected'),
                      style: context.textTheme.titleLarge?.mq.copyWith(
                        color: const Color(0xff1D1D1D),
                        letterSpacing: 0.14,
                        height: 1.43,
                        fontSize: 16.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.h),
            _fieldInfo(
              context,
              lang,
              AppStrings.get(lang, 'kyc_id_type'),
              _fallbackValue(
                extracted?.idType ?? extracted?.idName,
                'Personal Identity ID',
              ),
            ),
            SizedBox(height: 5.h),
            _fieldInfo(
              context,
              lang,
              AppStrings.get(lang, 'kyc_country'),
              _fallbackValue(extracted?.country, 'Syria'),
            ),
            SizedBox(height: 5.h),
            _fieldInfo(
              context,
              lang,
              AppStrings.get(lang, 'kyc_name'),
              _fallbackValue(fullName, 'De Bruijn'),
            ),
            SizedBox(height: 5.h),
            _fieldInfo(
              context,
              lang,
              AppStrings.get(lang, 'kyc_national_number'),
              _fallbackValue(
                extracted?.nationalNumber ?? extracted?.documentNumber,
                '09982111123332',
              ),
            ),
            SizedBox(height: 5.h),
            _fieldInfo(
              context,
              lang,
              AppStrings.get(lang, 'kyc_birthday'),
              _fallbackValue(extracted?.birthday, '01.01.1999'),
            ),
            SizedBox(height: 5.h),

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
                onTap: isFinalAttempt ? null : () => onTapNextPage?.call(),
                child: DottedBorder(
                  padding: EdgeInsets.zero,
                  borderType: BorderType.RRect,
                  strokeCap: StrokeCap.round,
                  strokeWidth: 0.5,
                  dashPattern: const [3, 3],
                  radius: Radius.circular(20.r),
                  color: isFinalAttempt
                      ? const Color(0xffFFFFFF)
                      : const Color(0xff5D5C5D),
                  child: Container(
                    width: 1.sw,
                    height: 60.h,

                    decoration: BoxDecoration(
                      color: isFinalAttempt
                          ? const Color(0xffFCFCFC)
                          : const Color(0xffFFFFFF),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Center(
                      child: Text(
                        AppStrings.get(
                          lang,
                          isFinalAttempt
                              ? 'kyc_contact_you_soon'
                              : 'kyc_correct_next',
                        ),
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
            SizedBox(height: 30.h),
            Center(
              child: InkWell(
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                onTap: isFinalAttempt ? null : () => onTapRetry?.call(),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Text(
                    AppStrings.get(lang, 'kyc_incorrect_try_again'),
                    style: context.textTheme.titleLarge?.rq.copyWith(
                      color: isFinalAttempt
                          ? const Color(0xffBDBDBD)
                          : const Color(0xff4D84FF),
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

  String _fallbackValue(String? value, String fallback) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }

  Widget _fieldInfo(
    BuildContext context,
    String lang,
    String title,
    String value,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xffFCFCFC),
        borderRadius: BorderRadius.circular(15.r),
      ),
      height: 56.h,
      width: 1.sw,
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textTheme.titleLarge?.rq.copyWith(
              color: const Color(0xff8D8D8D),
              letterSpacing: 0.14,
              height: 1.43,
              fontSize: 12.sp,
            ),
          ),
          Spacer(),
          Text(
            value,
            style: context.textTheme.titleLarge?.rq.copyWith(
              color: const Color(0xff1D1D1D),
              letterSpacing: 0.14,
              height: 1.43,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }
}
