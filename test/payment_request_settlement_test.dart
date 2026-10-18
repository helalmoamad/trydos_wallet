import 'package:flutter_test/flutter_test.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

void main() {
  /// A realtime ledger row as the requester receives it over the socket.
  Transaction ledgerRow({
    String id = 'ledger-in-1',
    String referenceId = 'transfer-1',
    String journalEntryId = 'journal-1',
  }) {
    return Transaction.fromJson(<String, dynamic>{
      'id': id,
      'referenceId': referenceId,
      'journalEntryId': journalEntryId,
      'direction': 'IN',
      'assetSymbol': 'SYP',
      'amount': 500,
      'status': 'COMPLETED',
    });
  }

  PaymentRequestLookupResponse request({
    String status = 'FULFILLED',
    String? financialLedgerInId,
    String? accountTransferId,
    String? journalEntryId,
  }) {
    return PaymentRequestLookupResponse.fromJson(<String, dynamic>{
      'id': 'req-1',
      'requestCode': 'pr.abc',
      'status': status,
      'amount': 500,
      'assetSymbol': 'SYP',
      'financialLedgerInId': financialLedgerInId,
      'accountTransferId': accountTransferId,
      'journalEntryId': journalEntryId,
    });
  }

  test('يطابق عبر معرّف قيد الطالب', () {
    expect(
      request(financialLedgerInId: 'ledger-in-1').isSettledBy(ledgerRow()),
      isTrue,
    );
  });

  test('يطابق عبر معرّف التحويل', () {
    expect(
      request(accountTransferId: 'transfer-1').isSettledBy(ledgerRow()),
      isTrue,
    );
  });

  test('يطابق عبر معرّف القيد اليومي', () {
    expect(
      request(journalEntryId: 'journal-1').isSettledBy(ledgerRow()),
      isTrue,
    );
  });

  test('عملية أخرى بنفس المبلغ والعملة لا تُطابق', () {
    // The whole point: identical money, unrelated operation.
    final other = ledgerRow(
      id: 'ledger-in-999',
      referenceId: 'transfer-999',
      journalEntryId: 'journal-999',
    );
    expect(
      request(
        financialLedgerInId: 'ledger-in-1',
        accountTransferId: 'transfer-1',
        journalEntryId: 'journal-1',
      ).isSettledBy(other),
      isFalse,
    );
  });

  test('طلب ما زال ACTIVE لا يحمل معرّفات فلا يُطابق شيئاً', () {
    expect(request(status: 'ACTIVE').isSettledBy(ledgerRow()), isFalse);
  });

  test('المعرّفات الفارغة لا تُطابق الفراغ', () {
    final blank = Transaction.fromJson(<String, dynamic>{
      'id': 'ledger-in-1',
      'referenceId': '',
      'journalEntryId': '',
      'direction': 'IN',
    });
    expect(request(accountTransferId: '').isSettledBy(blank), isFalse);
    expect(request(journalEntryId: '   ').isSettledBy(blank), isFalse);
  });

  test('isActive يميّز الطلب القابل للاستعمال', () {
    expect(request(status: 'ACTIVE').isActive, isTrue);
    expect(request(status: 'active').isActive, isTrue);
    expect(request(status: 'FULFILLED').isActive, isFalse);
    expect(request(status: 'EXPIRED').isActive, isFalse);
    expect(request(status: 'CANCELLED').isActive, isFalse);
  });
}
