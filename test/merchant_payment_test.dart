import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trydos_wallet/src/api/api_client.dart';
import 'package:trydos_wallet/src/config/trydos_wallet_config.dart';
import 'package:trydos_wallet/src/models/models.dart';
import 'package:trydos_wallet/src/utils/decimal_amount.dart';
import 'package:trydos_wallet/src/utils/merchant_payment_errors.dart';
import 'package:trydos_wallet/src/utils/payment_code.dart';
import 'package:trydos_wallet/src/utils/payment_link.dart';

/// Builds a failed [ApiResult] the way [ApiClient] would for a given response.
ApiResult<Object?> _failure({int? statusCode, String? code, String? message}) {
  final requestOptions = RequestOptions(path: '/merchant/payments/x/pay');
  return ApiResult<Object?>.failure(
    DioException(
      requestOptions: requestOptions,
      response: Response<dynamic>(
        requestOptions: requestOptions,
        statusCode: statusCode,
        data: {'statusCode': statusCode, 'code': code, 'message': message},
      ),
      type: DioExceptionType.badResponse,
    ),
    errorMessage: message,
    statusCode: statusCode,
    errorCode: code,
  );
}

ApiResult<Object?> _timeout() {
  final requestOptions = RequestOptions(path: '/merchant/payments/x/pay');
  return ApiResult<Object?>.failure(
    DioException(
      requestOptions: requestOptions,
      type: DioExceptionType.receiveTimeout,
    ),
  );
}

