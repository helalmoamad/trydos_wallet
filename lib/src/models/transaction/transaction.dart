class TransactionParty {
  const TransactionParty({
    required this.id,
    required this.accountNumber,
    required this.name,
  });

  factory TransactionParty.fromJson(Map<String, dynamic> json) {
    return TransactionParty(
      id: json['id'] as String? ?? '',
      accountNumber: json['accountNumber'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  final String id;
  final String accountNumber;
  final String name;
}

class TransactionMetadata {
  const TransactionMetadata({
    required this.purposeId,
    required this.purposeName,
    required this.inputMethod,
    required this.note,
  });

  factory TransactionMetadata.fromJson(Map<String, dynamic> json) {
    return TransactionMetadata(
      purposeId: json['purposeId'] as String? ?? '',
      purposeName: json['purposeName'] as String? ?? '',
      inputMethod: json['inputMethod'] as String? ?? '',
      note: json['note'] as String? ?? '',
    );
  }

  final String purposeId;
  final String purposeName;
  final String inputMethod;
  final String note;
}

/// نموذج معاملة المحفظة.
class Transaction {
  const Transaction({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.ledgerType,
    required this.status,
    required this.direction,
    required this.assetType,
    required this.assetId,
    required this.description,
    required this.balanceId,
    required this.assetSymbol,
    required this.type,
    required this.amount,
    required this.feeAmount,
    required this.taxAmount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.balanceField,
    required this.title,
    required this.journalEntryId,
    required this.senderUserId,
    required this.senderAccount,
    required this.receiverUserId,
    required this.receiverAccount,
    required this.referenceId,
    required this.errorMessage,
    required this.note,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      accountId: json['accountId'] as String? ?? '',
      ledgerType:
          json['ledgerType'] as String? ?? json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      direction: json['direction'] as String? ?? '',
      assetType: json['assetType'] as String? ?? 'CURRENCY',
      assetId: json['assetId'] as String? ?? '',
      description: json['description'] as String?,
      balanceId: json['balanceId'] as String? ?? '',
      assetSymbol: json['assetSymbol'] as String? ?? '',
      type: json['type'] as String? ?? json['ledgerType'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      feeAmount: (json['feeAmount'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['taxAmount'] as num?)?.toDouble() ?? 0,
      balanceBefore: (json['balanceBefore'] as num?)?.toDouble() ?? 0,
      balanceAfter: (json['balanceAfter'] as num?)?.toDouble() ?? 0,
      balanceField: json['balanceField'] as String? ?? '',
      title: json['title'] as String? ?? '',
      journalEntryId: json['journalEntryId'] as String? ?? '',
      senderUserId: json['senderUserId'] as String? ?? '',
      senderAccount: TransactionParty.fromJson(
        (json['senderAccount'] as Map<String, dynamic>?) ?? const {},
      ),
      receiverUserId: json['receiverUserId'] as String? ?? '',
      receiverAccount: TransactionParty.fromJson(
        (json['receiverAccount'] as Map<String, dynamic>?) ?? const {},
      ),
      referenceId: json['referenceId'] as String? ?? '',
      errorMessage: json['errorMessage'] as String?,
      note: json['note'] as String? ?? '',
      metadata: TransactionMetadata.fromJson(
        (json['metadata'] as Map<String, dynamic>?) ?? const {},
      ),
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  final String id;
  final String userId;
  final String accountId;
  final String ledgerType;
  final String status;
  final String direction;
  final String assetType;
  final String assetId;
  final String? description;
  final String balanceId;
  final String assetSymbol;
  final String type;
  final double amount;
  final double feeAmount;
  final double taxAmount;
  final double balanceBefore;
  final double balanceAfter;
  final String balanceField;
  final String title;
  final String journalEntryId;
  final String senderUserId;
  final TransactionParty senderAccount;
  final String receiverUserId;
  final TransactionParty receiverAccount;
  final String referenceId;
  final String? errorMessage;
  final String note;
  final TransactionMetadata metadata;
  final String createdAt;
  final String updatedAt;

  bool get isDeposit {
    if (direction.isNotEmpty) {
      return direction.toUpperCase() == 'IN';
    }
    return type.toUpperCase() == 'DEPOSIT' || amount >= 0;
  }

  bool get isOutgoing => direction.toUpperCase() == 'OUT';

  bool get isAccountTransfer => ledgerType.toUpperCase() == 'ACCOUNT_TRANSFER';
}
