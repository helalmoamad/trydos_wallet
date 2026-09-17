import 'merchant_localized_text.dart';
import 'merchant_payment_status.dart';

/// A resolved merchant payment request — the confirmation screen, as data.
///
/// ```json
/// { "id": "66f1c2a9e4b0a1d2c3b4a5f6", "status": "PENDING", "payable": true,
///   "merchantName": "Al Salam Stores", "orderRef": "ORD-10231",
///   "amount": "100.00", "feeAmount": "0.00",
///   "assetType": "CURRENCY", "assetSymbol": "USD",
///   "description": { "en": "Order #10231 — 2 items", "ar": "…" },
///   "expiresAt": "2026-10-01T09:44:00.000Z" }
/// ```
///
/// Every field on the payment screen comes from here and from nowhere else —
/// not from the QR, not from a query parameter, not from the shop's own page.
class MerchantPaymentLookup {
  const MerchantPaymentLookup({
    required this.id,
    required this.status,
    required this.payable,
    required this.merchantName,
    required this.orderRef,
    required this.amount,
    required this.feeAmount,
    required this.assetType,
    required this.assetSymbol,
    required this.description,
    this.expiresAt,
  });

  final String id;
  final MerchantPaymentStatus status;

  /// The server's verdict on whether this request can be paid right now.
  ///
  /// Authoritative: when it is false the request is already paid, expired or
  /// cancelled, whatever [status] happens to say.
  final bool payable;

  /// The shop asking for the money — the single most important element on the
  /// screen, and the customer's only defence against paying the wrong party.
  final String merchantName;

  final String orderRef;

  /// Decimal string, e.g. `"100.00"`. Display as received; compare only through
  /// `DecimalAmount`.
  final String amount;

  /// Decimal string, e.g. `"0.00"`.
  final String feeAmount;

  final String assetType;
  final String assetSymbol;
  final MerchantLocalizedText description;

  /// When the request stops being payable. Null means no expiry was set.
  final DateTime? expiresAt;

  bool get hasFee => feeAmount.trim().isNotEmpty && !_isZeroAmount(feeAmount);

  static bool _isZeroAmount(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty || int.tryParse(digits) == 0;
  }

  /// True once the countdown has run out locally.
  ///
  /// This only disables the button; it never decides the outcome. The screen
  /// still refreshes the lookup so the server has the last word.
  bool get isExpiredNow {
    final expiry = expiresAt;
    return expiry != null && !DateTime.now().isBefore(expiry);
  }

  factory MerchantPaymentLookup.fromJson(Map<String, dynamic> json) {
    String text(dynamic value) => value?.toString().trim() ?? '';

    String amountText(dynamic value) {
      // Amounts are decimal strings. A number here means an older or misbehaving
      // payload; keep the digits verbatim rather than routing them through a
      // double.
      final raw = value?.toString().trim() ?? '';
      return raw.isEmpty ? '0' : raw;
    }

    DateTime? date(dynamic value) {
      final raw = value?.toString().trim() ?? '';
      if (raw.isEmpty) return null;
      return DateTime.tryParse(raw)?.toLocal();
    }

    final status = MerchantPaymentStatus.fromString(text(json['status']));

    return MerchantPaymentLookup(
      id: text(json['id']),
      status: status,
      // Absent `payable` falls back to the status, so a trimmed payload cannot
      // silently make an unpayable request look payable.
      payable: json['payable'] is bool
          ? json['payable'] as bool
          : status.isPayable,
      merchantName: text(json['merchantName']),
      orderRef: text(json['orderRef']),
      amount: amountText(json['amount']),
      feeAmount: amountText(json['feeAmount']),
      assetType: text(json['assetType']).toUpperCase() == 'METAL'
          ? 'METAL'
          : 'CURRENCY',
      assetSymbol: text(json['assetSymbol']).toUpperCase(),
      description: MerchantLocalizedText.fromJson(json['description']),
      expiresAt: date(json['expiresAt']),
    );
  }
}
