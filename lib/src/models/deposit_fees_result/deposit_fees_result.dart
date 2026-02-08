/// Deposit fees and taxes calculation result.
class DepositFeesResult {
  const DepositFeesResult({
    required this.amount,
    required this.taxAmount,
    required this.feeAmount,
    required this.netAmount,
    required this.totalDeductions,
    required this.currencySymbol,
    this.bankNameEn,
    this.bankNameAr,
  });

  factory DepositFeesResult.fromJson(Map<String, dynamic> json) {
    return DepositFeesResult(
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
      feeAmount: (json['feeAmount'] as num?)?.toDouble() ?? 0,
      netAmount: (json['netAmount'] as num?)?.toDouble() ?? 0,
      totalDeductions: (json['totalDeductions'] as num?)?.toDouble() ?? 0,
      currencySymbol: json['currencySymbol'] as String? ?? '',
      bankNameEn: json['bankNameEn'] as String?,
      bankNameAr: json['bankNameAr'] as String?,
    );
  }

  final double amount;
  final double taxAmount;
  final double feeAmount;
  final double netAmount;
  final double totalDeductions;
  final String currencySymbol;
  final String? bankNameEn;
  final String? bankNameAr;
}
