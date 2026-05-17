import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

class ClientPhonePage extends StatelessWidget {
  final String languageCode;
  final String? phoneNumber;

  const ClientPhonePage({
    super.key,
    required this.languageCode,
    this.phoneNumber,
  });

  bool get _isRtl => languageCode == 'ar' || languageCode == 'ku';

  @override
  Widget build(BuildContext context) {
    final displayPhone = phoneNumber?.trim().isNotEmpty == true
        ? (phoneNumber!.startsWith('+') ? phoneNumber : '+$phoneNumber')
        : AppStrings.get(languageCode, 'not_provided');

    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xffFFFFFF),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              SizedBox(
                height: 50.h,
                width: 1.sw,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: SvgPicture.asset(
                          TrydosWalletAssets.back,
                          package: TrydosWalletStyles.packageName,
                          height: 20.h,
                          matchTextDirection: true,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        SvgPicture.asset(
                          TrydosWalletAssets.phone,
                          package: TrydosWalletStyles.packageName,
                          width: 20.w,
                          // ignore: deprecated_member_use
                          color: const Color(0xFF1D1D1D),
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          AppStrings.get(languageCode, 'client_phone_number'),
                          textAlign: TextAlign.center,
                          style: context.textTheme.bodyMedium?.rq.copyWith(
                            fontSize: 16.sp,
                            height: 1.1,
                            color: const Color(0xFF1D1D1D),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 40.w),
                    const Spacer(),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Column(
                    children: [
                      // Phone Number Cell
                      Container(
                        height: 55.h,
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffFCFCFC),
                          borderRadius: BorderRadius.circular(15.r),
                          border: Border.all(color: const Color(0xffC3C3C3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.get(
                                languageCode,
                                'client_phone_number',
                              ),
                              style: context.textTheme.bodySmall?.rq.copyWith(
                                color: const Color(0xff8D8D8D),
                                fontSize: 12.sp,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              displayPhone!,
                              textDirection: TextDirection.ltr,
                              style: context.textTheme.bodyMedium?.mq.copyWith(
                                color: const Color(0xFF1D1D1D),
                                fontSize: 14.sp,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10.h),
                      // Add second phone number button
                      Center(
                        child: SvgPicture.asset(
                          TrydosWalletAssets.addPhone,
                          package: TrydosWalletStyles.packageName,
                          height: 20.h,
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Center(
                        child: Text(
                          AppStrings.get(
                            languageCode,
                            'add_second_phone_number',
                          ),
                          textDirection: TextDirection.ltr,
                          style: context.textTheme.bodyMedium?.rq.copyWith(
                            color: const Color(0xFF1D1D1D),
                            fontSize: 11.sp,
                            height: 1.2,
                          ),
                        ),
                      ),
                      SizedBox(height: 50.h),
                      // Warning box 1
                      _InfoBox(
                        icon: TrydosWalletAssets.worrning,
                        backgroundColor: const Color(0xffF2FFF0),
                        title: AppStrings.get(
                          languageCode,
                          'enter_phone_number_you_own',
                        ),
                        description: AppStrings.get(
                          languageCode,
                          'advise_enter_secure_phone',
                        ),
                        languageCode: languageCode,
                      ),
                      SizedBox(height: 5.h),
                      // Warning box 2
                      _InfoBox(
                        icon: TrydosWalletAssets.worrning,
                        backgroundColor: const Color(0xffF2FFF0),
                        title: AppStrings.get(
                          languageCode,
                          'phone_important_for_verification',
                        ),
                        description: AppStrings.get(
                          languageCode,
                          'first_phone_requires_verification',
                        ),
                        languageCode: languageCode,
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom link
              Padding(
                padding: EdgeInsets.only(bottom: 35.h),
                child: InkWell(
                  onTap: () {},
                  child: Text(
                    AppStrings.get(languageCode, 'need_help_about_my_number'),
                    style: context.textTheme.bodySmall?.rq.copyWith(
                      color: const Color(0xff4D84FF),
                      fontSize: 14.sp,
                      height: 1.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String icon;
  final Color backgroundColor;
  final String title;
  final String description;
  final String languageCode;

  const _InfoBox({
    required this.icon,
    required this.backgroundColor,
    required this.title,
    required this.description,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                icon,
                package: TrydosWalletStyles.packageName,
                height: 14.h,
              ),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  title,
                  style: context.textTheme.bodyMedium?.mq.copyWith(
                    color: const Color(0xFF8D8D8D),
                    fontSize: 11.sp,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          Row(
            children: [
              SizedBox(width: 19.w),
              Expanded(
                child: Text(
                  description,
                  style: context.textTheme.bodyMedium?.rq.copyWith(
                    color: const Color(0xFF8D8D8D),
                    fontSize: 11.sp,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
