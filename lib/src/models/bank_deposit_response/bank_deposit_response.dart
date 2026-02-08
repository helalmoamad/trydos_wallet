/// Bank deposit creation response.
class BankDepositResponse {
  const BankDepositResponse({
    required this.id,
    required this.amount,
    this.taxAmount,
    this.feeAmount,
    this.netAmount,
    this.transferImageUrl,
    this.transactionReference,
    this.status,
    this.rejectionReason,
    this.processedBy,
    this.processedAt,
    this.walletCredited,
    this.createdAt,
    this.updatedAt,
    // ignore: library_private_types_in_public_api
    this.bank,
    // ignore: library_private_types_in_public_api
    this.currency,
  });

  factory BankDepositResponse.fromJson(Map<String, dynamic> json) {
    return BankDepositResponse(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble(),
      feeAmount: (json['feeAmount'] as num?)?.toDouble(),
      netAmount: (json['netAmount'] as num?)?.toDouble(),
      transferImageUrl: json['transferImageUrl'] as String?,
      transactionReference: json['transactionReference'] as String?,
      status: json['status'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      processedBy: json['processedBy'] as String?,
      processedAt: json['processedAt'] as String?,
      walletCredited: json['walletCredited'] as bool?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      bank: json['bank'] != null
          ? _BankInfo.fromJson(json['bank'] as Map<String, dynamic>)
          : null,
      currency: json['currency'] != null
          ? _CurrencyInfo.fromJson(json['currency'] as Map<String, dynamic>)
          : null,
    );
  }

  final String id;
  final double amount;
  final double? taxAmount;
  final double? feeAmount;
  final double? netAmount;
  final String? transferImageUrl;
  final String? transactionReference;
  final String? status;
  final String? rejectionReason;
  final String? processedBy;
  final String? processedAt;
  final bool? walletCredited;
  final String? createdAt;
  final String? updatedAt;
  // ignore: library_private_types_in_public_api
  final _BankInfo? bank;
  // ignore: library_private_types_in_public_api
  final _CurrencyInfo? currency;
}

class _BankInfo {
  _BankInfo({required this.id, this.name, this.code});

  factory _BankInfo.fromJson(Map<String, dynamic> json) {
    return _BankInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      code: json['code'] as String?,
    );
  }

  final String id;
  final String? name;
  final String? code;
}

class _CurrencyInfo {
  _CurrencyInfo({required this.id, this.name, this.symbol});

  factory _CurrencyInfo.fromJson(Map<String, dynamic> json) {
    return _CurrencyInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String?,
      symbol: json['symbol'] as String?,
    );
  }

  final String id;
  final String? name;
  final String? symbol;
}
