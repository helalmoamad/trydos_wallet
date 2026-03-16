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
      create: (context) => WalletBloc()
        ..add(const WalletCurrenciesLoadRequested())
        ..add(const WalletTransactionsLoadRequested()),
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
        return Scaffold(
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

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFFF5F5F5),
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      selectedItemColor: Colors.black87,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: TrydosWalletStyles.bodySmall.copyWith(fontSize: 10),
      unselectedLabelStyle: TrydosWalletStyles.bodySmall.copyWith(fontSize: 10),
      items: [
        BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SvgPicture.asset(
              TrydosWalletAssets.home,
              package: TrydosWalletStyles.packageName,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 0
                    ? const Color(0xff404040)
                    : const Color(0xffA2A0A0),
                BlendMode.srcIn,
              ),
            ),
          ),
          label: labels[0],
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SvgPicture.asset(
              TrydosWalletAssets.transactions,
              package: TrydosWalletStyles.packageName,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 1
                    ? const Color(0xff404040)
                    : const Color(0xffA2A0A0),
                BlendMode.srcIn,
              ),
            ),
          ),
          label: labels[1],
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SvgPicture.asset(
              TrydosWalletAssets.addresses,
              package: TrydosWalletStyles.packageName,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 2
                    ? const Color(0xff404040)
                    : const Color(0xffA2A0A0),
                BlendMode.srcIn,
              ),
            ),
          ),
          label: labels[2],
        ),
        BottomNavigationBarItem(
          icon: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SvgPicture.asset(
              TrydosWalletAssets.setting,
              package: TrydosWalletStyles.packageName,
              colorFilter: ColorFilter.mode(
                _selectedIndex == 3
                    ? const Color(0xff404040)
                    : const Color(0xffA2A0A0),
                BlendMode.srcIn,
              ),
            ),
          ),
          label: labels[3],
        ),
      ],
    );
  }
}
