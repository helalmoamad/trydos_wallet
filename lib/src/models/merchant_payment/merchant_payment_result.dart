import 'merchant_payment_status.dart';

/// The response to `POST /merchant/payments/{id}/pay` — the receipt.
///
/// ```json
/// { "status": "PAID", "paymentRequestId": "66f1…", "orderRef": "ORD-10231",
///   "merchantName": "Al Salam Stores", "amount": "100.00", "assetSymbol": "USD",
///   "receiptNumber": "RDB-R-2026-000123", "paidAt": "2026-10-01T09:14:03.118Z",
///   "accountTransferId": "66f1c2d1…",
///   "successUrl": "https://shop.example.com/orders/10231/thanks" }
/// ```
///
/// Retrying a timed-out payment with the same idempotency key returns this same
/// object rather than charging the customer twice.
class MerchantPaymentResult {
  const MerchantPaymentResult({
    required this.status,
    required this.paymentRequestId,
    required this.orderRef,
    required this.merchantName,
    required this.amount,
    required this.assetSymbol,
    required this.receiptNumber,
    this.paidAt,
    this.accountTransferId,
    this.successUrl,
  });

  final MerchantPaymentStatus status;
  final String paymentRequestId;
  final String orderRef;
  final String merchantName;

  /// Decimal string. Display as received.
  final String amount;
  final String assetSymbol;
  final String receiptNumber;
  final DateTime? paidAt;
  final String? accountTransferId;

  /// "Return to the shop" — nothing more.
  ///
  /// Never present it as proof of payment and never require the customer to
  /// open it: the shop learns about the payment from the backend directly.
  final String? successUrl;

  /// Whether this response confirms the money moved.
  ///
  /// [MerchantPaymentStatus.processing] and [MerchantPaymentStatus.unknown] are
  /// deliberately not confirmations.
  bool get isPaid => status == MerchantPaymentStatus.paid;

  factory MerchantPaymentResult.fromJson(Map<String, dynamic> json) {
    String text(dynamic value) => value?.toString().trim() ?? '';
    String? optional(dynamic value) {
      final raw = text(value);
      return raw.isEmpty ? null : raw;
    }

    return MerchantPaymentResult(
      status: MerchantPaymentStatus.fromString(text(json['status'])),
      paymentRequestId: text(json['paymentRequestId'] ?? json['id']),
      orderRef: text(json['orderRef']),
      merchantName: text(json['merchantName']),
      amount: text(json['amount']).isEmpty ? '0' : text(json['amount']),
      assetSymbol: text(json['assetSymbol']).toUpperCase(),
      receiptNumber: text(json['receiptNumber']),
      paidAt: DateTime.tryParse(text(json['paidAt']))?.toLocal(),
      accountTransferId: optional(json['accountTransferId']),
      successUrl: optional(json['successUrl']),
    );
  }
}
