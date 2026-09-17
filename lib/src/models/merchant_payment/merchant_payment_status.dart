/// Status of a merchant payment request.
///
/// The list can grow on the server. An unrecognised value therefore maps to
/// [unknown] and renders as a neutral "processing" state — never as a crash,
/// and never as "paid". Only the server decides that a payment happened.
enum MerchantPaymentStatus {
  /// Awaiting payment. The only payable state; show the countdown.
  pending('PENDING'),

  /// Paid — a receipt is available. In a lookup this means somebody already
  /// paid this code, which may well have been another person.
  paid('PAID'),

  /// Expired. Not payable; suggest asking the shop for a new code.
  expired('EXPIRED'),

  /// Cancelled by the shop. Not payable.
  cancelled('CANCELLED'),

  /// Partially refunded. History only — show paid and refunded together.
  partiallyRefunded('PARTIALLY_REFUNDED'),

  /// Refunded. History only.
  refunded('REFUNDED'),

  /// Reserved for future payment channels. Treat as unpaid.
  failed('FAILED'),

  /// Reserved. Show a wait state, and never treat it as paid.
  processing('PROCESSING'),

  /// A status this build does not know about. Render neutrally.
  unknown('');

  const MerchantPaymentStatus(this.value);

  final String value;

  static MerchantPaymentStatus fromString(String? value) {
    final normalized = (value ?? '').trim().toUpperCase();
    if (normalized.isEmpty) return MerchantPaymentStatus.unknown;
    for (final status in MerchantPaymentStatus.values) {
      if (status.value == normalized) return status;
    }
    return MerchantPaymentStatus.unknown;
  }

  /// Whether this status alone would allow a payment.
  ///
  /// This is a client-side sanity check, not the decision: the lookup's own
  /// `payable` flag is authoritative and already accounts for everything the
  /// status cannot express.
  bool get isPayable => this == MerchantPaymentStatus.pending;

  /// Whether the money has definitively left the payer's wallet.
  ///
  /// [unknown], [processing] and [failed] are all false here on purpose: none
  /// of them is a confirmation.
  bool get isSettled =>
      this == MerchantPaymentStatus.paid ||
      this == MerchantPaymentStatus.refunded ||
      this == MerchantPaymentStatus.partiallyRefunded;

  /// Localization key for the label shown to the customer.
  String get labelKey {
    switch (this) {
      case MerchantPaymentStatus.pending:
        return 'merchant_status_pending';
      case MerchantPaymentStatus.paid:
        return 'merchant_status_paid';
      case MerchantPaymentStatus.expired:
        return 'merchant_status_expired';
      case MerchantPaymentStatus.cancelled:
        return 'merchant_status_cancelled';
      case MerchantPaymentStatus.partiallyRefunded:
        return 'merchant_status_partially_refunded';
      case MerchantPaymentStatus.refunded:
        return 'merchant_status_refunded';
      case MerchantPaymentStatus.failed:
        return 'merchant_status_failed';
      case MerchantPaymentStatus.processing:
      case MerchantPaymentStatus.unknown:
        return 'merchant_status_processing';
    }
  }
}
