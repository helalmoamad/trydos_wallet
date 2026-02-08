import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../assets.dart';
import '../bloc/bloc.dart';
import '../models/models.dart';
import '../styles.dart';
import '../widgets/widgets.dart';

/// Home tab (balances + transactions list).
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  int _selectedTransactionIndex = 0;
  final List<String> _selectedCurrencies = [];
  final ScrollController _currenciesScrollController = ScrollController();
  final ScrollController _transactionsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currenciesScrollController.addListener(_onCurrenciesScroll);
    _transactionsScrollController.addListener(_onTransactionsScroll);
  }

  @override
  void dispose() {
    _currenciesScrollController.removeListener(_onCurrenciesScroll);
    _currenciesScrollController.dispose();
    _transactionsScrollController.removeListener(_onTransactionsScroll);
    _transactionsScrollController.dispose();
    super.dispose();
  }

  void _onCurrenciesScroll() {
    final bloc = context.read<PaginatedApiBloc<Currency>>();
    final state = bloc.state;
    if (state is! ApiLoaded<Currency> ||
        !state.hasNext ||
        state.isLoadingMore) {
      return;
    }
    final pos = _currenciesScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 50) {
      bloc.add(const ApiLoadMoreRequested());
    }
  }

  void _onTransactionsScroll() {
    final bloc = context.read<CursorPaginatedApiBloc<Transaction>>();
    final state = bloc.state;
    if (state is! ApiLoaded<Transaction> ||
        !state.hasNext ||
        state.isLoadingMore) {
      return;
    }
    final pos = _transactionsScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 100) {
      bloc.add(const ApiLoadMoreRequested());
    }
  }

  String get _transactionsTitle {
    if (_selectedCurrencies.isEmpty) {
      return 'All Transactions';
    }
    return '${_selectedCurrencies.join(' & ')} Transactions';
  }

  String _transactionIcon(Transaction t) {
    final type = t.type.toUpperCase();
    if (type == 'DEPOSIT') return TrydosWalletAssets.cashDeposit;
    if (type == 'WITHDRAWAL') return TrydosWalletAssets.cashWithdrawal;
    if (type.contains('REFUND')) return TrydosWalletAssets.refundOrder;
    if (type.contains('ORDER') || type.contains('INVOICE')) {
      return TrydosWalletAssets.orderInvoice;
    }
    return TrydosWalletAssets.cashDeposit;
  }

  String _transactionDirectionIcon(Transaction t) =>
      t.isDeposit ? TrydosWalletAssets.downArrow : TrydosWalletAssets.upArrow;

  String _formatTransactionDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(iso);
      if (dt == null) return iso;
      return '${dt.day}.${dt.month} | ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  String _formatAmount(Transaction t) {
    final amt = t.amount;
    final prefix = t.isDeposit ? '' : '-';
    final fmt = amt.abs().toStringAsFixed(
      amt.truncateToDouble() == amt ? 0 : 2,
    );
    return '$prefix$fmt ${t.assetSymbol}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WalletHeader(),
        const Padding(
          padding: EdgeInsets.only(top: 5, left: 24, right: 24),
          child: Divider(color: Color(0xffD3D3D3)),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24, right: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Total Balance',
                style: TrydosWalletStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff1D1D1D),
                ),
              ),
              BlocBuilder<PaginatedApiBloc<Currency>, ApiState<Currency>>(
                buildWhen: (prev, curr) =>
                    curr is ApiLoading<Currency> ||
                    curr is ApiLoaded<Currency> ||
                    curr is ApiError<Currency>,
                builder: (context, state) {
                  final isLoading = state is ApiLoading<Currency>;
                  return TextButton.icon(
                    onPressed: isLoading
                        ? null
                        : () => context
                            .read<PaginatedApiBloc<Currency>>()
                            .add(const ApiRefreshRequested()),
                    icon: SvgPicture.asset(
                      TrydosWalletAssets.addCurrency,
                      package: TrydosWalletStyles.packageName,
                    ),
                    label: Text(
                      'Add Currency',
                      style: TrydosWalletStyles.bodySmall.copyWith(
                        color: const Color(0xFF388CFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: BlocBuilder<BalancesBloc, BalancesState>(
            buildWhen: (prev, curr) =>
                prev.balances != curr.balances ||
                prev.loadingIds != curr.loadingIds,
            builder: (context, balancesState) {
              return BlocBuilder<PaginatedApiBloc<Currency>,
                  ApiState<Currency>>(
                builder: (context, state) {
                  if (state is ApiInitial<Currency> ||
                      state is ApiLoading<Currency>) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ApiError<Currency>) {
                    return Center(
                      child: TextButton(
                        onPressed: () => context
                            .read<PaginatedApiBloc<Currency>>()
                            .add(const ApiRefreshRequested()),
                        child: const Text('Retry'),
                      ),
                    );
                  }
                  final loadedState =
                      state is ApiLoaded<Currency> ? state : null;
                  final currencies = loadedState?.items ?? <Currency>[];
                  final hasNext = loadedState?.hasNext ?? false;
                  final isLoadingMore = loadedState?.isLoadingMore ?? false;

                  return ListView.builder(
                    controller: _currenciesScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: currencies.length + (hasNext ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == currencies.length) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: SizedBox(
                            width: 40,
                            child: isLoadingMore
                                ? const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      }
                      final currency = currencies[index];
                      final balance = balancesState.balance(currency.id);
                      final isLoadingBalance =
                          balancesState.isLoading(currency.id);
                      final amountStr = balance != null
                          ? balance.available.toStringAsFixed(
                              balance.available.truncateToDouble() ==
                                      balance.available
                                  ? 0
                                  : 2,
                            )
                          : '0';
                      return Padding(
                        padding: EdgeInsets.only(left: index > 0 ? 5 : 0),
                        child: BalanceCard(
                          symbolImageUrl: currency.symbolImageUrl,
                          symbol: currency.symbol,
                          currencyName: currency.displayName.isNotEmpty
                              ? currency.displayName
                              : currency.name,
                          amount: amountStr,
                          currencyCode: currency.symbol,
                          color: _selectedCurrencies.contains(currency.symbol)
                              ? const Color(0xff315391)
                              : const Color(0xFF3C3C3C),
                          isSelected:
                              _selectedCurrencies.contains(currency.symbol),
                          isLoadingBalance: isLoadingBalance,
                          onTap: () {
                            context
                                .read<BalancesBloc>()
                                .add(BalanceLoadRequested(currency.id));
                            setState(() {
                              final code = currency.symbol;
                              if (_selectedCurrencies.contains(code)) {
                                _selectedCurrencies.remove(code);
                              } else {
                                _selectedCurrencies.add(code);
                              }
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _transactionsTitle,
            style: TrydosWalletStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xff1D1D1D),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: BlocBuilder<
              CursorPaginatedApiBloc<Transaction>,
              ApiState<Transaction>>(
            builder: (context, state) {
              if (state is ApiInitial<Transaction> ||
                  state is ApiLoading<Transaction>) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ApiError<Transaction>) {
                return Center(
                  child: TextButton(
                    onPressed: () => context
                        .read<CursorPaginatedApiBloc<Transaction>>()
                        .add(const ApiRefreshRequested()),
                    child: const Text('Retry'),
                  ),
                );
              }
              final loadedState =
                  state is ApiLoaded<Transaction> ? state : null;
              final transactions = loadedState?.items ?? <Transaction>[];
              final hasNext = loadedState?.hasNext ?? false;
              final isLoadingMore = loadedState?.isLoadingMore ?? false;

              return ListView.builder(
                controller: _transactionsScrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: transactions.length + (hasNext ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == transactions.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: isLoadingMore
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    );
                  }
                  final t = transactions[index];
                  return TransactionItem(
                    icon: _transactionIcon(t),
                    directionIcon: _transactionDirectionIcon(t),
                    title: t.title.isNotEmpty ? t.title : t.type,
                    subtitle: _formatTransactionDate(t.createdAt),
                    amount: _formatAmount(t),
                    status: '',
                    amountColor: const Color(0xff1D1D1D),
                    titleColor: const Color(0xff1D1D1D),
                    statusColor: const Color(0xff1D1D1D),
                    subtitleColor: const Color(0xff8D8D8D),
                    isSelected: _selectedTransactionIndex == index,
                    onTap: () {
                      setState(() => _selectedTransactionIndex = index);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
