/// نموذج معاملة المحفظة.
class Transaction {
  const Transaction({
    required this.id,
    required this.accountId,
    required this.assetType,
    required this.assetId,
    required this.balanceId,
    required this.assetSymbol,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.balanceField,
    required this.title,
    required this.journalEntryId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String? ?? '',
      accountId: json['accountId'] as String? ?? '',
      assetType: json['assetType'] as String? ?? 'CURRENCY',
      assetId: json['assetId'] as String? ?? '',
      balanceId: json['balanceId'] as String? ?? '',
      assetSymbol: json['assetSymbol'] as String? ?? '',
      type: json['type'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      balanceBefore: (json['balanceBefore'] as num?)?.toDouble() ?? 0,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0,
      balanceField: json['balanceField'] as String? ?? '',
      title: json['title'] as String? ?? '',
      journalEntryId: json['journalEntryId'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  final String id;
  final String accountId;
  final String assetType;
  final String assetId;
  final String balanceId;
  final String assetSymbol;
  final String type;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String balanceField;
  final String title;
  final String journalEntryId;
  final String createdAt;
  final String updatedAt;

  bool get isDeposit => type.toUpperCase() == 'DEPOSIT' || amount >= 0;
}
