import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

import 'transaction_details_page.dart';
import 'transaction_item.dart';

/// The transactions list shared by the Home tab and the Transactions tab:
/// section title, shimmer, retry, the rows themselves, and scroll pagination.
///
/// The two tabs read different lists off [WalletState] — the home list follows
/// the selected currency card, the Transactions tab never filters — so the list
/// and its paging state are passed in rather than read here.
class TransactionsList extends StatefulWidget {
  const TransactionsList({
    super.key,
    required this.title,
    required this.transactions,
    required this.status,
    required this.hasNext,
    required this.nextCursor,
    required this.languageCode,
    required this.onLoadMore,
    required this.onRetry,
    this.physics = const ClampingScrollPhysics(),
  });

  /// Heading shown above the list (e.g. "All transactions").
  final String title;
  final List<Transaction> transactions;
  final WalletStatus status;
  final bool hasNext;
  final String? nextCursor;
  final String languageCode;

  /// Dispatched when the user scrolls to the end and another page exists.
  final VoidCallback onLoadMore;

  /// Dispatched by the retry button shown when the first page failed.
  final VoidCallback onRetry;

  /// Pass [AlwaysScrollableScrollPhysics] where this list is the only
  /// scrollable under a [RefreshIndicator], or a list too short to scroll
  /// leaves the user with no way to pull for a refresh.
  final ScrollPhysics physics;

  @override
  State<TransactionsList> createState() => _TransactionsListState();
}

