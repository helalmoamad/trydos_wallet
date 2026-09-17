import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';

import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

/// The customer's merchant payments (`GET /merchant/payments/my`).
///
/// Its own section, separate from the wallet ledger: "what did I pay that shop,
/// and did any of it come back" is a different question from "what moved in my
/// wallet", and it is the one customers bring to support.
///
/// Refunds are shown honestly. When money came back, the paid and refunded
/// figures sit side by side rather than the row quietly showing a net number.
class MerchantPaymentsPage extends StatefulWidget {
  const MerchantPaymentsPage({super.key});

  @override
  State<MerchantPaymentsPage> createState() => _MerchantPaymentsPageState();
}

class _MerchantPaymentsPageState extends State<MerchantPaymentsPage> {
  final ScrollController _scrollController = ScrollController();
  bool _loadMoreQueued = false;

  static const Color _ink = Color(0xff1D1D1D);
  static const Color _muted = Color(0xff8D8D8D);
  static const Color _line = Color(0xffEDEDED);
  static const Color _refund = Color(0xffE65100);

  static const List<String> _monthKeys = [
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<WalletBloc>().add(
      const WalletMerchantPaymentsRequested(page: 0),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadMoreQueued) return;

    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 300) return;

    final state = context.read<WalletBloc>().state;
    if (!state.merchantPaymentsHasMore ||
        state.merchantPaymentsStatus == WalletStatus.loading) {
      return;
    }

    _loadMoreQueued = true;
    context.read<WalletBloc>().add(
      WalletMerchantPaymentsRequested(
        page: state.merchantPaymentsPage + 1,
        append: true,
      ),
    );
  }

  Future<void> _refresh() async {
    context.read<WalletBloc>().add(
      const WalletMerchantPaymentsRequested(page: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        if (state.merchantPaymentsStatus != WalletStatus.loading) {
          _loadMoreQueued = false;
        }

        final items = state.merchantPayments;
        final isFirstLoad =
            state.merchantPaymentsStatus == WalletStatus.loading &&
            items.isEmpty;

        return Directionality(
          textDirection: state.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(state),
                  Expanded(
                    child: isFirstLoad
                        ? const _MerchantPaymentsShimmer()
                        : _buildBody(state, items),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(WalletState state) {
    return SizedBox(
      height: 50.h,
      width: 1.sw,
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: SvgPicture.asset(
                TrydosWalletAssets.back,
                package: TrydosWalletStyles.packageName,
                height: 20.h,
                matchTextDirection: true,
              ),
            ),
          ),
          Expanded(
            child: Text(
              AppStrings.get(state.languageCode, 'merchant_payments_title'),
              style: context.textTheme.bodyMedium?.mq.copyWith(
                color: _ink,
                fontSize: 13.sp,
              ),
            ),
          ),
          SizedBox(width: 40.w),
        ],
      ),
    );
  }

  Widget _buildBody(WalletState state, List<MerchantPaymentHistoryItem> items) {
    if (items.isEmpty) {
      final failed = state.merchantPaymentsStatus == WalletStatus.failure;
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 120.h),
            Center(
              child: Text(
                failed
                    ? (state.merchantPaymentsErrorMessage ??
                          AppStrings.get(
                            state.languageCode,
                            'merchant_payments_load_failed',
                          ))
                    : AppStrings.get(
                        state.languageCode,
                        'merchant_payments_empty',
                      ),
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.rq.copyWith(
                  color: _muted,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final isLoadingMore =
        state.merchantPaymentsStatus == WalletStatus.loading && items.isNotEmpty;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        itemCount: items.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => Divider(height: 1, color: _line),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Center(
                child: SizedBox(
                  width: 24.w,
                  height: 24.h,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          return _buildItem(state, items[index]);
        },
      ),
    );
  }

  Widget _buildItem(WalletState state, MerchantPaymentHistoryItem item) {
    final lang = state.languageCode;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.merchantName,
                  style: context.textTheme.bodyMedium?.mq.copyWith(
                    color: _ink,
                    fontSize: 13.sp,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                // The decimal string exactly as the server sent it.
                '${item.amount} ${item.assetSymbol}',
                textDirection: TextDirection.ltr,
                style: context.textTheme.bodyMedium?.mq.copyWith(
                  color: _ink,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.orderRef.isEmpty ? item.receiptNumber : item.orderRef,
                  textDirection: TextDirection.ltr,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.rq.copyWith(
                    color: _muted,
                    fontSize: 11.sp,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                AppStrings.get(lang, item.status.labelKey),
                style: context.textTheme.bodyMedium?.rq.copyWith(
                  color: item.hasRefund ? _refund : _muted,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
          if (item.hasRefund) ...[
            SizedBox(height: 6.h),
            // Both figures, side by side: "100.00 paid, 25.00 refunded" is the
            // question customers ask support about, so answer it on the row.
            Row(
              children: [
                Text(
                  '${AppStrings.get(lang, 'merchant_paid_amount')}: '
                  '${item.amount} ${item.assetSymbol}',
                  style: context.textTheme.bodyMedium?.rq.copyWith(
                    color: _muted,
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  '${AppStrings.get(lang, 'merchant_refunded_amount')}: '
                  '${item.refundedAmount} ${item.assetSymbol}',
                  style: context.textTheme.bodyMedium?.rq.copyWith(
                    color: _refund,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ],
          if (item.paidAt != null) ...[
            SizedBox(height: 4.h),
            Text(
              _formatDate(item.paidAt!, lang),
              style: context.textTheme.bodyMedium?.rq.copyWith(
                color: _muted,
                fontSize: 10.sp,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime value, String languageCode) {
    final dt = value.toLocal();
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${AppStrings.get(languageCode, _monthKeys[dt.month - 1])} | '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _MerchantPaymentsShimmer extends StatelessWidget {
  const _MerchantPaymentsShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF5F5F5),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        itemCount: 6,
        separatorBuilder: (_, _) => SizedBox(height: 12.h),
        itemBuilder: (_, _) => Container(
          height: 60.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }
}
