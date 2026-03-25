import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constent/assets.dart';
import '../bloc/bloc.dart';
import '../localization/app_strings.dart';
import '../constent/styles.dart';
import 'tabs/tabs.dart';

/// Digital wallet home page.
class TrydosWalletHomePage extends StatelessWidget {
  const TrydosWalletHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WalletBloc()..add(const WalletRefreshAllRequested()),
      child: BlocBuilder<WalletBloc, WalletState>(
        buildWhen: (prev, curr) => prev.languageCode != curr.languageCode,
        builder: (context, state) {
          return const _TrydosWalletHomePageContent();
        },
      ),
    );
  }
}

class _TrydosWalletHomePageContent extends StatefulWidget {
  const _TrydosWalletHomePageContent();

  @override
  State<_TrydosWalletHomePageContent> createState() =>
      _TrydosWalletHomePageContentState();
}

class _TrydosWalletHomePageContentState
    extends State<_TrydosWalletHomePageContent> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      buildWhen: (prev, curr) => prev.languageCode != curr.languageCode,
      builder: (context, state) {
        return Directionality(
          textDirection: state.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: IndexedStack(
                index: _selectedIndex,
                children: const [
                  HomeTab(),
                  WalletTab(),
                  AddressesTab(),
                  SettingsTab(),
                ],
              ),
            ),
            bottomNavigationBar: _buildBottomNav(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context, WalletState state) {
    final labels = [
      AppStrings.get(state.languageCode, 'home_title'),
      AppStrings.get(state.languageCode, 'my_wallet'),
      AppStrings.get(state.languageCode, 'addresses'),
      AppStrings.get(state.languageCode, 'settings'),
    ];

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      child: SizedBox(
        height: 75,
        child: Container(
          color: const Color(0xFFF4F5F5),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              _buildCustomBottomNavItem(
                index: 0,
                assetPath: TrydosWalletAssets.home,
                label: labels[0],
              ),
              _buildCustomBottomNavItem(
                index: 1,
                assetPath: TrydosWalletAssets.transactions,
                label: labels[1],
              ),
              _buildCustomBottomNavItem(
                index: 2,
                assetPath: TrydosWalletAssets.addresses,
                label: labels[2],
              ),
              _buildCustomBottomNavItem(
                index: 3,
                assetPath: TrydosWalletAssets.setting,
                label: labels[3],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomBottomNavItem({
    required int index,
    required String assetPath,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;
    final color = isSelected
        ? const Color(0xff404040)
        : const Color(0xffA2A0A0);

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SvgPicture.asset(
              assetPath,
              package: TrydosWalletStyles.packageName,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TrydosWalletStyles.bodySmall.copyWith(
                fontSize: isSelected ? 12 : 10,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
