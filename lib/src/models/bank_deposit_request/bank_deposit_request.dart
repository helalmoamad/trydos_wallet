/// نموذج طلب إيداع بنكي (للعرض في الجدول).
class BankDepositRequest {
  const BankDepositRequest({
    required this.id,
    required this.amount,
    required this.taxAmount,
    required this.feeAmount,
    required this.netAmount,
    required this.transactionReference,
    required this.status,
    required this.createdAt,
    // ignore: library_private_types_in_public_api
    required this.bank,
    // ignore: library_private_types_in_public_api
    required this.currency,
  });

  factory BankDepositRequest.fromJson(Map<String, dynamic> json) {
    return BankDepositRequest(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
      feeAmount: (json['feeAmount'] as num?)?.toDouble() ?? 0,
      netAmount: (json['netAmount'] as num?)?.toDouble() ?? 0,
      transactionReference: json['transactionReference'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['createdAt'] as String? ?? '',
      bank: json['bank'] != null
          ? _BankInfo.fromJson(json['bank'] as Map<String, dynamic>)
          : const _BankInfo(id: '', name: '', code: null),
      currency: json['currency'] != null
          ? _CurrencyInfo.fromJson(json['currency'] as Map<String, dynamic>)
          : const _CurrencyInfo(id: '', name: '', symbol: ''),
    );
  }

  final String id;
  final double amount;
  final double taxAmount;
  final double feeAmount;
  final double netAmount;
  final String transactionReference;
  final String status;
  final String createdAt;
  // ignore: library_private_types_in_public_api
  final _BankInfo bank;
  // ignore: library_private_types_in_public_api
  final _CurrencyInfo currency;
}

class _BankInfo {
  const _BankInfo({required this.id, required this.name, this.code});

  factory _BankInfo.fromJson(Map<String, dynamic> json) {
    return _BankInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
    );
  }

  final String id;
  final String name;
  final String? code;
}

class _CurrencyInfo {
  const _CurrencyInfo({
    required this.id,
    required this.name,
    required this.symbol,
  });

  factory _CurrencyInfo.fromJson(Map<String, dynamic> json) {
    return _CurrencyInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String symbol;
}