void main() {
  group('DecimalAmount', () {
    test('parses and preserves the string the server sent', () {
      final amount = DecimalAmount.tryParse('100.00');
      expect(amount, isNotNull);
      expect(amount!.raw, '100.00');
      expect(amount.toString(), '100.00');
    });

    test('compares exactly where a double would round', () {
      // 0.1 + 0.2 == 0.30000000000000004 in binary floating point.
      final sum =
          DecimalAmount.tryParse('0.1')! + DecimalAmount.tryParse('0.2')!;
      expect(sum, DecimalAmount.tryParse('0.3'));
      expect(sum.compareTo(DecimalAmount.tryParse('0.3')!), 0);
    });

    test('compares across different scales', () {
      final hundred = DecimalAmount.tryParse('100.00')!;
      final metal = DecimalAmount.tryParse('100.000000')!;
      expect(hundred, metal);
      expect(hundred < DecimalAmount.tryParse('100.000001')!, isTrue);
      expect(hundred > DecimalAmount.tryParse('99.999999')!, isTrue);
    });

    test('equal values hash equally regardless of trailing zeros', () {
      expect(
        DecimalAmount.tryParse('1.50')!.hashCode,
        DecimalAmount.tryParse('1.5')!.hashCode,
      );
    });

    test('adds without losing precision', () {
      final total =
          DecimalAmount.tryParse('100.00')! + DecimalAmount.tryParse('2.25')!;
      expect(total.raw, '102.25');
    });

    test('refuses anything that is not a plain decimal', () {
      expect(DecimalAmount.tryParse('1,000.00'), isNull);
      expect(DecimalAmount.tryParse('1e3'), isNull);
      expect(DecimalAmount.tryParse(''), isNull);
      expect(DecimalAmount.tryParse(null), isNull);
      expect(DecimalAmount.tryParse('abc'), isNull);
    });

    test('handles negatives', () {
      final negative = DecimalAmount.tryParse('-25.50')!;
      expect(negative.isNegative, isTrue);
      expect(negative < DecimalAmount.zero, isTrue);
      expect((negative + DecimalAmount.tryParse('25.50')!).isZero, isTrue);
    });
  });

  group('PaymentCode', () {
    test('classifies each namespace', () {
      expect(PaymentCode.kindOf('pr.abc123'), PaymentCodeKind.peer);
      expect(PaymentCode.kindOf('mp.abc123'), PaymentCodeKind.merchant);
      expect(
        PaymentCode.kindOf('4817302956'),
        PaymentCodeKind.merchantCounter,
      );
    });

    test('rejects a string in no namespace without a lookup', () {
      expect(PaymentCode.isResolvable('https://example.com'), isFalse);
      expect(PaymentCode.isResolvable('0000-0030'), isFalse);
      expect(PaymentCode.isResolvable('481730295'), isFalse); // 9 digits
      expect(PaymentCode.isResolvable('48173029567'), isFalse); // 11 digits
      expect(PaymentCode.isResolvable(''), isFalse);
      expect(PaymentCode.isResolvable(null), isFalse);
    });

    test('trims spaces a QR or a person added', () {
      expect(PaymentCode.normalize('  481 730 2956 '), '4817302956');
      expect(PaymentCode.isCounterCode('481 730 2956'), isTrue);
      expect(PaymentCode.normalize(' pr.abc\n'), 'pr.abc');
    });

    test('groups a counter code for display', () {
      expect(PaymentCode.formatCounterCode('4817302956'), '481 730 2956');
      // Not a counter code: returned untouched rather than mangled.
      expect(PaymentCode.formatCounterCode('pr.abc'), 'pr.abc');
    });

    test('groups progressively while typing and caps at ten digits', () {
      expect(PaymentCode.formatCounterCodeInput('481'), '481');
      expect(PaymentCode.formatCounterCodeInput('4817'), '481 7');
      expect(PaymentCode.formatCounterCodeInput('481730'), '481 730');
      expect(PaymentCode.formatCounterCodeInput('4817302956'), '481 730 2956');
      expect(
        PaymentCode.formatCounterCodeInput('48173029561234'),
        '481 730 2956',
      );
    });
  });

  group('Trydos store QR payload', () {
    // The Trydos payment screen encodes the bare short code — ten ASCII digits,
    // no scheme, no prefix, no whitespace — and the scanner must treat it as the
    // code the customer would otherwise have typed. An external team depends on
    // this exact contract, so it is pinned here rather than left implied.
    const payload = '4817302956';

    test('the documented payload resolves as a merchant counter code', () {
      expect(PaymentCode.kindOf(payload), PaymentCodeKind.merchantCounter);
      expect(PaymentCode.isResolvable(payload), isTrue);
      expect(PaymentCode.isCounterCode(payload), isTrue);
      // Sent to the lookup byte-for-byte as scanned.
      expect(PaymentCode.normalize(payload), payload);
    });

    test('survives whitespace a scanner or a screenshot may add', () {
      for (final noisy in ['  $payload', '$payload\n', ' 481 730 2956 ']) {
        expect(
          PaymentCode.kindOf(noisy),
          PaymentCodeKind.merchantCounter,
          reason: 'payload "$noisy"',
        );
        expect(PaymentCode.normalize(noisy), payload);
      }
    });

    test('a near-miss length is not mistaken for a code', () {
      // Falls through to the scanner's other formats instead of spending one of
      // the ten lookups the throttle allows.
      expect(PaymentCode.isResolvable('481730295'), isFalse);
      expect(PaymentCode.isResolvable('48173029567'), isFalse);
    });
  });

  group('PaymentLink', () {
    test('extracts a code from a universal link', () {
      expect(
        PaymentLink.extractCodeFromString('https://pay.example.com/r/v1/mp.abc'),
        'mp.abc',
      );
    });

    test('extracts a code from the custom-scheme fallback', () {
      expect(PaymentLink.extractCodeFromString('rdb://r/v1/mp.abc'), 'mp.abc');
    });

    test('extracts a code from a query parameter', () {
      expect(
        PaymentLink.extractCodeFromString('rdb://pay?code=4817302956'),
        '4817302956',
      );
    });

    test('accepts the spellings the store checkout response uses', () {
      expect(
        PaymentLink.extractCodeFromString(
          'https://pay.example.com/p?request_code=mp.q7Vb2kLm9XwPz3RaAbCdEf',
        ),
        'mp.q7Vb2kLm9XwPz3RaAbCdEf',
      );
      expect(
        PaymentLink.extractCodeFromString(
          'https://pay.example.com/p?short_code=4817302956',
        ),
        '4817302956',
      );
    });

    test('falls back to a trailing code on an unknown path shape', () {
      // The hosted payment page does not exist yet, so its URL shape is not
      // settled. A link that simply ends in the code still resolves.
      expect(
        PaymentLink.extractCodeFromString(
          'https://pay.example.com/pay/mp.q7Vb2kLm9XwPz3RaAbCdEf',
        ),
        'mp.q7Vb2kLm9XwPz3RaAbCdEf',
      );
      expect(
        PaymentLink.extractCodeFromString('https://pay.example.com/x/4817302956'),
        '4817302956',
      );
    });

    test('rejects a link that carries nothing resolvable', () {
      expect(
        PaymentLink.extractCodeFromString('https://example.com/r/v1/not-a-code'),
        isNull,
      );
      expect(PaymentLink.extractCodeFromString('https://example.com'), isNull);
      expect(PaymentLink.extractCodeFromString(null), isNull);
    });
  });

  group('MerchantPaymentStatus', () {
    test('maps the documented statuses', () {
      expect(
        MerchantPaymentStatus.fromString('PENDING'),
        MerchantPaymentStatus.pending,
      );
      expect(
        MerchantPaymentStatus.fromString('PARTIALLY_REFUNDED'),
        MerchantPaymentStatus.partiallyRefunded,
      );
    });

    test('an unknown status is neutral, never paid', () {
      final status = MerchantPaymentStatus.fromString('SOMETHING_NEW');
      expect(status, MerchantPaymentStatus.unknown);
      expect(status.isPayable, isFalse);
      expect(status.isSettled, isFalse);
      expect(status.labelKey, 'merchant_status_processing');
    });

    test('processing and failed are not confirmations', () {
      expect(MerchantPaymentStatus.processing.isSettled, isFalse);
      expect(MerchantPaymentStatus.failed.isSettled, isFalse);
      expect(MerchantPaymentStatus.paid.isSettled, isTrue);
      expect(MerchantPaymentStatus.refunded.isSettled, isTrue);
    });

    test('only PENDING is payable', () {
      for (final status in MerchantPaymentStatus.values) {
        expect(
          status.isPayable,
          status == MerchantPaymentStatus.pending,
          reason: '${status.name} payability',
        );
      }
    });
  });

  group('MerchantLocalizedText', () {
    test('picks the user language', () {
      const text = MerchantLocalizedText(en: 'Order #1', ar: 'طلب رقم ١');
      expect(text.resolve('en'), 'Order #1');
      expect(text.resolve('ar'), 'طلب رقم ١');
    });

    test('falls back to the other language rather than showing nothing', () {
      const arabicOnly = MerchantLocalizedText(ar: 'طلب رقم ١');
      expect(arabicOnly.resolve('en'), 'طلب رقم ١');

      const englishOnly = MerchantLocalizedText(en: 'Order #1');
      expect(englishOnly.resolve('ar'), 'Order #1');
    });

    test('languages the shop never sends fall through to English', () {
      const text = MerchantLocalizedText(en: 'Order #1', ar: 'طلب رقم ١');
      expect(text.resolve('ku'), 'Order #1');
      expect(text.resolve('tr'), 'Order #1');
    });

    test('is empty when the shop sent nothing', () {
      expect(MerchantLocalizedText.empty.resolve('en'), '');
      expect(MerchantLocalizedText.empty.isEmpty, isTrue);
    });
  });

  group('PaymentCodeResolution', () {
    test('routes a merchant response on kind', () {
      final resolution = PaymentCodeResolution.fromJson({
        'kind': 'MERCHANT',
        'merchant': {
          'id': '66f1',
          'status': 'PENDING',
          'payable': true,
          'merchantName': 'Al Salam Stores',
          'orderRef': 'ORD-10231',
          'amount': '100.00',
          'feeAmount': '0.00',
          'assetType': 'CURRENCY',
          'assetSymbol': 'USD',
          'description': {'en': 'Order #10231', 'ar': 'طلب رقم 10231'},
          'expiresAt': '2026-10-01T09:44:00.000Z',
        },
      });

      expect(resolution.isMerchant, isTrue);
      expect(resolution.merchant!.merchantName, 'Al Salam Stores');
      // The amount stays a string, exactly as sent.
      expect(resolution.merchant!.amount, '100.00');
      expect(resolution.merchant!.hasFee, isFalse);
    });

    test('routes a peer response on kind', () {
      final resolution = PaymentCodeResolution.fromJson({
        'kind': 'USER',
        'id': 'req-1',
        'requesterAccountNumber': '0000-0030',
        'requesterAccountName': 'Sara',
        'assetType': 'CURRENCY',
        'assetSymbol': 'USD',
        'amount': 25,
        'requestCode': 'pr.abc',
        'status': 'ACTIVE',
      });

      expect(resolution.isUser, isTrue);
      expect(resolution.peer!.requesterAccountNumber, '0000-0030');
    });

    test('a response with no kind is treated as a peer request', () {
      final resolution = PaymentCodeResolution.fromJson({
        'id': 'req-1',
        'requesterAccountNumber': '0000-0030',
        'requesterAccountName': 'Sara',
        'amount': 25,
        'requestCode': 'pr.abc',
        'status': 'ACTIVE',
      });

      expect(resolution.kind, ResolvedCodeKind.user);
    });

    test('an unknown kind resolves to neither flow', () {
      final resolution = PaymentCodeResolution.fromJson({'kind': 'SOMETHING'});
      expect(resolution.kind, ResolvedCodeKind.unknown);
      expect(resolution.isUser, isFalse);
      expect(resolution.isMerchant, isFalse);
    });
  });

  group('MerchantPaymentLookup', () {
    test('a missing payable flag falls back to the status', () {
      final lookup = MerchantPaymentLookup.fromJson({
        'id': '66f1',
        'status': 'EXPIRED',
        'merchantName': 'Al Salam Stores',
        'amount': '100.00',
      });
      expect(lookup.payable, isFalse);
    });

    test('a non-zero fee is reported', () {
      final lookup = MerchantPaymentLookup.fromJson({
        'id': '66f1',
        'status': 'PENDING',
        'payable': true,
        'amount': '100.00',
        'feeAmount': '1.50',
      });
      expect(lookup.hasFee, isTrue);
    });

    test('expiry is evaluated against the clock, not assumed', () {
      final past = MerchantPaymentLookup.fromJson({
        'id': '66f1',
        'status': 'PENDING',
        'payable': true,
        'amount': '100.00',
        'expiresAt': DateTime.now()
            .subtract(const Duration(minutes: 1))
            .toUtc()
            .toIso8601String(),
      });
      expect(past.isExpiredNow, isTrue);

      final future = MerchantPaymentLookup.fromJson({
        'id': '66f1',
        'status': 'PENDING',
        'payable': true,
        'amount': '100.00',
        'expiresAt': DateTime.now()
            .add(const Duration(minutes: 5))
            .toUtc()
            .toIso8601String(),
      });
      expect(future.isExpiredNow, isFalse);
    });
  });

  group('MerchantPaymentHistoryPage', () {
    test('reports a refund honestly', () {
      final page = MerchantPaymentHistoryPage.fromJson({
        'items': [
          {
            'id': '66f1',
            'status': 'PARTIALLY_REFUNDED',
            'merchantName': 'Al Salam Stores',
            'orderRef': 'ORD-10231',
            'amount': '100.00',
            'refundedAmount': '25.00',
            'assetSymbol': 'USD',
            'receiptNumber': 'RDB-R-2026-000123',
            'paidAt': '2026-10-01T09:14:03.118Z',
          },
        ],
        'total': 1,
        'page': 0,
        'limit': 20,
      });

      expect(page.items.single.hasRefund, isTrue);
      expect(page.items.single.amount, '100.00');
      expect(page.items.single.refundedAmount, '25.00');
      expect(page.hasMore, isFalse);
    });

    test('a zero refund is not a refund', () {
      final page = MerchantPaymentHistoryPage.fromJson({
        'items': [
          {'id': '1', 'status': 'PAID', 'amount': '10.00', 'refundedAmount': '0.00'},
        ],
        'total': 1,
        'page': 0,
        'limit': 20,
      });
      expect(page.items.single.hasRefund, isFalse);
    });

    test('paging follows total, page and limit', () {
      final page = MerchantPaymentHistoryPage.fromJson({
        'items': [],
        'total': 45,
        'page': 0,
        'limit': 20,
      });
      expect(page.hasMore, isTrue);
    });
  });

  group('MerchantPaymentErrors', () {
    test('branches on the code, not on the message', () {
      // Same 403, two very different outcomes — only `code` separates them.
      expect(
        MerchantPaymentErrors.classifyPayment(
          _failure(statusCode: 403, code: 'KYC_REQUIRED'),
        ),
        MerchantPaymentFailure.kycRequired,
      );
      expect(
        MerchantPaymentErrors.classifyPayment(
          _failure(statusCode: 403, code: 'PAYER_NOT_ALLOWED'),
        ),
        MerchantPaymentFailure.payerNotAllowed,
      );
    });

    test('a 403 with no code defers to the server message', () {
      final failure = MerchantPaymentErrors.classifyPayment(
        _failure(statusCode: 403, message: 'Not allowed'),
      );
      expect(failure, MerchantPaymentFailure.forbidden);
      expect(MerchantPaymentErrors.messageKey(failure), isNull);
    });

    test('maps the documented payment statuses', () {
      expect(
        MerchantPaymentErrors.classifyPayment(_failure(statusCode: 400)),
        MerchantPaymentFailure.insufficientBalance,
      );
      expect(
        MerchantPaymentErrors.classifyPayment(_failure(statusCode: 409)),
        MerchantPaymentFailure.alreadyPaid,
      );
    });

    test('maps the documented lookup statuses', () {
      expect(
        MerchantPaymentErrors.classifyLookup(_failure(statusCode: 404)),
        MerchantPaymentFailure.invalidCode,
      );
      expect(
        MerchantPaymentErrors.classifyLookup(_failure(statusCode: 429)),
        MerchantPaymentFailure.tooManyAttempts,
      );
    });

    test('a timeout is not a failure to show', () {
      final failure = MerchantPaymentErrors.classifyPayment(_timeout());
      expect(failure, MerchantPaymentFailure.noResponse);
      expect(MerchantPaymentErrors.messageKey(failure), isNull);
    });

    test('a lost connection is recognised as no response', () {
      expect(_timeout().isTimeoutOrConnectionLoss, isTrue);
      expect(_failure(statusCode: 409).isTimeoutOrConnectionLoss, isFalse);
    });

    test('code matching tolerates case and separator differences', () {
      expect(
        MerchantPaymentErrors.classifyPayment(
          _failure(statusCode: 500, code: 'insufficient-balance'),
        ),
        MerchantPaymentFailure.insufficientBalance,
      );
    });
  });

  group('TrydosWallet link entry point', () {
    tearDown(() {
      // The buffer is static: leave nothing behind for the next test.
      TrydosWallet.consumePendingPaymentCode();
    });

    test('buffers a code when the wallet UI is not listening yet', () {
      final accepted = TrydosWallet.handleIncomingLinkString(
        'https://pay.example.com/r/v1/mp.abc',
      );

      expect(accepted, isTrue);
      expect(TrydosWallet.consumePendingPaymentCode(), 'mp.abc');
      // Drained exactly once.
      expect(TrydosWallet.consumePendingPaymentCode(), isNull);
    });

    test('delivers to a listening wallet instead of buffering', () async {
      final received = <String>[];
      final subscription = TrydosWallet.paymentCodes.listen(received.add);
      addTearDown(subscription.cancel);

      final accepted = TrydosWallet.handleIncomingLink(
        Uri.parse('rdb://r/v1/4817302956'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(accepted, isTrue);
      expect(received, ['4817302956']);
      expect(TrydosWallet.consumePendingPaymentCode(), isNull);
    });

    test('ignores links that are not ours, so hosts can pass everything', () {
      expect(
        TrydosWallet.handleIncomingLinkString('https://example.com/promo/spring'),
        isFalse,
      );
      expect(TrydosWallet.handleIncomingLink(null), isFalse);
      expect(TrydosWallet.handlePaymentCode('0000-0030'), isFalse);
      expect(TrydosWallet.consumePendingPaymentCode(), isNull);
    });

    test('accepts a bare code from a notification payload', () {
      expect(TrydosWallet.handlePaymentCode(' 481 730 2956 '), isTrue);
      expect(TrydosWallet.consumePendingPaymentCode(), '4817302956');
    });

    test('the most recent buffered link wins', () {
      TrydosWallet.handlePaymentCode('mp.first');
      TrydosWallet.handlePaymentCode('mp.second');
      expect(TrydosWallet.consumePendingPaymentCode(), 'mp.second');
    });
  });

  group('MerchantPaymentResult', () {
    test('only PAID counts as paid', () {
      final processing = MerchantPaymentResult.fromJson({
        'status': 'PROCESSING',
        'paymentRequestId': '66f1',
        'amount': '100.00',
      });
      expect(processing.isPaid, isFalse);

      final paid = MerchantPaymentResult.fromJson({
        'status': 'PAID',
        'paymentRequestId': '66f1',
        'orderRef': 'ORD-10231',
        'merchantName': 'Al Salam Stores',
        'amount': '100.00',
        'assetSymbol': 'USD',
        'receiptNumber': 'RDB-R-2026-000123',
        'paidAt': '2026-10-01T09:14:03.118Z',
        'successUrl': 'https://shop.example.com/orders/10231/thanks',
      });
      expect(paid.isPaid, isTrue);
      expect(paid.receiptNumber, 'RDB-R-2026-000123');
      expect(paid.successUrl, 'https://shop.example.com/orders/10231/thanks');
    });
  });
}
