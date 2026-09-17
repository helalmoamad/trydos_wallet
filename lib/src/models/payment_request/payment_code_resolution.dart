import '../merchant_payment/merchant_payment_lookup.dart';
import 'payment_request_lookup_response.dart';

/// Which kind of request a scanned code turned out to be.
enum ResolvedCodeKind {
  /// A payment request from another wallet user. Paid with
  /// `POST /payment-requests/{id}/fulfill`.
  user,

  /// A merchant payment request. Paid with
  /// `POST /merchant/payments/{id}/pay`.
  merchant,

  /// The server answered with a `kind` this build does not know. Show a neutral
  /// "this code is not supported in this version" rather than guessing.
  unknown,
}

/// The result of `GET /payment-requests/lookup/{code}` — the one scanner
/// endpoint.
///
/// Codes carry their own namespace, so the server routes on the string alone
/// and reports which kind came back. The client reads [kind] and branches; it
/// never inspects the code to decide which endpoint to call.
///
/// ```dart
/// switch (resolution.kind) {
///   case ResolvedCodeKind.user:     // resolution.peer
///   case ResolvedCodeKind.merchant: // resolution.merchant
///   case ResolvedCodeKind.unknown:  // neutral message
/// }
/// ```
class PaymentCodeResolution {
  const PaymentCodeResolution({
    required this.kind,
    this.peer,
    this.merchant,
  });

  final ResolvedCodeKind kind;

  /// Populated when [kind] is [ResolvedCodeKind.user].
  final PaymentRequestLookupResponse? peer;

  /// Populated when [kind] is [ResolvedCodeKind.merchant].
  final MerchantPaymentLookup? merchant;

  bool get isUser => kind == ResolvedCodeKind.user && peer != null;
  bool get isMerchant => kind == ResolvedCodeKind.merchant && merchant != null;

  factory PaymentCodeResolution.fromJson(Map<String, dynamic> json) {
    final rawKind = (json['kind'] ?? '').toString().trim().toUpperCase();
    final merchantJson = json['merchant'];

    if (rawKind == 'MERCHANT' || (rawKind.isEmpty && merchantJson is Map)) {
      // The merchant-only resolver returns the same object at the top level,
      // so accept either shape.
      final payload = merchantJson is Map<String, dynamic>
          ? merchantJson
          : json;
      return PaymentCodeResolution(
        kind: ResolvedCodeKind.merchant,
        merchant: MerchantPaymentLookup.fromJson(payload),
      );
    }

    if (rawKind == 'USER' || rawKind.isEmpty) {
      // A response with no `kind` is a peer request from an older backend.
      final payload = json['user'] is Map<String, dynamic>
          ? json['user'] as Map<String, dynamic>
          : (json['paymentRequest'] is Map<String, dynamic>
                ? json['paymentRequest'] as Map<String, dynamic>
                : json);
      return PaymentCodeResolution(
        kind: ResolvedCodeKind.user,
        peer: PaymentRequestLookupResponse.fromJson(payload),
      );
    }

    return const PaymentCodeResolution(kind: ResolvedCodeKind.unknown);
  }
}

/// Parses the merchant-only resolver, which returns the merchant object at the
/// top level.
MerchantPaymentLookup merchantLookupFromJson(Map<String, dynamic> json) {
  final nested = json['merchant'];
  return MerchantPaymentLookup.fromJson(
    nested is Map<String, dynamic> ? nested : json,
  );
}
