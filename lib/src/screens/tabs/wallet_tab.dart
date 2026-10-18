import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

import '../widgets/widgets.dart';
import '../widgets/home_page_widgets/transactions_list.dart';

/// Transactions tab: every transaction on the account, never filtered by the
/// currency card selected on the home tab.
class WalletTab extends StatefulWidget {
  const WalletTab({super.key, this.isActive = false});

  /// Whether this tab is the one on screen. The list loads the first time it
  /// becomes true, so a user who never opens the tab costs no request.
  final bool isActive;

  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  @override
  void initState() {
    super.initState();
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
    }
  }

  @override
  void didUpdateWidget(covariant WalletTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _loadIfNeeded();
    }
  }

  void _loadIfNeeded() {
    if (!mounted) return;
    final bloc = context.read<WalletBloc>();
    if (bloc.state.allTransactionsStatus == WalletStatus.initial) {
      bloc.add(const WalletAllTransactionsLoadRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        return Directionality(
          textDirection: state.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<WalletBloc>().add(
                const WalletAllTransactionsRefreshRequested(),
              );
            },
            child: SizedBox(
              height: 1.sh,
              width: 1.sw,
              child: Column(
                children: [
                  const WalletHeader(),
                  Expanded(
                    child: TransactionsList(
                      title: AppStrings.get(
                        state.languageCode,
                        'all_transactions',
                      ),
                      transactions: state.allTransactions,
                      status: state.allTransactionsStatus,
                      hasNext: state.allTransactionsHasNext,
                      nextCursor: state.allTransactionsNextCursor,
                      languageCode: state.languageCode,
                      // Nothing else on this tab scrolls, so the list itself
                      // has to carry the pull-to-refresh gesture.
                      physics: const AlwaysScrollableScrollPhysics(),
                      onLoadMore: () => context.read<WalletBloc>().add(
                        const WalletAllTransactionsLoadMoreRequested(),
                      ),
                      onRetry: () => context.read<WalletBloc>().add(
                        const WalletAllTransactionsLoadRequested(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
