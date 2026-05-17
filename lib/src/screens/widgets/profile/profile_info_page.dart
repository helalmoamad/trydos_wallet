import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/src/screens/widgets/profile/client_name_page.dart';
import 'package:trydos_wallet/src/screens/widgets/profile/client_phone_page.dart';
import 'package:trydos_wallet/src/screens/widgets/profile/client_qr_page.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

class ProfileInfoPage extends StatelessWidget {
  const ProfileInfoPage({
    super.key,
    required this.languageCode,
    required this.accountNumber,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    required this.isAccountActive,
    required this.isPhoneVerified,
    this.memberSince,
    this.isVerified = false,
    this.profileImagePath,
  });

  final String languageCode;
  final String accountNumber;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final bool isAccountActive;
  final bool isPhoneVerified;
  final DateTime? memberSince;
  final String? profileImagePath;
  final bool isVerified;

  bool get _isRtl => languageCode == 'ar' || languageCode == 'ku';

  String _valueOrFallback(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return AppStrings.get(languageCode, 'not_provided');
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    // final hasProfileImage = imagePath != null && imagePath.isNotEmpty;
    final normalizedPhone = phoneNumber?.trim().isNotEmpty == true
        ? (phoneNumber!.startsWith('+') ? phoneNumber! : '+${phoneNumber!}')
        : AppStrings.get(languageCode, 'not_provided');

    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xffFFFFFF),
        body: SafeArea(
          child: SizedBox(
            height: 1.sh,
            width: 1.sw,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Column(
                children: [
                  SizedBox(
                    height: 50.h,
                    width: 1.sw,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
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
                        Text(
                          AppStrings.get(languageCode, 'client_information'),
                          textAlign: TextAlign.center,
                          style: context.textTheme.bodyMedium?.rq.copyWith(
                            fontSize: 16.sp,
                            height: 1.1,
                            color: const Color(0xFF1D1D1D),
                          ),
                        ),
                        SizedBox(width: 20.w),
                        const Spacer(),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ClientQrPage(
                                  languageCode: languageCode,
                                  accountNumber: accountNumber,
                                  firstName: firstName,
                                  lastName: lastName,
                                  isVerified: isVerified,
                                  phoneNumber: phoneNumber,
                                ),
                              ),
                            );
                          },

                          child: _InfoCell(
                            languageCode: languageCode,
                            labelKey: 'client_id_label',
                            value: accountNumber,
                            forceLtr: true,
                            trailing: Row(
                              children: [
                                SizedBox(width: 10.w),
                                Container(
                                  width: 40.w,
                                  height: 40.w,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.r),
                                    color: const Color(0xffFCFCFC),
                                    border: Border.all(
                                      color: const Color(0xffD3D3D3),
                                    ),
                                  ),
                                  child: Center(
                                    child: SvgPicture.asset(
                                      TrydosWalletAssets.realQr,
                                      package: TrydosWalletStyles.packageName,
                                      width: 40.w,
                                      height: 40.w,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCell(
                          languageCode: languageCode,
                          labelKey: 'client_status',
                          withBorder: false,
                          value: AppStrings.get(
                            languageCode,
                            isAccountActive ? 'active' : 'disabled',
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _InfoCell(
                          languageCode: languageCode,
                          labelKey: 'client_since',
                          value: AppStrings.get(
                            languageCode,
                            'client_since_value',
                          ),
                          withBorder: false,
                          forceLtr: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCell(
                          languageCode: languageCode,
                          labelKey: 'client_type',
                          value: AppStrings.get(
                            languageCode,
                            'client_type_personal',
                          ),
                          withBorder: false,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: _InfoCell(
                          languageCode: languageCode,
                          labelKey: 'client_verified',
                          value: AppStrings.get(languageCode, 'verified'),
                          withBorder: false,
                          forceLtr: true,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ClientNamePage(
                            languageCode: languageCode,
                            firstName: firstName,
                            isVerified: isVerified,
                            lastName: lastName,
                          ),
                        ),
                      );
                    },
                    child: _InfoCell(
                      languageCode: languageCode,
                      labelKey: 'client_name',
                      value: _valueOrFallback(firstName),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              !isVerified
                                  ? SizedBox.shrink()
                                  : SvgPicture.asset(
                                      TrydosWalletAssets.nVerify,
                                      package: TrydosWalletStyles.packageName,
                                      // ignore: deprecated_member_use
                                      color: const Color(0xff388CFF),
                                      width: 18.w,
                                      height: 18.w,
                                    ),
                              SizedBox(width: 5.w),
                              SvgPicture.asset(
                                TrydosWalletAssets.files,
                                package: TrydosWalletStyles.packageName,
                                width: 18.w,
                                height: 18.w,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 5.h),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ClientPhonePage(
                            languageCode: languageCode,
                            phoneNumber: phoneNumber,
                          ),
                        ),
                      );
                    },
                    child: _InfoCell(
                      languageCode: languageCode,
                      labelKey: 'client_phone_number',
                      value: normalizedPhone,
                      forceLtr: true,
                    ),
                  ),
                  Spacer(),
                  Container(
                    width: 1.sw,
                    alignment: Alignment.center,
                    height: 56.h,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: BoxDecoration(
                      color: const Color(0xffFCFCFC),
                      borderRadius: BorderRadius.circular(15.r),
                      border: Border.all(color: const Color(0xffD3D3D3)),
                    ),
                    child: Text(
                      AppStrings.get(languageCode, 'delete_my_account_request'),
                      style: context.textTheme.bodySmall?.mq.copyWith(
                        color: const Color(0xff1D1D1D),
                        fontSize: 14.sp,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 95.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({
    required this.languageCode,
    required this.labelKey,
    required this.value,
    this.forceLtr = false,
    this.withBorder = true,
    this.trailing,
  });

  final String languageCode;
  final String labelKey;
  final String value;
  final bool forceLtr;
  final bool? withBorder;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xffFCFCFC),

        borderRadius: BorderRadius.circular(15.r),
        border: withBorder == true
            ? Border.all(color: const Color(0xffD3D3D3))
            : null,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.get(languageCode, labelKey),
                style: context.textTheme.bodySmall?.rq.copyWith(
                  color: const Color(0xff8D8D8D),
                  fontSize: 12.sp,
                  height: 1.1,
                ),
              ),
              Spacer(),
              Text(
                value,
                textDirection: forceLtr ? TextDirection.ltr : null,
                style: context.textTheme.bodyMedium?.mq.copyWith(
                  color: const Color(0xff1D1D1D),
                  fontSize: 14.sp,
                  height: 1.2,
                ),
              ),
            ],
          ),
          Spacer(),
          if (trailing != null) ...[trailing!],
        ],
      ),
    );
  }
}
