import 'merchant_payment_status.dart';

/// One row of `GET /merchant/payments/my`.
///
/// Refunds arrive here rather than as a separate event: a status change plus a
/// non-zero [refundedAmount]. Both figures are shown together, because
/// "100.00 paid, 25.00 refunded" is the question customers ask support about.
class MerchantPaymentHistoryItem {
  const MerchantPaymentHistoryItem({
    required this.id,
    required this.status,
    required this.merchantName,
    required this.orderRef,
    required this.amount,
    required this.refundedAmount,
    required this.assetSymbol,
    required this.receiptNumber,
    this.paidAt,
  });

  final String id;
  final MerchantPaymentStatus status;
  final String merchantName;
  final String orderRef;

  /// Decimal string. Display as received.
  final String amount;

  /// Decimal string; `"0.00"` when nothing was refunded.
  final String refundedAmount;

  final String assetSymbol;
  final String receiptNumber;
  final DateTime? paidAt;

  /// True when any money came back, whatever the status says.
  bool get hasRefund {
    final digits = refundedAmount.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isNotEmpty && int.tryParse(digits) != 0;
  }

  factory MerchantPaymentHistoryItem.fromJson(Map<String, dynamic> json) {
    String text(dynamic value) => value?.toString().trim() ?? '';

    return MerchantPaymentHistoryItem(
      id: text(json['id']),
      status: MerchantPaymentStatus.fromString(text(json['status'])),
      merchantName: text(json['merchantName']),
      orderRef: text(json['orderRef']),
      amount: text(json['amount']).isEmpty ? '0' : text(json['amount']),
      refundedAmount: text(json['refundedAmount']).isEmpty
          ? '0'
          : text(json['refundedAmount']),
      assetSymbol: text(json['assetSymbol']).toUpperCase(),
      receiptNumber: text(json['receiptNumber']),
      paidAt: DateTime.tryParse(text(json['paidAt']))?.toLocal(),
    );
  }
}

/// A page of merchant payment history.
class MerchantPaymentHistoryPage {
  const MerchantPaymentHistoryPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<MerchantPaymentHistoryItem> items;
  final int total;

  /// 0-indexed, as the API numbers pages.
  final int page;
  final int limit;

  /// Whether another page exists after this one.
  bool get hasMore => (page + 1) * limit < total;

  factory MerchantPaymentHistoryPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <MerchantPaymentHistoryItem>[];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is Map<String, dynamic>) {
          items.add(MerchantPaymentHistoryItem.fromJson(raw));
        }
      }
    }

    int number(dynamic value, int fallback) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return MerchantPaymentHistoryPage(
      items: items,
      total: number(json['total'], items.length),
      page: number(json['page'], 0),
      limit: number(json['limit'], items.isEmpty ? 20 : items.length),
    );
  }
}
