/// نموذج طلب الدفع.
class PaymentRequest {
  const PaymentRequest({
    required this.accountNumber,
    required this.assetType,
    required this.assetSymbol,
    required this.amount,
    required this.purposeId,
    this.note,
    required this.reference,
    this.expiryMinutes,
    required this.isPermanent,
    required this.idempotencyKey,
  });

  final String accountNumber;
  final String assetType;
  final String assetSymbol;
  final double amount;
  final String purposeId;
  final String? note;
  final String reference;
  final int? expiryMinutes;
  final bool isPermanent;
  final String idempotencyKey;

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      accountNumber: json['accountNumber'] as String,
      assetType: json['assetType'] as String,
      assetSymbol: json['assetSymbol'] as String,
      amount: (json['amount'] as num).toDouble(),
      purposeId: json['purposeId'] as String,
      note: json['note'] as String?,
      reference: json['reference'] as String,
      expiryMinutes: json['expiryMinutes'] as int?,
      isPermanent: json['isPermanent'] as bool? ?? false,
      idempotencyKey: json['idempotencyKey'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'accountNumber': accountNumber,
    'assetType': assetType,
    'assetSymbol': assetSymbol,
    'amount': amount,
    'purposeId': purposeId,
    'note': note,
    'reference': reference,
    'expiryMinutes': expiryMinutes,
    'isPermanent': isPermanent,
    'idempotencyKey': idempotencyKey,
  };
}
