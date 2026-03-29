/// نموذج بيانات QR في الاستجابة.
class QrData {
  const QrData({
    required this.type,
    required this.code,
    required this.amount,
    required this.assetSymbol,
    required this.assetType,
    required this.requesterAccount,
  });

  final String type;
  final String code;
  final double amount;
  final String assetSymbol;
  final String assetType;
  final String requesterAccount;

  factory QrData.fromJson(Map<String, dynamic> json) {
    return QrData(
      type: (json['type'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      assetSymbol: (json['assetSymbol'] ?? '').toString(),
      assetType: (json['assetType'] ?? '').toString(),
      requesterAccount: (json['requesterAccount'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'code': code,
    'amount': amount,
    'assetSymbol': assetSymbol,
    'assetType': assetType,
    'requesterAccount': requesterAccount,
  };
}

/// نموذج استجابة طلب الدفع.
class PaymentRequestResponse {
  const PaymentRequestResponse({
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
    required this.qrData,
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
  final QrData qrData;

  factory PaymentRequestResponse.fromJson(Map<String, dynamic> json) {
    final rawQr = json['qrData'];
    final qrData = rawQr is Map<String, dynamic>
        ? QrData.fromJson(rawQr)
        : QrData(
            type: 'PAYMENT_REQUEST',
            code: (json['requestCode'] ?? '').toString(),
            amount: (json['amount'] as num?)?.toDouble() ?? 0,
            assetSymbol: (json['assetSymbol'] ?? '').toString(),
            assetType: (json['assetType'] ?? '').toString(),
            requesterAccount: (json['requesterAccountNumber'] ?? '').toString(),
          );

    return PaymentRequestResponse(
      id: json['id'] as String,
      requesterId: json['requesterId'] as String,
      requesterAccountNumber: json['requesterAccountNumber'] as String,
      requesterAccountId: json['requesterAccountId'] as String,
      payerId: json['payerId'],
      payerAccountId: json['payerAccountId'],
      assetType: json['assetType'] as String,
      assetId: json['assetId'] as String,
      assetSymbol: json['assetSymbol'] as String,
      amount: (json['amount'] as num).toDouble(),
      purposeId: json['purposeId'] as String,
      note: json['note'],
      reference: json['reference'],
      requestCode: json['requestCode'] as String,
      expiresAt: json['expiresAt'],
      isPermanent: json['isPermanent'] as bool? ?? false,
      status: json['status'] as String,
      financialLedgerInId: json['financialLedgerInId'],
      accountTransferId: json['accountTransferId'],
      journalEntryId: json['journalEntryId'],
      fulfilledAt: json['fulfilledAt'],
      cancellationReason: json['cancellationReason'],
      cancelledAt: json['cancelledAt'],
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      qrData: qrData,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'requesterId': requesterId,
    'requesterAccountNumber': requesterAccountNumber,
    'requesterAccountId': requesterAccountId,
    'payerId': payerId,
    'payerAccountId': payerAccountId,
    'assetType': assetType,
    'assetId': assetId,
    'assetSymbol': assetSymbol,
    'amount': amount,
    'purposeId': purposeId,
    'note': note,
    'reference': reference,
    'requestCode': requestCode,
    'expiresAt': expiresAt,
    'isPermanent': isPermanent,
    'status': status,
    'financialLedgerInId': financialLedgerInId,
    'accountTransferId': accountTransferId,
    'journalEntryId': journalEntryId,
    'fulfilledAt': fulfilledAt,
    'cancellationReason': cancellationReason,
    'cancelledAt': cancelledAt,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'qrData': qrData.toJson(),
  };
}
