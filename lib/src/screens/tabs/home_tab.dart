import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

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
    final bloc = context.read<WalletBloc>();
    final state = bloc.state;
    if (state.currenciesStatus == WalletStatus.loading ||
        !state.currenciesHasNext) {
      return;
    }
    final pos = _currenciesScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 50) {
      bloc.add(const WalletCurrenciesLoadMoreRequested());
    }
  }

  void _onTransactionsScroll() {
    final bloc = context.read<WalletBloc>();
    final state = bloc.state;
    if (state.transactionsStatus == WalletStatus.loading ||
        !state.transactionsHasNext) {
      return;
    }
    final pos = _transactionsScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 100) {
      bloc.add(const WalletTransactionsLoadMoreRequested());
    }
  }

  String _getTransactionsTitle(String languageCode) {
    if (_selectedCurrencies.isEmpty) {
      return AppStrings.get(languageCode, 'all_transactions');
    }
    return '${AppStrings.get(languageCode, 'transaction_history')} ${_selectedCurrencies.join(' & ')}';
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
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const WalletHeader(),
            const Padding(
              padding: EdgeInsets.only(top: 5, left: 24, right: 24),
              child: Divider(color: Color(0xffD3D3D3)),
            ),
            Padding(
              padding: state.isRtl
                  ? const EdgeInsets.only(left: 0, right: 24)
                  : const EdgeInsets.only(left: 24, right: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.get(state.languageCode, 'your_total_balance'),
                    style: TrydosWalletStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff1D1D1D),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: state.currenciesStatus == WalletStatus.loading
                        ? null
                        : () => context.read<WalletBloc>().add(
                            const WalletCurrenciesRefreshRequested(),
                          ),
                    icon: SvgPicture.asset(
                      TrydosWalletAssets.addCurrency,
                      package: TrydosWalletStyles.packageName,
                    ),
                    label: Text(
                      AppStrings.get(state.languageCode, 'add_currency'),
                      style: TrydosWalletStyles.bodySmall.copyWith(
                        color: const Color(0xFF388CFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: Builder(
                builder: (context) {
                  if (state.currenciesStatus == WalletStatus.loading &&
                      state.currencies.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.currenciesStatus == WalletStatus.failure &&
                      state.currencies.isEmpty) {
                    return Center(
                      child: TextButton(
                        onPressed: () => context.read<WalletBloc>().add(
                          const WalletCurrenciesLoadRequested(),
                        ),
                        child: Text(
                          AppStrings.get(state.languageCode, 'retry'),
                        ),
                      ),
                    );
                  }

                  final currencies = state.currencies;
                  final hasNext = state.currenciesHasNext;
                  final isLoadingMore =
                      state.currenciesStatus == WalletStatus.loading &&
                      currencies.isNotEmpty;

                  if (_selectedCurrencies.isNotEmpty) {
                    final currency = currencies.firstWhere(
                      (element) => _selectedCurrencies.contains(element.symbol),
                      orElse: () => currencies.first,
                    );
                    final balance = state.balances[currency.id];
                    final isLoadingBalance = state.loadingBalanceIds.contains(
                      currency.id,
                    );
                    final amountStr = balance != null
                        ? balance.available.toStringAsFixed(
                            balance.available.truncateToDouble() ==
                                    balance.available
                                ? 0
                                : 2,
                          )
                        : '0';

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: BalanceCard(
                        symbolImageUrl: currency.symbolImageUrl,
                        symbol: currency.symbol,
                        currencyName: currency.displayName.isNotEmpty
                            ? currency.displayName
                            : currency.name,
                        amount: amountStr,
                        currencyCode: currency.symbol,
                        color: const Color(0xFF404040),
                        isSelected: true,
                        isLoadingBalance: isLoadingBalance,
                        onTap: () {
                          context.read<WalletBloc>().add(
                            const BalanceCardIsSelected(isSelected: false),
                          );
                          context.read<WalletBloc>().add(
                            WalletBalanceLoadRequested(currency.id),
                          );
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
                  }

                  return ListView.builder(
                    controller: _currenciesScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: currencies.length + (hasNext ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == currencies.length) {
                        return Padding(
                          padding: state.isRtl
                              ? const EdgeInsets.only(right: 8)
                              : const EdgeInsets.only(left: 8),
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
                      final balance = state.balances[currency.id];
                      final isLoadingBalance = state.loadingBalanceIds.contains(
                        currency.id,
                      );
                      final amountStr = balance != null
                          ? balance.available.toStringAsFixed(
                              balance.available.truncateToDouble() ==
                                      balance.available
                                  ? 0
                                  : 2,
                            )
                          : '0';

                      return Padding(
                        padding: state.isRtl
                            ? EdgeInsets.only(right: index > 0 ? 5 : 0)
                            : EdgeInsets.only(left: index > 0 ? 5 : 0),
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
                              : const Color(0xFF404040),
                          isSelected: _selectedCurrencies.contains(
                            currency.symbol,
                          ),
                          isLoadingBalance: isLoadingBalance,
                          onTap: () {
                            context.read<WalletBloc>().add(
                              BalanceCardIsSelected(
                                isSelected: true,
                                assetId: currency.id,
                              ),
                            );
                            context.read<WalletBloc>().add(
                              WalletBalanceLoadRequested(currency.id),
                            );
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
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _getTransactionsTitle(state.languageCode),
                style: TrydosWalletStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff1D1D1D),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (state.transactionsStatus == WalletStatus.loading &&
                      state.transactions.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.transactionsStatus == WalletStatus.failure &&
                      state.transactions.isEmpty) {
                    return Center(
                      child: TextButton(
                        onPressed: () => context.read<WalletBloc>().add(
                          const WalletTransactionsLoadRequested(),
                        ),
                        child: Text(
                          AppStrings.get(state.languageCode, 'retry'),
                        ),
                      ),
                    );
                  }

                  final transactions = state.transactions;
                  final hasNext = state.transactionsHasNext;
                  final isLoadingMore =
                      state.transactionsStatus == WalletStatus.loading &&
                      transactions.isNotEmpty;

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
      },
    );
  }
}
