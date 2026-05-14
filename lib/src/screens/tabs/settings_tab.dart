import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/src/screens/widgets/profile/profile_photo_page.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

import '../widgets/widgets.dart';

/// Scrollable settings tab with readonly user information.
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                WalletHeader(fromSettings: true),
                Padding(
                  padding: EdgeInsetsDirectional.only(start: 24.w, end: 24.w),
                  child: Divider(color: Color(0xffD3D3D3)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: _personInfoWidget(context, state),
                ),
                SizedBox(height: 5.h, width: 1.sw),
                Container(
                  padding: EdgeInsets.all(12.w),
                  margin: EdgeInsets.symmetric(horizontal: 12.w),

                  width: 1.sw,
                  decoration: BoxDecoration(
                    color: const Color(0xffFFF9F0),
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(
                            TrydosWalletAssets.worrning,
                            package: TrydosWalletStyles.packageName,
                            height: 14.h,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            AppStrings.get(
                              state.languageCode,
                              'unprotected_account_limited_access',
                            ),
                            style: context.textTheme.bodyMedium?.mq.copyWith(
                              color: const Color(0xFF1D1D1D),
                              fontSize: 11.sp,
                              height: 1.1,
                            ),
                          ),
                          Spacer(),
                          SvgPicture.asset(
                            TrydosWalletAssets.question,
                            package: TrydosWalletStyles.packageName,
                            height: 14.h,
                            color: const Color(0xFFC3C3C3),
                          ),
                        ],
                      ),
                      SizedBox(height: 5.h),
                      Row(
                        children: [
                          SizedBox(width: 19.w),
                          Text(
                            AppStrings.get(
                              state.languageCode,
                              'weekly_transfer_volume',
                            ),
                            style: context.textTheme.bodyMedium?.rq.copyWith(
                              color: const Color(0xFF1D1D1D),
                              fontSize: 11.sp,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            " 60/15 ",
                            style: context.textTheme.bodyMedium?.bq.copyWith(
                              color: const Color(0xFF1D1D1D),
                              fontSize: 11.sp,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            AppStrings.get(state.languageCode, 'usd_renew'),
                            style: context.textTheme.bodyMedium?.rq.copyWith(
                              color: const Color(0xFF1D1D1D),
                              fontSize: 11.sp,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            ' fri_1010',
                            style: context.textTheme.bodyMedium?.rq.copyWith(
                              color: const Color(0xFF1D1D1D),
                              fontSize: 11.sp,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 5.h, width: 1.sw),
                Container(
                  padding: EdgeInsets.all(12.w),
                  margin: EdgeInsets.symmetric(horizontal: 12.w),

                  width: 1.sw,
                  decoration: BoxDecoration(
                    color: const Color(0xffF0F6FD),
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SvgPicture.asset(
                            TrydosWalletAssets.successVerification,
                            package: TrydosWalletStyles.packageName,
                            height: 15.h,
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            AppStrings.get(
                              state.languageCode,
                              'protect_account_full_access',
                            ),
                            style: context.textTheme.bodyMedium?.mq.copyWith(
                              color: const Color(0xFF1D1D1D),
                              fontSize: 11.sp,
                              height: 1.1,
                            ),
                          ),
                          Spacer(),
                          SvgPicture.asset(
                            TrydosWalletAssets.question,
                            package: TrydosWalletStyles.packageName,
                            height: 14.h,
                            color: const Color(0xFFC3C3C3),
                          ),
                        ],
                      ),
                      SizedBox(height: 5.h),
                      Row(
                        children: [
                          Text(
                            AppStrings.get(
                              state.languageCode,
                              'secure_account_safe_transactions',
                            ),
                            style: context.textTheme.bodyMedium?.mq.copyWith(
                              color: const Color(0xFF1D1D1D),
                              fontSize: 11.sp,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        alignment: Alignment.center,
                        margin: EdgeInsets.only(top: 12.h),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffE0EDFF),
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const FirstPageKyc(),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SvgPicture.asset(
                                TrydosWalletAssets.successVerification,
                                package: TrydosWalletStyles.packageName,
                                height: 15.h,
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                AppStrings.get(
                                  state.languageCode,
                                  'protect_verify_now',
                                ),
                                style: context.textTheme.bodyMedium?.mq
                                    .copyWith(
                                      color: const Color(0xFF1D1D1D),
                                      fontSize: 11.sp,
                                      height: 1.1,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h, width: 1.sw),
                Padding(
                  padding: EdgeInsetsDirectional.only(start: 24.w, end: 24.w),
                  child: Divider(color: Color(0xffD3D3D3), height: 0.5),
                ),
                SizedBox(height: 20.h, width: 1.sw),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: SizedBox(
                    height: 1.sh - 560.h,
                    child: ListView(
                      scrollDirection: Axis.vertical,

                      children: [
                        _actionWidget(
                          TrydosWalletAssets.setting,
                          AppStrings.get(state.languageCode, 'settings'),
                          context,
                        ),

                        SizedBox(height: 5.h, width: 1.sw),
                        _actionWidget(
                          TrydosWalletAssets.terms,
                          AppStrings.get(
                            state.languageCode,
                            'terms_conditions',
                          ),
                          context,
                        ),
                        SizedBox(height: 5.h, width: 1.sw),
                        _actionWidget(
                          TrydosWalletAssets.legal,
                          AppStrings.get(
                            state.languageCode,
                            'legal_information',
                          ),
                          context,
                        ),
                        SizedBox(height: 5.h, width: 1.sw),
                        _actionWidget(
                          TrydosWalletAssets.aboutUs,
                          AppStrings.get(state.languageCode, 'about_us'),
                          context,
                        ),
                        SizedBox(height: 5.h, width: 1.sw),
                        _actionWidget(
                          TrydosWalletAssets.shareApp,
                          AppStrings.get(state.languageCode, 'share_app'),
                          context,
                        ),
                        SizedBox(height: 5.h, width: 1.sw),
                        _languageActionWidget(context: context, state: state),
                        SizedBox(height: 5.h, width: 1.sw),
                        InkWell(
                          child: _actionWidget(
                            TrydosWalletAssets.history,
                            AppStrings.get(state.languageCode, 'history'),
                            context,
                            true,
                          ),
                        ),
                        SizedBox(height: 5.h, width: 1.sw),
                        InkWell(
                          onTap: TrydosWallet.logout,
                          child: _actionWidget(
                            TrydosWalletAssets.logout,
                            AppStrings.get(state.languageCode, 'logout'),
                            context,
                          ),
                        ),
                        SizedBox(height: 20.h, width: 1.sw),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        /* ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const WalletHeader(),
            Padding(
              padding: ResponsivePadding.only(
                start: 24.w,
                end: 24.w,
                top: 1.h,
                isRtl: isRtl,
              ),
              child: const Divider(height: 0.5, color: Color(0xffD3D3D3)),
            ),
            Padding(
              padding: ResponsivePadding.only(
                start: 16.w,
                end: 16.w,
                top: 14.h,
                bottom: 24.h,
                isRtl: isRtl,
              ),
              child: Column(
                crossAxisAlignment: ResponsiveAlignment.crossAxisAlignment(
                  isRtl,
                ),
                children: [
                  _ProfileCard(state: state),
                  SizedBox(height: 20.h),
                  _SectionTitle(
                    title: AppStrings.get(
                      state.languageCode,
                      'personal_information',
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _SettingsInfoCard(
                    icon: Icons.email_outlined,
                    label: AppStrings.get(state.languageCode, 'email'),
                    value: _displayValue(
                      state.email,
                      fallback: AppStrings.get(
                        state.languageCode,
                        'not_provided',
                      ),
                    ),
                    isRtl: isRtl,
                    forceLtrValue: true,
                  ),
                  SizedBox(height: 10.h),
                  _SettingsInfoCard(
                    icon: Icons.phone_outlined,
                    label: AppStrings.get(state.languageCode, 'phone_number'),
                    valueWidget: Wrap(
                      spacing: 8.h,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          _displayValue(
                            state.phoneNumber,
                            fallback: AppStrings.get(
                              state.languageCode,
                              'not_provided',
                            ),
                          ),
                          textDirection: TextDirection.ltr,
                          style: _valueTextStyle(),
                        ),
                        if (state.isPhoneVerified)
                          Text(
                            '✓ ${AppStrings.get(state.languageCode, 'verified')}',
                            style: context.textTheme.bodyMedium?.mq.copyWith(
                              color: const Color(0xFF25B660),
                              fontWeight: FontWeight.w600,
                              fontSize: 12.sp,
                            ),
                          ),
                      ],
                    ),
                    isRtl: isRtl,
                  ),
                  const SizedBox(height: 10),
                  _SettingsInfoCard(
                    icon: Icons.person_outline,
                    label: AppStrings.get(state.languageCode, 'first_name'),
                    value: _displayValue(
                      state.firstName,
                      fallback: AppStrings.get(
                        state.languageCode,
                        'not_provided',
                      ),
                    ),
                    isRtl: isRtl,
                  ),
                  SizedBox(height: 10.h),
                  _SettingsInfoCard(
                    icon: Icons.person_outline,
                    label: AppStrings.get(state.languageCode, 'last_name'),
                    value: _displayValue(
                      state.lastName,
                      fallback: AppStrings.get(
                        state.languageCode,
                        'not_provided',
                      ),
                    ),
                    isRtl: isRtl,
                    italicWhenFallback: _isBlank(state.lastName),
                  ),
                  SizedBox(height: 20.h),
                  _SectionTitle(
                    title: AppStrings.get(
                      state.languageCode,
                      'account_information',
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _SettingsInfoCard(
                    icon: Icons.shield_outlined,
                    label: AppStrings.get(state.languageCode, 'account_status'),
                    value: AppStrings.get(
                      state.languageCode,
                      state.isAccountActive ? 'active' : 'disabled',
                    ),
                    valueColor: const Color(0xFF25B660),
                    isRtl: isRtl,
                  ),
                  SizedBox(height: 10.h),
                  _SettingsInfoCard(
                    icon: Icons.visibility_outlined,
                    label: AppStrings.get(
                      state.languageCode,
                      'two_factor_authentication',
                    ),
                    value: AppStrings.get(
                      state.languageCode,
                      state.isTwoFactorEnabled ? 'enabled' : 'disabled',
                    ),
                    isRtl: isRtl,
                  ),
                  SizedBox(height: 10.h),
                  _SettingsInfoCard(
                    icon: Icons.calendar_today_outlined,
                    label: AppStrings.get(state.languageCode, 'member_since'),
                    value: _formatMemberSince(
                      state.memberSince,
                      AppStrings.get(state.languageCode, 'not_provided'),
                    ),
                    isRtl: isRtl,
                    forceLtrValue: true,
                  ),
                  SizedBox(height: 10.h),
                  _LanguageCard(state: state),
                  SizedBox(height: 24.h),
                  _KycButton(languageCode: state.languageCode),
                  SizedBox(height: 12.h),
                  _LogoutButton(languageCode: state.languageCode),
                ],
              ),
            ),
          ],
        );*/
      },
    );
  }
}

Widget _actionWidget(
  String svgUrl,
  String actionName,
  BuildContext context, [
  bool isActiveSession = false,
]) {
  final languageCode = context.read<WalletBloc>().state.languageCode;

  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 20.h),
    height: 58.h,
    width: 1.sw,
    decoration: BoxDecoration(
      color: const Color(0xffF8F8F8),
      borderRadius: BorderRadius.circular(15.r),
    ),
    child: Row(
      children: [
        SvgPicture.asset(
          svgUrl,
          package: TrydosWalletStyles.packageName,
          height: 18.h,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                actionName,
                style: context.textTheme.bodyMedium?.rq.copyWith(
                  color: const Color(0xff1D1D1D),
                  letterSpacing: 0.18,
                  fontSize: 14.sp,
                  height: 1.3,
                ),
              ),
              SizedBox(width: 40.w),
              isActiveSession
                  ? Text(
                      AppStrings.get(languageCode, 'active_session'),
                      style: context.textTheme.bodyMedium?.lq.copyWith(
                        color: const Color(0xff1D1D1D),
                        letterSpacing: 0.18,
                        fontSize: 11.sp,
                        height: 1.3,
                      ),
                    )
                  : SizedBox.shrink(),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _languageActionWidget({
  required BuildContext context,
  required WalletState state,
}) {
  return PopupMenuButton<String>(
    tooltip: AppStrings.get(state.languageCode, 'select_language'),
    onSelected: (languageCode) {
      context.read<WalletBloc>().add(WalletLanguageChanged(languageCode));
    },
    color: Colors.white,
    position: PopupMenuPosition.under,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
    itemBuilder: (context) => _languageOptions.map((option) {
      final isSelected = option.code == state.languageCode;
      return PopupMenuItem<String>(
        value: option.code,
        child: Row(
          children: [
            Text(option.flag, style: TextStyle(fontSize: 16.sp)),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.get(state.languageCode, option.labelKey),
                    style: context.textTheme.bodyMedium?.mq.copyWith(
                      color: const Color(0xFF1D1D1D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    option.nativeLabel,
                    style: context.textTheme.bodySmall?.mq.copyWith(
                      color: const Color(0xFF8D8D8D),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: const Color(0xFF2E6AE8),
                size: 20.h,
              ),
          ],
        ),
      );
    }).toList(),
    child: Container(
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Expanded(
            child: _actionWidget(
              TrydosWalletAssets.language,
              AppStrings.get(state.languageCode, 'language'),
              context,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _personInfoWidget(BuildContext context, WalletState state) {
  Balance? resolveReceiveBalance(WalletState state) {
    if (state.selectedAssetId != null) {
      final selected = state.balances[state.selectedAssetId!];
      if (selected != null) return selected;
    }

    for (final balance in state.balances.values) {
      if (balance.assetSymbol.toUpperCase() == 'USD') {
        return balance;
      }
    }

    if (state.balances.isNotEmpty) {
      return state.balances.values.first;
    }
    return null;
  }

  String accountNumberFromState(WalletState state) {
    final balanceNumber = (resolveReceiveBalance(state)?.accountNumber ?? '')
        .trim();
    final accountNumber = balanceNumber.isNotEmpty
        ? balanceNumber
        : (Balance.lastMyAccountsPrimaryWallet?.accountNumber ?? '');
    return accountNumber;
  }

  final profileImagePath = state.profileImageUrl?.trim();
  final hasProfileImage =
      profileImagePath != null && profileImagePath.isNotEmpty;

  void openProfilePhotoPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfilePhotoPage(
          languageCode: state.languageCode,
          initialImagePath: profileImagePath,
        ),
      ),
    );
  }

  return Container(
    padding: EdgeInsets.all(12.w),
    decoration: BoxDecoration(
      color: const Color(0xffFCFCFC),
      borderRadius: BorderRadius.circular(15.r),
    ),
    width: 1.sw,
    height: 140.h,
    child: Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SvgPicture.asset(
              TrydosWalletAssets.realQr,
              package: TrydosWalletStyles.packageName,
              height: 50.h,
            ),

            Row(
              children: [
                Text(
                  accountNumberFromState(state),
                  style: context.textTheme.bodyMedium?.bq.copyWith(
                    color: const Color(0xff1D1D1D),
                    letterSpacing: 0.18,
                    fontSize: 13.sp,
                    height: 1.3,
                  ),
                  textDirection: TextDirection.ltr,
                ),
                SizedBox(width: 5.w),
                Text(
                  "ID",
                  style: context.textTheme.bodyMedium?.rq.copyWith(
                    color: const Color(0xff1D1D1D),
                    letterSpacing: 0.18,
                    fontSize: 13.sp,
                    height: 1.3,
                  ),
                ),
              ],
            ),

            Row(
              children: [
                Text(
                  '${state.firstName} ${state.lastName}',
                  style: context.textTheme.bodyMedium?.rq.copyWith(
                    color: const Color(0xff1D1D1D),
                    letterSpacing: 0.18,
                    fontSize: 13.sp,
                    height: 1.3,
                  ),
                ),
                /*    SizedBox(width: 5.w),
                SvgPicture.asset(
                  TrydosWalletAssets.nVerify,
                  package: TrydosWalletStyles.packageName,
                  height: 15.h,
                ),*/
              ],
            ),

            Row(
              children: [
                Text(
                  state.phoneNumber ?? '---',
                  style: context.textTheme.bodyMedium?.rq.copyWith(
                    color: const Color(0xff1D1D1D),
                    letterSpacing: 0.18,
                    fontSize: 11.sp,
                    height: 1.3,
                  ),
                ),
                SizedBox(width: 10.w),
                SvgPicture.asset(
                  TrydosWalletAssets.phone,
                  package: TrydosWalletStyles.packageName,
                  height: 10.h,
                  color: const Color(0xff8D8D8D),
                ),
              ],
            ),
            SizedBox(height: 5.h),
          ],
        ),
        Spacer(),
        Container(
          height: 116.h,
          width: 116.w,
          decoration: BoxDecoration(
            color: const Color(0xffFCFCFC),
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: const Color(0xffC3C3C3)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: InkWell(
                  onTap: openProfilePhotoPage,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15.r),
                    child: hasProfileImage
                        ? Image.file(
                            File(profileImagePath),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _ProfileImagePlaceholder(),
                          )
                        : _ProfileImagePlaceholder(),
                  ),
                ),
              ),
              hasProfileImage
                  ? SizedBox.shrink()
                  : Positioned(
                      bottom: 0,
                      child: InkWell(
                        onTap: openProfilePhotoPage,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(15.r),
                          bottomRight: Radius.circular(15.r),
                        ),
                        child: Container(
                          width: 116.w,
                          height: 22.h,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xff404040)),
                            color: const Color(0xff404040),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(15.r),
                              bottomRight: Radius.circular(15.r),
                            ),
                          ),
                          child: Center(
                            child: SizedBox(
                              height: 14.h,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    TrydosWalletAssets.addPhoto,
                                    package: TrydosWalletStyles.packageName,
                                    height: 13.h,
                                  ),
                                  SizedBox(width: 5.w),
                                  Text(
                                    "Add Photo",
                                    style: context.textTheme.bodySmall?.rq
                                        .copyWith(
                                          color: const Color(0xffFCFCFC),
                                          letterSpacing: 0.18,
                                          fontSize: 10.sp,
                                          height: 1.1,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProfileImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xffFCFCFC),
      alignment: Alignment.center,
      child: SvgPicture.asset(
        TrydosWalletAssets.personHide,
        package: TrydosWalletStyles.packageName,
        height: 80.h,
      ),
    );
  }
}
/*
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.state});

  final WalletState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          _ProfileAvatar(
            profileImageUrl: state.profileImageUrl,
            firstName: state.firstName,
            lastName: state.lastName,
          ),
          SizedBox(height: 14.r),
          Text(
            _displayName(
              state.firstName,
              state.lastName,
              AppStrings.get(state.languageCode, 'not_provided'),
            ),
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.mq.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: const Color(0xFF1D1D1D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _displaySubtitle(state),
            textAlign: TextAlign.center,
            style: TrydosWalletStyles.bodyMedium.copyWith(
              color: const Color(0xFF8D8D8D),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}*/

/*class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.profileImageUrl,
    required this.firstName,
    required this.lastName,
  });

  final String? profileImageUrl;
  final String firstName;
  final String lastName;

  @override
  Widget build(BuildContext context) {
    final initials = _buildInitials(firstName, lastName);

    return Container(
      width: 86.w,
      height: 86.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2E6AE8), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: ClipOval(
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xFF2E6AE8)),
            child: _hasImage(profileImageUrl)
                ? Image.network(
                    profileImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _InitialsAvatar(initials: initials),
                  )
                : _InitialsAvatar(initials: initials),
          ),
        ),
      ),
    );
  }
}
*/
/*class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TrydosWalletStyles.headlineMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}*/

/*class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TrydosWalletStyles.headlineMedium.copyWith(
        fontSize: 18,
        color: const Color(0xFF1D1D1D),
      ),
    );
  }
}

class _SettingsInfoCard extends StatelessWidget {
  const _SettingsInfoCard({
    required this.icon,
    required this.label,
    required this.isRtl,
    this.value,
    this.valueWidget,
    this.valueColor = const Color(0xFF1D1D1D),
    this.forceLtrValue = false,
    this.italicWhenFallback = false,
  }) : assert(value != null || valueWidget != null);

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final Color valueColor;
  final bool isRtl;
  final bool forceLtrValue;
  final bool italicWhenFallback;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: const Color(0xFF2E6AE8), size: 22),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: ResponsiveAlignment.crossAxisAlignment(isRtl),
              children: [
                Text(
                  label,
                  style: context.textTheme.bodyMedium?.mq.copyWith(
                    color: const Color(0xFF8D8D8D),
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                valueWidget ??
                    Text(
                      value ?? '',
                      textDirection: forceLtrValue ? TextDirection.ltr : null,
                      style: _valueTextStyle(
                        color: valueColor,
                        italic: italicWhenFallback,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}*/

/*class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.state});

  final WalletState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.language_outlined,
              color: Color(0xFF2E6AE8),
              size: 22,
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            AppStrings.get(state.languageCode, 'language'),
            style: context.textTheme.bodyMedium?.mq.copyWith(
              color: const Color(0xFF8D8D8D),
              fontSize: 12.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _LanguageSelector(state: state),
            ),
          ),
        ],
      ),
    );
  }
}
*/
class _LanguageOptionData {
  const _LanguageOptionData({
    required this.code,
    required this.labelKey,
    required this.nativeLabel,
    required this.flag,
  });

  final String code;
  final String labelKey;
  final String nativeLabel;
  final String flag;
}

const List<_LanguageOptionData> _languageOptions = [
  _LanguageOptionData(
    code: 'en',
    labelKey: 'english',
    nativeLabel: 'English',
    flag: '🇬🇧',
  ),
  _LanguageOptionData(
    code: 'ar',
    labelKey: 'arabic',
    nativeLabel: 'العربية',
    flag: '🇸🇦',
  ),
  _LanguageOptionData(
    code: 'ku',
    labelKey: 'kurdish',
    nativeLabel: 'کوردی',
    flag: '🇮🇶',
  ),
  _LanguageOptionData(
    code: 'tr',
    labelKey: 'turkish',
    nativeLabel: 'Türkçe',
    flag: '🇹🇷',
  ),
];

/*class _KycButton extends StatelessWidget {
  const _KycButton({required this.languageCode});

  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const FirstPageKyc()));
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF2E6AE8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.verified_user_outlined, size: 20),
        label: Text(
          AppStrings.get(languageCode, 'kyc_verify_identity_btn'),
          style: context.textTheme.bodyMedium?.mq.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.languageCode});

  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: TrydosWallet.logout,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFFF94141),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: Text(
          AppStrings.get(languageCode, 'logout'),
          style: context.textTheme.bodyMedium?.mq.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }
}


TextStyle _valueTextStyle({Color? color, bool italic = false}) {
  return TrydosWalletStyles.bodyMedium.copyWith(
    color: color ?? const Color(0xFF1D1D1D),
    fontWeight: FontWeight.w600,
    fontSize: 14,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
  );
}

String _displayValue(String? value, {required String fallback}) {
  if (_isBlank(value)) {
    return fallback;
  }
  return value!.trim();
}

String _displayName(String firstName, String lastName, String fallback) {
  final parts = [
    if (!_isBlank(firstName)) firstName.trim(),
    if (!_isBlank(lastName)) lastName.trim(),
  ];
  if (parts.isEmpty) return fallback;
  return parts.join(' ');
}

String _displaySubtitle(WalletState state) {
  const localizedKeys = {
    'registered',
    'active',
    'disabled',
    'enabled',
    'verified',
  };

  if (_isBlank(state.userSubtitle)) {
    return AppStrings.get(state.languageCode, 'registered');
  }

  final subtitle = state.userSubtitle!.trim();
  if (localizedKeys.contains(subtitle)) {
    return AppStrings.get(state.languageCode, subtitle);
  }

  return subtitle;
}

String _buildInitials(String firstName, String lastName) {
  final first = !_isBlank(firstName) ? firstName.trim()[0].toUpperCase() : '';
  final last = !_isBlank(lastName) ? lastName.trim()[0].toUpperCase() : '';
  final initials = '$first $last';
  return initials.isEmpty ? '?' : initials;
}

String _formatMemberSince(DateTime? memberSince, String fallback) {
  if (memberSince == null) return fallback;
  return '${memberSince.month}/${memberSince.day}/${memberSince.year}';
}

bool _hasImage(String? profileImageUrl) => !_isBlank(profileImageUrl);

bool _isBlank(String? value) => value == null || value.trim().isEmpty;
*/
