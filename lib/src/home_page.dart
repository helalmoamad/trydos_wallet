import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'assets.dart';
import 'bloc/bloc.dart';
import 'models/models.dart';
import 'services/currencies_api_service.dart';
import 'services/transactions_api_service.dart';
import 'styles.dart';
import 'tabs/tabs.dart';

/// Digital wallet home page.
class TrydosWalletHomePage extends StatelessWidget {
  const TrydosWalletHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PaginatedApiBloc<Currency>(
            fetcher: (page, limit) => CurrenciesApiService().getCurrencies(
              CurrenciesQueryParams(page: page, limit: limit),
            ),
            defaultErrorMessage: 'Failed to load currencies',
          )..add(const ApiLoadRequested()),
        ),
        BlocProvider(
          create: (context) => BalancesBloc(),
        ),
        BlocProvider(
          create: (context) => CursorPaginatedApiBloc<Transaction>(
            fetcher: (cursor, limit) => TransactionsApiService()
                .getTransactions(cursor: cursor, limit: limit),
            defaultErrorMessage: 'Failed to load transactions',
          )..add(const ApiLoadRequested()),
        ),
      ],
      child: const _TrydosWalletHomePageContent(),
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
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: const Color(0xFFF5F5F5),
      currentIndex: _selectedIndex,
      onTap: (index) => setState(() => _selectedIndex = index),
      selectedItemColor: Colors.black87,
      unselectedItemColor: Colors.grey,
      selectedLabelStyle: TrydosWalletStyles.bodySmall.copyWith(fontSize: 10),
      unselectedLabelStyle:
          TrydosWalletStyles.bodySmall.copyWith(fontSize: 10),
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
          label: 'Home',
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
          label: 'Transactions',
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
          label: 'Addresses',
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
          label: 'Settings',
        ),
      ],
    );
  }
}
