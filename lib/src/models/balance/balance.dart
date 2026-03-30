/// نموذج رصيد المحفظة لعملة محددة.
class Balance {
  static WalletIdentity? _lastMyAccountsPrimaryWallet;

  static WalletIdentity? get lastMyAccountsPrimaryWallet =>
      _lastMyAccountsPrimaryWallet;

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
    this.accountNumber = '',
    this.accountName = '',
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
      accountNumber: json['accountNumber'] as String? ?? '',
      accountName: json['accountName'] as String? ?? '',
      accountSubtype: json['accountSubtype'] as String? ?? 'MAIN',
    );
  }

  factory Balance.fromMyAccountsJson(
    Map<String, dynamic> json, {
    required String requestedAssetId,
    String? fallbackSymbol,
  }) {
    final wallets = (json['wallets'] as List?)?.cast<dynamic>() ?? const [];
    Map<String, dynamic>? fallbackWallet;
    Map<String, dynamic>? fallbackBalance;

    for (final rawWallet in wallets) {
      final wallet = rawWallet as Map<String, dynamic>?;
      if (wallet == null) continue;
      final balances =
          (wallet['balances'] as List?)?.cast<dynamic>() ?? const [];

      for (final rawBalance in balances) {
        final balance = rawBalance as Map<String, dynamic>?;
        if (balance == null) continue;

        fallbackWallet ??= wallet;
        fallbackBalance ??= balance;

        final assetId = balance['assetId'] as String? ?? '';
        final assetSymbol = (balance['assetSymbol'] as String? ?? '')
            .toUpperCase();
        final desiredSymbol = (fallbackSymbol ?? '').toUpperCase();

        if (assetId == requestedAssetId ||
            (desiredSymbol.isNotEmpty && assetSymbol == desiredSymbol)) {
          return Balance.fromJson({
            ...balance,
            'accountNumber': wallet['accountNumber'],
            'accountName': wallet['name'],
          });
        }
      }
    }

    if (fallbackBalance != null && fallbackWallet != null) {
      return Balance.fromJson({
        ...fallbackBalance,
        'accountNumber': fallbackWallet['accountNumber'],
        'accountName': fallbackWallet['name'],
      });
    }

    return Balance(
      id: '',
      accountId: '',
      assetType: 'CURRENCY',
      assetId: requestedAssetId,
      assetSymbol: fallbackSymbol ?? '',
      available: 0,
      locked: 0,
      reserved: 0,
      createdAt: '',
      updatedAt: '',
      accountSubtype: 'MAIN',
    );
  }

  static List<Balance> listFromMyAccountsJson(Map<String, dynamic> json) {
    final wallets = (json['wallets'] as List?)?.cast<dynamic>() ?? const [];
    final result = <Balance>[];
    _lastMyAccountsPrimaryWallet = null;

    for (final rawWallet in wallets) {
      final wallet = rawWallet as Map<String, dynamic>?;
      if (wallet == null) continue;

      _lastMyAccountsPrimaryWallet ??= WalletIdentity(
        accountNumber: (wallet['accountNumber'] ?? '').toString(),
        accountName: (wallet['name'] ?? '').toString(),
        accountSubtype: ((wallet['subtype'] ?? 'MAIN').toString()).isEmpty
            ? 'MAIN'
            : (wallet['subtype'] ?? 'MAIN').toString(),
      );

      final balances =
          (wallet['balances'] as List?)?.cast<dynamic>() ?? const [];
      for (final rawBalance in balances) {
        final balance = rawBalance as Map<String, dynamic>?;
        if (balance == null) continue;

        result.add(
          Balance.fromJson({
            ...balance,
            'accountNumber': wallet['accountNumber'],
            'accountName': wallet['name'],
          }),
        );
      }
    }

    return result;
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
  final String accountNumber;
  final String accountName;
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
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      name: json['name'] as String? ?? json['displayName'] as String? ?? '',
    );
  }

  final String id;
  final String symbol;
  final String name;
}

class WalletIdentity {
  const WalletIdentity({
    required this.accountNumber,
    required this.accountName,
    this.accountSubtype = 'MAIN',
  });

  final String accountNumber;
  final String accountName;
  final String accountSubtype;
}
