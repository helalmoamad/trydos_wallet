import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
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
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Column(
                    children: [
                      WalletHeader(fromSettings: true),
                      SizedBox(height: 18.h, width: 1.sw),
                      _personInfoWidget(context, state),
                      SizedBox(height: 18.h, width: 1.sw),
                      Container(
                        padding: EdgeInsets.all(10.r),

                        height: 65.h,
                        width: 1.sw,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 243, 219, 187),
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                SvgPicture.asset(
                                  TrydosWalletAssets.setting,
                                  package: TrydosWalletStyles.packageName,
                                  height: 15.h,
                                  color: const Color(0xFF1D1D1D),
                                ),
                                SizedBox(width: 10.w),
                                Text(
                                  "Limit Access",
                                  style: TextStyle(
                                    color: const Color(0xFF1D1D1D),
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Spacer(),
                                SvgPicture.asset(
                                  TrydosWalletAssets.question,
                                  package: TrydosWalletStyles.packageName,
                                  height: 15.h,
                                  color: const Color(0xFF1D1D1D),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  "WEEKLY TRANSFER VOLUME",
                                  style: TextStyle(
                                    color: const Color(0xFF1D1D1D),
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "60/15",
                                  style: TextStyle(
                                    color: const Color(0xFF1D1D1D),
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "USD | RENEW",
                                  style: TextStyle(
                                    color: const Color(0xFF1D1D1D),
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "FRI 10:10",
                                  style: TextStyle(
                                    color: const Color(0xFF1D1D1D),
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 5.h, width: 1.sw),
                      Container(
                        padding: EdgeInsets.all(10.r),

                        height: 105.h,
                        width: 1.sw,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 200, 228, 255),
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
                                  "PROTECT YOUR ACCOUNT & GET FULL ACCESS",
                                  style: TextStyle(
                                    color: const Color(0xFF1D1D1D),
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Spacer(),
                                SvgPicture.asset(
                                  TrydosWalletAssets.question,
                                  package: TrydosWalletStyles.packageName,
                                  height: 15.h,
                                  color: const Color(0xFF1D1D1D),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  "KEEP YOUR ACCOUNT SECURE, ENSURE SAFE TRANSACTIONS",
                                  style: TextStyle(
                                    color: const Color(0xFF1D1D1D),
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              alignment: Alignment.center,
                              margin: EdgeInsets.only(top: 10.h),
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 8.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 161, 184, 247),
                                borderRadius: BorderRadius.circular(10.r),
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
                                      "PROTECT NOW",
                                      style: TextStyle(
                                        color: const Color(0xFF1D1D1D),
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 18.h, width: 1.sw),

                      _actionWidget(
                        TrydosWalletAssets.setting,
                        "settings",
                        context,
                      ),

                      SizedBox(height: 10.h, width: 1.sw),
                      _actionWidget(
                        TrydosWalletAssets.setting,
                        "terms_conditions",
                        context,
                      ),
                      SizedBox(height: 10.h, width: 1.sw),
                      _actionWidget(
                        TrydosWalletAssets.setting,
                        "legal_information",
                        context,
                      ),
                      SizedBox(height: 10.h, width: 1.sw),
                      _actionWidget(
                        TrydosWalletAssets.setting,
                        "about_us",
                        context,
                      ),
                      SizedBox(height: 10.h, width: 1.sw),
                      _actionWidget(
                        TrydosWalletAssets.setting,
                        "share_app",
                        context,
                      ),
                      SizedBox(height: 10.h, width: 1.sw),
                      InkWell(
                        onTap: TrydosWallet.logout,
                        child: _actionWidget(
                          TrydosWalletAssets.setting,
                          "logout",
                          context,
                        ),
                      ),
                      SizedBox(height: 10.h, width: 1.sw),
                      _LanguageSelector(state: state),
                      SizedBox(height: 10.h, width: 1.sw),
                    ],
                  ),
                ),
              ),
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

Widget _actionWidget(String svgUrl, String actionName, BuildContext context) {
  return Container(
    padding: EdgeInsets.all(12.r),
    height: 54.h,
    width: 1.sw,
    decoration: BoxDecoration(
      color: const Color(0xffF8F8F8),
      borderRadius: BorderRadius.circular(15.r),
    ),
    child: Row(
      children: [
        SvgPicture.asset(svgUrl),
        const SizedBox(width: 10),
        Text(
          actionName,
          style: context.textTheme.bodyMedium?.rq.copyWith(
            color: const Color(0xff1D1D1D),
            letterSpacing: 0.18,
            fontSize: 14.sp,
            height: 1.3,
          ),
        ),
      ],
    ),
  );
}

Widget _personInfoWidget(BuildContext context, WalletState state) {
  Balance? _resolveReceiveBalance(WalletState state) {
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

  String _accountNumberFromState(WalletState state) {
    final balanceNumber = (_resolveReceiveBalance(state)?.accountNumber ?? '')
        .trim();
    final accountNumber = balanceNumber.isNotEmpty
        ? balanceNumber
        : (Balance.lastMyAccountsPrimaryWallet?.accountNumber ?? '');
    return accountNumber;
  }

  return Container(
    padding: EdgeInsets.all(12.r),
    decoration: BoxDecoration(
      color: const Color(0xffF8F8F8),
      borderRadius: BorderRadius.circular(15.r),
    ),
    width: 1.sw,

    child: Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset(
              TrydosWalletAssets.realQr,
              package: TrydosWalletStyles.packageName,
              height: 30.h,
            ),
            SizedBox(height: 5.h),
            SizedBox(
              height: 20.h,
              child: Row(
                children: [
                  Text(
                    _accountNumberFromState(state),
                    style: context.textTheme.bodyMedium?.bq.copyWith(
                      color: const Color(0xff1D1D1D),
                      letterSpacing: 0.18,
                      fontSize: 14.sp,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    "ID",
                    style: context.textTheme.bodyMedium?.mq.copyWith(
                      color: const Color(0xff1D1D1D),
                      letterSpacing: 0.18,
                      fontSize: 14.sp,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 20.h,
              child: Row(
                children: [
                  Text(
                    '${state.firstName} ${state.lastName}',
                    style: context.textTheme.bodyMedium?.mq.copyWith(
                      color: const Color(0xff1D1D1D),
                      letterSpacing: 0.18,
                      fontSize: 14.sp,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(width: 5.w),
                  SvgPicture.asset(
                    TrydosWalletAssets.nVerify,
                    package: TrydosWalletStyles.packageName,
                    height: 15.h,
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 20.h,
              child: Row(
                children: [
                  Text(
                    state.phoneNumber ?? '---',
                    style: context.textTheme.bodyMedium?.bq.copyWith(
                      color: const Color(0xff1D1D1D),
                      letterSpacing: 0.18,
                      fontSize: 14.sp,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(width: 5.w),
                  SvgPicture.asset(
                    TrydosWalletAssets.phone,
                    package: TrydosWalletStyles.packageName,
                    height: 15.h,
                    color: const Color.fromARGB(255, 59, 59, 59),
                  ),
                ],
              ),
            ),
            SizedBox(height: 5.h),
          ],
        ),
        Spacer(),
        Container(
          height: 90.h,
          width: 90.w,
          decoration: BoxDecoration(
            color: const Color(0xff1D1D1D),
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Center(
            child: Text(
              '${state.firstName.isNotEmpty ? state.firstName[0] : ''} ${state.lastName.isNotEmpty ? state.lastName[0] : ''}',
              style: context.textTheme.headlineMedium?.copyWith(
                color: const Color(0xffF8F8F8),
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    ),
  );
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

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.state});

  final WalletState state;

  @override
  Widget build(BuildContext context) {
    final selected = _languageOptions.firstWhere(
      (option) => option.code == state.languageCode,
      orElse: () => _languageOptions.first,
    );

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
              Text(
                option.flag,
                style: context.textTheme.bodyMedium?.mq.copyWith(
                  fontSize: 16.sp,
                ),
              ),
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
                Icon(Icons.check_circle, color: Color(0xFF2E6AE8), size: 20.h),
            ],
          ),
        );
      }).toList(),
      child: Container(
        constraints: const BoxConstraints(minWidth: 150, maxWidth: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD9D9D9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selected.flag,
              style: context.textTheme.bodyMedium?.mq.copyWith(fontSize: 16),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                AppStrings.get(state.languageCode, selected.labelKey),
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.mq.copyWith(
                  color: const Color(0xFF1D1D1D),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              selected.code.toUpperCase(),
              style: TrydosWalletStyles.bodySmall.copyWith(
                color: const Color(0xFF8D8D8D),
                fontSize: 11,
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF8D8D8D),
              size: 20.h,
            ),
          ],
        ),
      ),
    );
  }
}

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
