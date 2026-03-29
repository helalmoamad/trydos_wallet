class PaymentRequestFulfillResponse {
  const PaymentRequestFulfillResponse({
    required this.id,
    required this.requesterId,
    required this.requesterAccountNumber,
    required this.requesterAccountId,
    this.payerId,
    this.payerAccountId,
    required this.assetType,
    required this.assetId,
    required this.assetSymbol,
    required this.amount,
    required this.purposeId,
    this.note,
    this.reference,
    required this.requestCode,
    this.expiresAt,
    required this.isPermanent,
    required this.status,
    this.financialLedgerInId,
    this.accountTransferId,
    this.journalEntryId,
    this.fulfilledAt,
    this.cancellationReason,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String requesterId;
  final String requesterAccountNumber;
  final String requesterAccountId;
  final dynamic payerId;
  final dynamic payerAccountId;
  final String assetType;
  final String assetId;
  final String assetSymbol;
  final double amount;
  final String purposeId;
  final dynamic note;
  final dynamic reference;
  final String requestCode;
  final dynamic expiresAt;
  final bool isPermanent;
  final String status;
  final dynamic financialLedgerInId;
  final dynamic accountTransferId;
  final dynamic journalEntryId;
  final dynamic fulfilledAt;
  final dynamic cancellationReason;
  final dynamic cancelledAt;
  final String createdAt;
  final String updatedAt;

  factory PaymentRequestFulfillResponse.fromJson(Map<String, dynamic> json) {
    return PaymentRequestFulfillResponse(
      id: (json['id'] ?? '').toString(),
      requesterId: (json['requesterId'] ?? '').toString(),
      requesterAccountNumber: (json['requesterAccountNumber'] ?? '').toString(),
      requesterAccountId: (json['requesterAccountId'] ?? '').toString(),
      payerId: json['payerId'],
      payerAccountId: json['payerAccountId'],
      assetType: (json['assetType'] ?? '').toString(),
      assetId: (json['assetId'] ?? '').toString(),
      assetSymbol: (json['assetSymbol'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      purposeId: (json['purposeId'] ?? '').toString(),
      note: json['note'],
      reference: json['reference'],
      requestCode: (json['requestCode'] ?? '').toString(),
      expiresAt: json['expiresAt'],
      isPermanent: json['isPermanent'] as bool? ?? false,
      status: (json['status'] ?? '').toString(),
      financialLedgerInId: json['financialLedgerInId'],
      accountTransferId: json['accountTransferId'],
      journalEntryId: json['journalEntryId'],
      fulfilledAt: json['fulfilledAt'],
      cancellationReason: json['cancellationReason'],
      cancelledAt: json['cancelledAt'],
      createdAt: (json['createdAt'] ?? '').toString(),
      updatedAt: (json['updatedAt'] ?? '').toString(),
    );
  }
}
