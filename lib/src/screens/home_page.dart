import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';

import 'dart:async';

import '../constent/assets.dart';
import '../api/api_interceptors.dart';
import '../bloc/bloc.dart';
import '../localization/app_strings.dart';
import '../constent/styles.dart';
import '../services/connectivity_service.dart';
import 'no_internet_screen.dart';
import 'tabs/tabs.dart';

/// Digital wallet home page.
class TrydosWalletHomePage extends StatelessWidget {
  const TrydosWalletHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    WalletBloc? existingBloc;
    try {
      existingBloc = BlocProvider.of<WalletBloc>(context);
    } catch (_) {
      existingBloc = null;
    }

    if (existingBloc != null) {
      return BlocProvider.value(
        value: existingBloc,
        child: const _TrydosWalletHomePageContent(),
      );
    }

    return BlocProvider(
      create: (context) => WalletBloc(),
      child: const _TrydosWalletHomePageContent(),
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
  StreamSubscription<LogoutEvent>? _logoutSubscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _logoutSubscription = logoutEvents.listen((_) {
      if (!mounted) return;
      context.read<WalletBloc>().add(const WalletResetRequested());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<WalletBloc>();
      bloc.add(const WalletRefreshAllRequested());
      bloc.add(const WalletTransferPurposesLoadRequested());
      ConnectivityService.instance.initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _isOffline = !ConnectivityService.instance.isOnline.value;
        });
      });
      ConnectivityService.instance.isOnline.addListener(_onConnectivityChanged);
    });
  }

  @override
  void dispose() {
    _logoutSubscription?.cancel();
    ConnectivityService.instance.isOnline.removeListener(
      _onConnectivityChanged,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      buildWhen: (prev, curr) => prev.languageCode != curr.languageCode,
      builder: (context, state) {
        return Directionality(
          textDirection: state.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Stack(
            children: [
              Scaffold(
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
              if (_isOffline)
                Positioned.fill(
                  child: NoInternetScreen(languageCode: state.languageCode),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context, WalletState state) {
    final labels = [
      AppStrings.get(state.languageCode, 'home_title'),
      AppStrings.get(state.languageCode, 'transactions'),
      AppStrings.get(state.languageCode, 'addresses'),
      AppStrings.get(state.languageCode, 'settings'),
    ];

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      child: SizedBox(
        height: 80.h,
        child: Container(
          color: const Color(0xFFF4F5F5),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          child: Row(
            children: [
              _buildCustomBottomNavItem(
                index: 0,
                assetPath: _selectedIndex != 0
                    ? TrydosWalletAssets.homeNotTaped
                    : TrydosWalletAssets.home,
                label: labels[0],
              ),
              _buildCustomBottomNavItem(
                index: 1,
                assetPath: _selectedIndex != 1
                    ? TrydosWalletAssets.transactions
                    : TrydosWalletAssets.transactionTaped,
                label: labels[1],
              ),
              _buildCustomBottomNavItem(
                index: 2,
                assetPath: _selectedIndex != 2
                    ? TrydosWalletAssets.addresses
                    : TrydosWalletAssets.addressesTaped,
                label: labels[2],
              ),
              _buildCustomBottomNavItem(
                index: 3,
                assetPath: _selectedIndex != 3
                    ? TrydosWalletAssets.setting
                    : TrydosWalletAssets.settingTaped,
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
              height: 25.h,
              package: TrydosWalletStyles.packageName,
            ),

            Text(
              label,
              style: isSelected
                  ? context.textTheme.bodyMedium?.rq.copyWith(
                      fontSize: 12.sp,
                      color: color,
                    )
                  : context.textTheme.bodyMedium?.lq.copyWith(
                      fontSize: 10.sp,
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

  void _onConnectivityChanged() {
    final online = ConnectivityService.instance.isOnline.value;
    if (!mounted) return;
    setState(() => _isOffline = !online);
    if (online) {
      final bloc = context.read<WalletBloc>();
      bloc.add(const WalletReconnectWebSocketRequested());
      bloc.add(const WalletRefreshAllRequested());
      bloc.add(const WalletTransferPurposesLoadRequested());
    }
  }
}
