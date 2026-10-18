import '../transaction/transaction.dart';

class PaymentRequestLookupPurpose {
  const PaymentRequestLookupPurpose({required this.id, required this.name});

  final String id;
  final String name;

  factory PaymentRequestLookupPurpose.fromJson(Map<String, dynamic> json) {
    return PaymentRequestLookupPurpose(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
    );
  }
}

class PaymentRequestLookupResponse {
  const PaymentRequestLookupResponse({
    required this.id,
    required this.requesterAccountNumber,
    required this.requesterAccountName,
    required this.purpose,
    required this.assetType,
    required this.assetSymbol,
    required this.amount,
    this.note,
    this.reference,
    required this.requestCode,
    this.expiresAt,
    required this.isPermanent,
    required this.status,
    this.createdAt,
    this.financialLedgerInId,
    this.accountTransferId,
    this.journalEntryId,
  });

  final String id;
  final String requesterAccountNumber;
  final String requesterAccountName;
  final PaymentRequestLookupPurpose? purpose;
  final String assetType;
  final String assetSymbol;
  final double amount;
  final String? note;
  final String? reference;
  final String requestCode;
  final DateTime? expiresAt;
  final bool isPermanent;
  final String status;
  final DateTime? createdAt;

  /// Identifiers of the movement that settled this request — null while it is
  /// still ACTIVE. They are what ties a realtime ledger event to this request:
  /// [financialLedgerInId] is the requester's own ledger entry (the incoming
  /// side), [accountTransferId] the transfer, [journalEntryId] the journal.
  final String? financialLedgerInId;
  final String? accountTransferId;
  final String? journalEntryId;

  /// Whether this request is still usable — anything else means it has been
  /// paid, cancelled or has expired.
  bool get isActive => status.trim().toUpperCase() == 'ACTIVE';

  /// Whether [transaction] is the movement that settled this request.
  ///
  /// Matched on the operation ids the server reports once a request is
  /// fulfilled, never on the amount: two unrelated transfers can carry the
  /// same amount in the same asset, and treating that as settlement would tell
  /// a requester a payment arrived when none did.
  ///
  /// [financialLedgerInId] is the requester's own ledger entry — the very row
  /// a `ledger:created` event announces to them. The other two cover servers
  /// that report the transfer or the journal entry instead.
  bool isSettledBy(Transaction transaction) {
    bool sameId(String? a, String b) {
      final left = (a ?? '').trim();
      final right = b.trim();
      return left.isNotEmpty && right.isNotEmpty && left == right;
    }

    return sameId(financialLedgerInId, transaction.id) ||
        sameId(accountTransferId, transaction.referenceId) ||
        sameId(journalEntryId, transaction.journalEntryId);
  }

  factory PaymentRequestLookupResponse.fromJson(Map<String, dynamic> json) {
    String? normalizeOptionalString(dynamic value) {
      if (value == null) return null;
      if (value is String) {
        final trimmed = value.trim();
        return trimmed.isEmpty ? null : trimmed;
      }
      if (value is Map || value is List) {
        return null;
      }
      final asString = value.toString().trim();
      return asString.isEmpty ? null : asString;
    }

    DateTime? parseOptionalDate(dynamic value) {
      if (value == null) return null;
      if (value is String && value.trim().isNotEmpty) {
        return DateTime.tryParse(value)?.toLocal();
      }
      return null;
    }

    final purposeJson = json['purpose'];

    return PaymentRequestLookupResponse(
      id: (json['id'] ?? '').toString(),
      requesterAccountNumber: (json['requesterAccountNumber'] ?? '').toString(),
      requesterAccountName: (json['requesterAccountName'] ?? '').toString(),
      purpose: purposeJson is Map<String, dynamic>
          ? PaymentRequestLookupPurpose.fromJson(purposeJson)
          : null,
      assetType: (json['assetType'] ?? '').toString(),
      assetSymbol: (json['assetSymbol'] ?? '').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      note: normalizeOptionalString(json['note']),
      reference: normalizeOptionalString(json['reference']),
      requestCode: (json['requestCode'] ?? '').toString(),
      expiresAt: parseOptionalDate(json['expiresAt']),
      isPermanent: json['isPermanent'] as bool? ?? false,
      status: (json['status'] ?? '').toString(),
      createdAt: parseOptionalDate(json['createdAt']),
      financialLedgerInId: normalizeOptionalString(json['financialLedgerInId']),
      accountTransferId: normalizeOptionalString(json['accountTransferId']),
      journalEntryId: normalizeOptionalString(json['journalEntryId']),
    );
  }
}