class _TransactionsListState extends State<TransactionsList> {
  int _selectedTransactionIndex = 0;
  bool _loadMoreQueued = false;
  int _lastPaginationTriggerMs = 0;
  String? _lastPaginationCursor;
  int _lastPaginationItemCount = -1;
  double _lastPaginationPixels = -1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant TransactionsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == WalletStatus.failure ||
        !widget.hasNext ||
        (widget.nextCursor?.isEmpty ?? true)) {
      _resetPaginationGuards();
      return;
    }
    if (_lastPaginationItemCount >= 0 &&
        widget.transactions.length > _lastPaginationItemCount) {
      _loadMoreQueued = false;
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _resetPaginationGuards() {
    _loadMoreQueued = false;
    _lastPaginationTriggerMs = 0;
    _lastPaginationCursor = null;
    _lastPaginationItemCount = -1;
    _lastPaginationPixels = -1;
  }

  bool get _canLoadMore =>
      widget.status != WalletStatus.loading &&
      widget.hasNext &&
      (widget.nextCursor?.isNotEmpty ?? false);

  void _onScroll() {
    if (!_scrollController.hasClients || !_canLoadMore) {
      return;
    }
    final pos = _scrollController.position;

    if (pos.userScrollDirection != ScrollDirection.reverse) {
      return;
    }
    if (pos.extentAfter > 120) {
      return;
    }

    final nextCursor = widget.nextCursor;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final isRepeatedEdgeTrigger =
        _lastPaginationCursor == nextCursor &&
        _lastPaginationItemCount == widget.transactions.length &&
        (pos.pixels - _lastPaginationPixels).abs() < 32;
    if (isRepeatedEdgeTrigger && nowMs - _lastPaginationTriggerMs < 350) {
      return;
    }

    _lastPaginationCursor = nextCursor;
    _lastPaginationItemCount = widget.transactions.length;
    _lastPaginationPixels = pos.pixels;
    _lastPaginationTriggerMs = nowMs;
    _queueLoadMore();
  }

  void _queueLoadMore() {
    if (_loadMoreQueued) {
      return;
    }
    _loadMoreQueued = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadMoreQueued = false;
      if (!mounted || !_canLoadMore) {
        return;
      }
      widget.onLoadMore();
    });
  }

  /// Open a view-only details sheet for the tapped transaction. Closes via the
  /// Done button, the Android back button, or tapping outside (modal default).
  void _openTransactionDetails(BuildContext context, Transaction transaction) {
    showWalletModal(
      context: context,
      builder: (modalContext, scrollController) => TransactionDetailsPage(
        transaction: transaction,
        onDone: () => Navigator.of(modalContext).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final disableOverscrollIndicator =
        TrydosWallet.config.disableWalletOverscrollIndicator;
    final transactions = widget.transactions;
    final isLoadingMore =
        widget.status == WalletStatus.loading && transactions.isNotEmpty;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Text(
                widget.title,
                style: context.textTheme.bodyMedium?.rq.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11.sp,
                  color: const Color(0xff1D1D1D),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (widget.status == WalletStatus.loading && transactions.isEmpty)
          const TransactionsShimmerList()
        else if (widget.status == WalletStatus.failure && transactions.isEmpty)
          Center(
            child: TextButton(
              onPressed: widget.onRetry,
              child: Text(
                AppStrings.get(widget.languageCode, 'retry'),
                style: context.textTheme.bodyMedium?.rq.copyWith(
                  color: const Color(0xFF388CFF),
                  fontSize: 15.sp,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: NotificationListener<OverscrollIndicatorNotification>(
              onNotification: (notification) {
                if (disableOverscrollIndicator) {
                  notification.disallowIndicator();
                }
                return false;
              },
              child: ListView.builder(
                controller: _scrollController,
                primary: false,
                physics: widget.physics,
                itemCount: transactions.length + (isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == transactions.length) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
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
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: TransactionItem(
                      icon: transactionIcon(transaction),
                      directionIcon: transactionDirectionIcon(transaction),
                      title: transactionTitle(
                        widget.languageCode,
                        transaction,
                      ),
                      subtitle: transactionSubtitle(
                        widget.languageCode,
                        transaction,
                      ),
                      subtitleSpan: transactionSubtitleSpan(
                        context,
                        widget.languageCode,
                        transaction,
                        const Color(0xff8D8D8D),
                      ),
                      symbol: transaction.assetSymbol,
                      amount: formatTransactionAmount(transaction),
                      status: transactionStatusLabel(
                        widget.languageCode,
                        transaction,
                      ),
                      amountColor: const Color(0xff1D1D1D),
                      titleColor: const Color(0xff1D1D1D),
                      statusColor: const Color(0xff8D8D8D),
                      subtitleColor: const Color(0xff8D8D8D),
                      isSelected: _selectedTransactionIndex == index,
                      onTap: () {
                        setState(() => _selectedTransactionIndex = index);
                        _openTransactionDetails(context, transaction);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

/// Placeholder rows shown while the first page of transactions loads.
class TransactionsShimmerList extends StatelessWidget {
  const TransactionsShimmerList({super.key});

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

/// Leading icon: the kind of movement this transaction is.
String transactionIcon(Transaction t) {
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

/// Arrow under the leading icon: money in or money out.
String transactionDirectionIcon(Transaction t) =>
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

String formatTransactionDate(String languageCode, String? iso) {
  if (iso == null || iso.isEmpty) return '';
  try {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return '${dt.day}.${_monthLabel(languageCode, dt.month)}';
  } catch (_) {
    return iso;
  }
}

String transactionTitle(String languageCode, Transaction t) {
  if (t.isAccountTransfer) {
    return t.isDeposit
        ? AppStrings.get(languageCode, 'receive_label').replaceAll('/', '|')
        : AppStrings.get(languageCode, 'transfer_send').replaceAll('/', '|');
  }
  return t.title.isNotEmpty ? t.title : t.type;
}

String transactionSubtitle(String languageCode, Transaction t) {
  final date = formatTransactionDate(languageCode, t.createdAt);
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

/// Same text as [transactionSubtitle], but with the account number pinned to
/// LTR so it does not reorder under an RTL locale.
InlineSpan transactionSubtitleSpan(
  BuildContext context,
  String languageCode,
  Transaction t,
  Color subtitleColor,
) {
  final date = formatTransactionDate(languageCode, t.createdAt);
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
    children.add(
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(party.accountNumber, style: regularStyle),
        ),
      ),
    );
  }
  if (party.name.isNotEmpty) {
    addSeparator();
    children.add(TextSpan(text: party.name, style: regularStyle));
  }

  return TextSpan(children: children, style: lightStyle);
}

String transactionStatusLabel(String languageCode, Transaction t) {
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

String formatTransactionAmount(Transaction t) {
  final amt = t.amount;
  final prefix = t.isDeposit ? '' : '-';
  final fmt = amt.abs().toStringAsFixed(amt.truncateToDouble() == amt ? 0 : 2);
  return '$prefix$fmt ';
}
