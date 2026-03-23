import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

import '../widgets/widgets.dart';

/// Scrollable settings tab with readonly user information.
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        final isRtl = state.isRtl;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const WalletHeader(),
            Padding(
              padding: ResponsivePadding.only(
                start: 24,
                end: 24,
                top: 1,
                isRtl: isRtl,
              ),
              child: const Divider(height: 0.5, color: Color(0xffD3D3D3)),
            ),
            Padding(
              padding: ResponsivePadding.only(
                start: 16,
                end: 16,
                top: 14,
                bottom: 24,
                isRtl: isRtl,
              ),
              child: Column(
                crossAxisAlignment: ResponsiveAlignment.crossAxisAlignment(
                  isRtl,
                ),
                children: [
                  _ProfileCard(state: state),
                  const SizedBox(height: 20),
                  _SectionTitle(
                    title: AppStrings.get(
                      state.languageCode,
                      'personal_information',
                    ),
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 10),
                  _SettingsInfoCard(
                    icon: Icons.phone_outlined,
                    label: AppStrings.get(state.languageCode, 'phone_number'),
                    valueWidget: Wrap(
                      spacing: 8,
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
                            style: TrydosWalletStyles.bodyMedium.copyWith(
                              color: const Color(0xFF25B660),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
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
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 20),
                  _SectionTitle(
                    title: AppStrings.get(
                      state.languageCode,
                      'account_information',
                    ),
                  ),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 10),
                  _LanguageCard(state: state),
                  const SizedBox(height: 24),
                  _LogoutButton(languageCode: state.languageCode),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.state});

  final WalletState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _ProfileAvatar(
            profileImageUrl: state.profileImageUrl,
            firstName: state.firstName,
            lastName: state.lastName,
          ),
          const SizedBox(height: 14),
          Text(
            _displayName(
              state.firstName,
              state.lastName,
              AppStrings.get(state.languageCode, 'not_provided'),
            ),
            textAlign: TextAlign.center,
            style: TrydosWalletStyles.bodyMedium.copyWith(
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
}

class _ProfileAvatar extends StatelessWidget {
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
      width: 86,
      height: 86,
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

class _InitialsAvatar extends StatelessWidget {
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
}

class _SectionTitle extends StatelessWidget {
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: const Color(0xFF2E6AE8), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: ResponsiveAlignment.crossAxisAlignment(isRtl),
              children: [
                Text(
                  label,
                  style: TrydosWalletStyles.bodyMedium.copyWith(
                    color: const Color(0xFF8D8D8D),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
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
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.state});

  final WalletState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(18),
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
          const SizedBox(width: 12),
          Text(
            AppStrings.get(state.languageCode, 'language'),
            style: TrydosWalletStyles.bodyMedium.copyWith(
              color: const Color(0xFF8D8D8D),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      itemBuilder: (context) => _languageOptions.map((option) {
        final isSelected = option.code == state.languageCode;
        return PopupMenuItem<String>(
          value: option.code,
          child: Row(
            children: [
              Text(option.flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppStrings.get(state.languageCode, option.labelKey),
                      style: TrydosWalletStyles.bodyMedium.copyWith(
                        color: const Color(0xFF1D1D1D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      option.nativeLabel,
                      style: TrydosWalletStyles.bodySmall.copyWith(
                        color: const Color(0xFF8D8D8D),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2E6AE8),
                  size: 20,
                ),
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
            Text(selected.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppStrings.get(state.languageCode, selected.labelKey),
                overflow: TextOverflow.ellipsis,
                style: TrydosWalletStyles.bodyMedium.copyWith(
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
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF8D8D8D),
              size: 20,
            ),
          ],
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
          style: TrydosWalletStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

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
