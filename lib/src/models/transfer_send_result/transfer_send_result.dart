class TransferSendResult {
  const TransferSendResult({
    required this.transferId,
    required this.status,
    required this.sender,
    required this.receiver,
    required this.currency,
    required this.amount,
    required this.purpose,
    required this.note,
    required this.inputMethod,
    required this.createdAt,
  });

  factory TransferSendResult.fromJson(Map<String, dynamic> json) {
    return TransferSendResult(
      transferId: json['transferId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      sender: TransferSendParty.fromJson(
        (json['sender'] as Map<String, dynamic>?) ?? const {},
      ),
      receiver: TransferSendParty.fromJson(
        (json['receiver'] as Map<String, dynamic>?) ?? const {},
      ),
      currency: TransferSendCurrency.fromJson(
        (json['currency'] as Map<String, dynamic>?) ?? const {},
      ),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      purpose: json['purpose'] as String? ?? '',
      note: json['note'] as String? ?? '',
      inputMethod: json['inputMethod'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  final String transferId;
  final String status;
  final TransferSendParty sender;
  final TransferSendParty receiver;
  final TransferSendCurrency currency;
  final double amount;
  final String purpose;
  final String note;
  final String inputMethod;
  final String createdAt;

  bool get isCompleted => status.toUpperCase() == 'COMPLETED';
}

class TransferSendParty {
  const TransferSendParty({
    required this.accountNumber,
    required this.name,
    required this.balanceAfter,
  });

  factory TransferSendParty.fromJson(Map<String, dynamic> json) {
    return TransferSendParty(
      accountNumber: json['accountNumber'] as String? ?? '',
      name: json['name'] as String? ?? '',
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0,
    );
  }

  final String accountNumber;
  final String name;
  final double balanceAfter;
}

class TransferSendCurrency {
  const TransferSendCurrency({required this.symbol, required this.name});

  factory TransferSendCurrency.fromJson(Map<String, dynamic> json) {
    return TransferSendCurrency(
      symbol: json['symbol'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  final String symbol;
  final String name;
}
