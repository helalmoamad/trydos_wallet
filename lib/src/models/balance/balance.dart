/// نموذج رصيد المحفظة لعملة محددة.
class Balance {
  const Balance({
    required this.id,
    required this.accountId,
    required this.assetType,
    required this.assetId,
    required this.assetSymbol,
    required this.available,
    required this.locked,
    required this.reserved,
    required this.createdAt,
    required this.updatedAt,
    this.asset,
    this.accountSubtype = 'MAIN',
  });

  factory Balance.fromJson(Map<String, dynamic> json) {
    return Balance(
      id: json['id'] as String? ?? '',
      accountId: json['accountId'] as String? ?? '',
      assetType: json['assetType'] as String? ?? 'CURRENCY',
      assetId: json['assetId'] as String? ?? '',
      assetSymbol: json['assetSymbol'] as String? ?? '',
      available: (json['available'] as num?)?.toDouble() ?? 0,
      locked: (json['locked'] as num?)?.toDouble() ?? 0,
      reserved: (json['reserved'] as num?)?.toDouble() ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      asset: json['asset'] != null
          ? BalanceAsset.fromJson(json['asset'] as Map<String, dynamic>)
          : null,
      accountSubtype: json['accountSubtype'] as String? ?? 'MAIN',
    );
  }

  final String id;
  final String accountId;
  final String assetType;
  final String assetId;
  final String assetSymbol;
  final double available;
  final double locked;
  final double reserved;
  final String createdAt;
  final String updatedAt;
  final BalanceAsset? asset;
  final String accountSubtype;

  double get total => available + locked + reserved;
}

class BalanceAsset {
  const BalanceAsset({
    required this.id,
    required this.symbol,
    required this.name,
  });

  factory BalanceAsset.fromJson(Map<String, dynamic> json) {
    return BalanceAsset(
      id: json['id'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  final String id;
  final String symbol;
  final String name;
}
