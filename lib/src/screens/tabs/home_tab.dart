import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
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
  bool _hideBalance = false;
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
    if (pos.userScrollDirection != ScrollDirection.reverse) {
      return;
    }
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
    if (t.isAccountTransfer) {
      return t.isDeposit
          ? TrydosWalletAssets.depositReceive
          : TrydosWalletAssets.depositSend;
    }
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

  String _monthLabel(String languageCode, int month) {
    const monthKeys = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];
    return AppStrings.get(languageCode, monthKeys[month - 1]);
  }

  String _formatTransactionDate(String languageCode, String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(iso);
      if (dt == null) return iso;
      return '${dt.day}.${_monthLabel(languageCode, dt.month)}';
    } catch (_) {
      return iso;
    }
  }

  String _transactionTitle(String languageCode, Transaction t) {
    if (t.isAccountTransfer) {
      return t.isDeposit
          ? AppStrings.get(languageCode, 'receive_label').replaceAll('/', '|')
          : AppStrings.get(languageCode, 'transfer_send').replaceAll('/', '|');
    }
    return t.title.isNotEmpty ? t.title : t.type;
  }

  String _transactionSubtitle(String languageCode, Transaction t) {
    final date = _formatTransactionDate(languageCode, t.createdAt);
    if (t.isAccountTransfer) {
      final party = t.isOutgoing ? t.receiverAccount : t.senderAccount;
      final details = <String>[
        if (date.isNotEmpty) date,
        if (party.accountNumber.isNotEmpty) party.accountNumber,
        if (party.name.isNotEmpty) party.name,
      ];
      return details.join(' | ');
    }
    return date;
  }

  InlineSpan _transactionSubtitleSpan(
    BuildContext context,
    String languageCode,
    Transaction t,
    Color subtitleColor,
  ) {
    final date = _formatTransactionDate(languageCode, t.createdAt);
    final lightStyle = context.textTheme.bodyMedium?.lq.copyWith(
      color: subtitleColor,
      fontSize: 11.sp,
    );
    final regularStyle = context.textTheme.bodyMedium?.rq.copyWith(
      color: subtitleColor,
      fontSize: 11.sp,
    );

    if (!t.isAccountTransfer) {
      return TextSpan(text: date, style: lightStyle);
    }

    final party = t.isOutgoing ? t.receiverAccount : t.senderAccount;
    final children = <InlineSpan>[];

    void addSeparator() {
      if (children.isNotEmpty) {
        children.add(TextSpan(text: ' | ', style: regularStyle));
      }
    }

    if (date.isNotEmpty) {
      children.add(TextSpan(text: date, style: lightStyle));
    }
    if (party.accountNumber.isNotEmpty) {
      addSeparator();
      children.add(TextSpan(text: party.accountNumber, style: regularStyle));
    }
    if (party.name.isNotEmpty) {
      addSeparator();
      children.add(TextSpan(text: party.name, style: regularStyle));
    }

    return TextSpan(children: children, style: lightStyle);
  }

  String _transactionStatus(String languageCode, Transaction t) {
    final status = t.status.toUpperCase();
    if (status == 'COMPLETED') {
      return AppStrings.get(languageCode, 'success');
    }
    if (status == 'FAILED') {
      return AppStrings.get(languageCode, 'failed');
    }
    if (status == 'PENDING') {
      return AppStrings.get(languageCode, 'pending');
    }
    return t.status;
  }

  String _formatAmount(Transaction t) {
    final amt = t.amount;
    final prefix = t.isDeposit ? '' : '-';
    final fmt = amt.abs().toStringAsFixed(
      amt.truncateToDouble() == amt ? 0 : 2,
    );
    return '$prefix$fmt ';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        final transactions = state.transactions;
        final isLoadingMore =
            state.transactionsStatus == WalletStatus.loading &&
            transactions.isNotEmpty;

        return Directionality(
          textDirection: state.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<WalletBloc>().add(const WalletRefreshAllRequested());
            },
            child: SizedBox(
              height: 1.sh,
              width: 1.sw,
              child: Column(
                children: [
                  SizedBox(
                    height: 240.h,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const WalletHeader(),
                        Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: 24.w,
                            end: 24.w,
                          ),
                          child: Divider(color: Color(0xffD3D3D3)),
                        ),
                        (_selectedCurrencies.isNotEmpty)
                            ? Padding(
                                padding: EdgeInsetsDirectional.only(
                                  start: 24.w,
                                  end: 12.w,
                                  top: 6.h,
                                  bottom: 12.h,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      AppStrings.get(
                                        state.languageCode,
                                        'your_total_balance_of',
                                      ).replaceAll(
                                        '{currency}',
                                        _selectedCurrencies[0],
                                      ),
                                      style: context.textTheme.bodyMedium?.rq
                                          .copyWith(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11.sp,
                                            color: const Color(0xff1D1D1D),
                                          ),
                                    ),
                                    SizedBox(width: 10.w),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _hideBalance = !_hideBalance;
                                        });
                                      },
                                      child: SizedBox(
                                        height: 15.h,

                                        child: SvgPicture.asset(
                                          TrydosWalletAssets.hide,
                                          package:
                                              TrydosWalletStyles.packageName,
                                          colorFilter: ColorFilter.mode(
                                            _hideBalance
                                                ? const Color(0xff1D1D1D)
                                                : const Color(0xff8D8D8D),
                                            BlendMode.srcIn,
                                          ),
                                          height: 14.h,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),

                                    SvgPicture.asset(
                                      TrydosWalletAssets.addAccount,
                                      package: TrydosWalletStyles.packageName,
                                      height: 14.h,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      AppStrings.get(
                                        state.languageCode,
                                        'add_account_of',
                                      ).replaceAll(
                                        '{currency}',
                                        _selectedCurrencies[0],
                                      ),
                                      style: context.textTheme.bodyMedium?.rq
                                          .copyWith(
                                            color: const Color(0xFF388CFF),

                                            fontSize: 11.sp,
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : Padding(
                                padding: EdgeInsetsDirectional.only(
                                  start: 24.w,
                                  end: 12.w,
                                  top: 6.h,
                                  bottom: 12.h,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      AppStrings.get(
                                        state.languageCode,
                                        'your_total_balance',
                                      ),
                                      style: context.textTheme.bodyMedium?.rq
                                          .copyWith(
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xff1D1D1D),
                                          ),
                                    ),
                                    SizedBox(width: 8.w),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _hideBalance = !_hideBalance;
                                        });
                                      },
                                      child: SizedBox(
                                        height: 15.h,

                                        child: SvgPicture.asset(
                                          TrydosWalletAssets.hide,
                                          package:
                                              TrydosWalletStyles.packageName,
                                          colorFilter: ColorFilter.mode(
                                            _hideBalance
                                                ? Colors.black
                                                : const Color(0xff8D8D8D),
                                            BlendMode.srcIn,
                                          ),
                                          height: 14.h,
                                        ),
                                      ),
                                    ),
                                    Spacer(),

                                    SvgPicture.asset(
                                      TrydosWalletAssets.addCurrency,
                                      package: TrydosWalletStyles.packageName,
                                      height: 14.h,
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      AppStrings.get(
                                        state.languageCode,
                                        'add_currency',
                                      ),
                                      style: context.textTheme.bodyMedium?.rq
                                          .copyWith(
                                            color: const Color(0xFF388CFF),

                                            fontSize: 11.sp,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                        SizedBox(
                          height: 120.h,
                          width: 200.w,
                          child: Builder(
                            builder: (context) {
                              if (state.currenciesStatus ==
                                      WalletStatus.loading &&
                                  state.currencies.isEmpty) {
                                return const _CurrencyCardsShimmer();
                              }
                              if (state.currenciesStatus ==
                                      WalletStatus.failure &&
                                  state.currencies.isEmpty) {
                                return Center(
                                  child: TextButton(
                                    onPressed: () =>
                                        context.read<WalletBloc>().add(
                                          const WalletCurrenciesLoadRequested(),
                                        ),
                                    child: Text(
                                      AppStrings.get(
                                        state.languageCode,
                                        'retry',
                                      ),
                                      style: context.textTheme.bodyMedium?.rq
                                          .copyWith(
                                            color: const Color(0xFF388CFF),
                                            fontSize: 15.sp,
                                          ),
                                    ),
                                  ),
                                );
                              }

                              final currencies = state.currencies;
                              final hasNextCurrencies = state.currenciesHasNext;
                              final isLoadingMoreCurrencies =
                                  state.currenciesStatus ==
                                      WalletStatus.loading &&
                                  currencies.isNotEmpty;

                              if (_selectedCurrencies.isNotEmpty) {
                                final currency = currencies.firstWhere(
                                  (element) => _selectedCurrencies.contains(
                                    element.symbol,
                                  ),
                                  orElse: () => currencies.first,
                                );
                                final balance = state.balances[currency.id];
                                final isLoadingBalance = state.loadingBalanceIds
                                    .contains(currency.id);
                                final amountStr = _hideBalance
                                    ? '*****'
                                    : (balance != null
                                          ? balance.available.toStringAsFixed(
                                              balance.available
                                                          .truncateToDouble() ==
                                                      balance.available
                                                  ? 0
                                                  : 2,
                                            )
                                          : '0');

                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                  ),
                                  child: BalanceCard(
                                    symbolImageUrl: currency.symbolImageUrl,
                                    symbol: currency.symbol,
                                    currencyName: currency.localizedName(
                                      state.languageCode,
                                    ),
                                    amount: amountStr,
                                    currencyCode: currency.symbol,
                                    color: const Color(0xFF404040),
                                    isSelected: true,
                                    isLoadingBalance: isLoadingBalance,
                                    onTap: () {
                                      if (_selectedCurrencies.contains(
                                        currency.symbol,
                                      )) {
                                        context.read<WalletBloc>().add(
                                          BalanceCardIsSelected(
                                            isSelected: false,
                                            assetId: currency.id,
                                            assetSymbol: currency.symbol,
                                            assetType: currency.assetType,
                                          ),
                                        );
                                      } else {
                                        context.read<WalletBloc>().add(
                                          BalanceCardIsSelected(
                                            isSelected: true,
                                            assetId: currency.id,
                                            assetSymbol: currency.symbol,
                                            assetType: currency.assetType,
                                          ),
                                        );
                                      }
                                      setState(() {
                                        final code = currency.symbol;
                                        if (_selectedCurrencies.contains(
                                          code,
                                        )) {
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
                                padding: EdgeInsets.symmetric(horizontal: 12.w),
                                itemCount:
                                    currencies.length +
                                    (hasNextCurrencies ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == currencies.length) {
                                    return Padding(
                                      padding: EdgeInsetsDirectional.only(
                                        start: 8.w,
                                      ),
                                      child: SizedBox(
                                        width: 40.w,
                                        child: isLoadingMoreCurrencies
                                            ? Center(
                                                child: SizedBox(
                                                  width: 24.w,
                                                  height: 24.h,
                                                  child:
                                                      CircularProgressIndicator(
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
                                  final isLoadingBalance = state
                                      .loadingBalanceIds
                                      .contains(currency.id);
                                  final amountStr = _hideBalance
                                      ? '*****'
                                      : (balance != null
                                            ? balance.available.toStringAsFixed(
                                                balance.available
                                                            .truncateToDouble() ==
                                                        balance.available
                                                    ? 0
                                                    : 2,
                                              )
                                            : '0');

                                  return Padding(
                                    padding: EdgeInsetsDirectional.only(
                                      start: index > 0 ? 5.w : 0,
                                    ),
                                    child: BalanceCard(
                                      symbolImageUrl: currency.symbolImageUrl,
                                      symbol: currency.symbol,
                                      currencyName: currency.localizedName(
                                        state.languageCode,
                                      ),
                                      amount: amountStr,
                                      currencyCode: currency.symbol,
                                      color:
                                          _selectedCurrencies.contains(
                                            currency.symbol,
                                          )
                                          ? const Color(0xff315391)
                                          : const Color(0xFF404040),
                                      isSelected: _selectedCurrencies.contains(
                                        currency.symbol,
                                      ),
                                      isLoadingBalance: isLoadingBalance,
                                      onTap: () {
                                        if (_selectedCurrencies.contains(
                                          currency.symbol,
                                        )) {
                                          context.read<WalletBloc>().add(
                                            BalanceCardIsSelected(
                                              isSelected: false,
                                              assetId: currency.id,
                                              assetSymbol: currency.symbol,
                                              assetType: currency.assetType,
                                            ),
                                          );
                                        } else {
                                          context.read<WalletBloc>().add(
                                            BalanceCardIsSelected(
                                              isSelected: true,
                                              assetId: currency.id,
                                              assetSymbol: currency.symbol,
                                              assetType: currency.assetType,
                                            ),
                                          );
                                        }
                                        setState(() {
                                          final code = currency.symbol;
                                          if (_selectedCurrencies.contains(
                                            code,
                                          )) {
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
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,

                      children: [
                        SizedBox(height: 18.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: Text(
                                _getTransactionsTitle(state.languageCode),
                                style: context.textTheme.bodyMedium?.rq
                                    .copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11.sp,
                                      color: const Color(0xff1D1D1D),
                                    ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        if (state.transactionsStatus == WalletStatus.loading &&
                            state.transactions.isEmpty)
                          const _TransactionsShimmerList()
                        else if (state.transactionsStatus ==
                                WalletStatus.failure &&
                            state.transactions.isEmpty)
                          Center(
                            child: TextButton(
                              onPressed: () => context.read<WalletBloc>().add(
                                const WalletTransactionsLoadRequested(),
                              ),
                              child: Text(
                                AppStrings.get(state.languageCode, 'retry'),
                                style: context.textTheme.bodyMedium?.rq
                                    .copyWith(
                                      color: const Color(0xFF388CFF),
                                      fontSize: 15.sp,
                                    ),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              controller: _transactionsScrollController,
                              primary: false,
                              physics: const ClampingScrollPhysics(),
                              itemCount:
                                  transactions.length + (isLoadingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == transactions.length) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16.h,
                                    ),
                                    child: Center(
                                      child: isLoadingMore
                                          ? SizedBox(
                                              width: 24.w,
                                              height: 24.h,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  );
                                }

                                final transaction = transactions[index];
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                  ),
                                  child: TransactionItem(
                                    icon: _transactionIcon(transaction),
                                    directionIcon: _transactionDirectionIcon(
                                      transaction,
                                    ),
                                    title: _transactionTitle(
                                      state.languageCode,
                                      transaction,
                                    ),
                                    subtitle: _transactionSubtitle(
                                      state.languageCode,
                                      transaction,
                                    ),
                                    subtitleSpan: _transactionSubtitleSpan(
                                      context,
                                      state.languageCode,
                                      transaction,
                                      const Color(0xff8D8D8D),
                                    ),
                                    symbol: transaction.assetSymbol,
                                    amount: _formatAmount(transaction),
                                    status: _transactionStatus(
                                      state.languageCode,
                                      transaction,
                                    ),
                                    amountColor: const Color(0xff1D1D1D),
                                    titleColor: const Color(0xff1D1D1D),
                                    statusColor: const Color(0xff8D8D8D),
                                    subtitleColor: const Color(0xff8D8D8D),
                                    isSelected:
                                        _selectedTransactionIndex == index,
                                    onTap: () {
                                      setState(
                                        () => _selectedTransactionIndex = index,
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
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

class _CurrencyCardsShimmer extends StatelessWidget {
  const _CurrencyCardsShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        itemCount: 3,
        separatorBuilder: (_, __) => SizedBox(width: 5.w),
        itemBuilder: (_, __) => Container(
          width: 200.w,
          height: 120.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }
}

class _TransactionsShimmerList extends StatelessWidget {
  const _TransactionsShimmerList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE8E8E8),
        highlightColor: const Color(0xFFF5F5F5),
        child: Column(
          children: List.generate(5, (index) {
            return Container(
              margin: EdgeInsets.only(bottom: index == 4 ? 0 : 5.h),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15.r),
              ),
            );
          }),
        ),
      ),
    );
  }
}
