class TransferVerifyResult {
  const TransferVerifyResult({
    required this.valid,
    required this.sender,
    required this.receiver,
    required this.currency,
    required this.amount,
  });

  factory TransferVerifyResult.fromJson(Map<String, dynamic> json) {
    return TransferVerifyResult(
      valid: json['valid'] as bool? ?? false,
      sender: TransferVerifyParty.fromJson(
        (json['sender'] as Map<String, dynamic>?) ?? const {},
      ),
      receiver: TransferVerifyParty.fromJson(
        (json['receiver'] as Map<String, dynamic>?) ?? const {},
      ),
      currency: TransferVerifyCurrency.fromJson(
        (json['currency'] as Map<String, dynamic>?) ?? const {},
      ),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  final bool valid;
  final TransferVerifyParty sender;
  final TransferVerifyParty receiver;
  final TransferVerifyCurrency currency;
  final double amount;
}

class TransferVerifyParty {
  const TransferVerifyParty({
    required this.accountNumber,
    required this.name,
    required this.availableBalance,
  });

  factory TransferVerifyParty.fromJson(Map<String, dynamic> json) {
    return TransferVerifyParty(
      accountNumber: json['accountNumber'] as String? ?? '',
      name: json['name'] as String? ?? '',
      availableBalance: (json['availableBalance'] as num?)?.toDouble() ?? 0,
    );
  }

  final String accountNumber;
  final String name;
  final double availableBalance;
}

class TransferVerifyCurrency {
  const TransferVerifyCurrency({required this.symbol, required this.name});

  factory TransferVerifyCurrency.fromJson(Map<String, dynamic> json) {
    return TransferVerifyCurrency(
      symbol: json['symbol'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  final String symbol;
  final String name;
}
