import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

/// تبويب الإعدادات مع اختيار اللغة.
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        return SingleChildScrollView(
          child: Padding(
            padding: ResponsivePadding.only(
              start: 24,
              end: 24,
              top: 20,
              isRtl: state.isRtl,
            ),
            child: Column(
              crossAxisAlignment: state.isRtl
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.get(state.languageCode, 'settings'),
                  style: TrydosWalletStyles.headlineMedium.copyWith(
                    color: const Color(0xff1D1D1D),
                  ),
                ),
                const SizedBox(height: 20),

                // Language Selection Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffE0E0E0)),
                  ),
                  child: Column(
                    crossAxisAlignment: state.isRtl
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.get(state.languageCode, 'language'),
                        style: TrydosWalletStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1D1D1D),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildLanguageOption(
                        context,
                        state,
                        'en',
                        AppStrings.get(state.languageCode, 'english'),
                      ),
                      const SizedBox(height: 8),
                      _buildLanguageOption(
                        context,
                        state,
                        'ar',
                        AppStrings.get(state.languageCode, 'arabic'),
                      ),
                      const SizedBox(height: 8),
                      _buildLanguageOption(
                        context,
                        state,
                        'ku',
                        AppStrings.get(state.languageCode, 'kurdish'),
                      ),
                      const SizedBox(height: 8),
                      _buildLanguageOption(
                        context,
                        state,
                        'tr',
                        AppStrings.get(state.languageCode, 'turkish'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Information Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffE0E0E0)),
                  ),
                  child: Column(
                    crossAxisAlignment: state.isRtl
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.get(state.languageCode, 'about'),
                        style: TrydosWalletStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1D1D1D),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppStrings.get(state.languageCode, 'version'),
                            style: TrydosWalletStyles.bodySmall.copyWith(
                              color: const Color(0xff8D8D8D),
                            ),
                          ),
                          Text(
                            '1.0.0',
                            style: TrydosWalletStyles.bodySmall.copyWith(
                              color: const Color(0xff1D1D1D),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Logout Button
                GestureDetector(
                  onTap: () => TrydosWallet.logout(),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xffFFF5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffFFD6D6)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.get(state.languageCode, 'logout'),
                          style: TrydosWalletStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xffFF3B3B),
                          ),
                        ),
                        const Icon(
                          Icons.logout,
                          color: Color(0xffFF3B3B),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    WalletState state,
    String languageCode,
    String languageName,
  ) {
    final isSelected = state.languageCode == languageCode;

    return GestureDetector(
      onTap: () {
        context.read<WalletBloc>().add(WalletLanguageChanged(languageCode));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: isSelected ? const Color(0xFF388CFF).withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF388CFF) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              languageName,
              style: TrydosWalletStyles.bodySmall.copyWith(
                color: isSelected
                    ? const Color(0xFF388CFF)
                    : const Color(0xff1D1D1D),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Color(0xFF388CFF), size: 20),
          ],
        ),
      ),
    );
  }
}
