import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/models.dart';
import '../utils/merchant_payment_errors.dart';
import 'merchant_payments_api_service.dart';
import 'pending_merchant_payment_store.dart';

/// The outcome of a payment attempt.
///
/// Note what is *not* here: there is no "probably paid". Every branch is
/// something the server said, or an explicit admission that the app does not
/// yet know — which is a different thing from failure, and must be shown
/// differently.
sealed class MerchantPaymentOutcome {
  const MerchantPaymentOutcome();
}

/// Paid, with the receipt in hand.
class MerchantPaymentPaid extends MerchantPaymentOutcome {
  const MerchantPaymentPaid(this.result);
  final MerchantPaymentResult result;
}

/// The money moved, but the receipt never reached us.
///
/// Reached when a response was lost and the follow-up lookup reports the
/// request as settled. The customer is told the payment went through and
/// pointed at their history for the receipt — never told it failed.
class MerchantPaymentPaidWithoutReceipt extends MerchantPaymentOutcome {
  const MerchantPaymentPaidWithoutReceipt(this.lookup);
  final MerchantPaymentLookup lookup;
}

/// The request cannot be paid any more — someone else paid it, it expired, or
/// the shop cancelled it. Carries the refreshed state when we could fetch it.
class MerchantPaymentNotPayable extends MerchantPaymentOutcome {
  const MerchantPaymentNotPayable(this.failure, {this.lookup, this.message});
  final MerchantPaymentFailure failure;
  final MerchantPaymentLookup? lookup;
  final String? message;
}

/// The customer must verify their identity first. Route into verification,
/// keeping a way back to this code.
class MerchantPaymentNeedsKyc extends MerchantPaymentOutcome {
  const MerchantPaymentNeedsKyc({this.message});
  final String? message;
}

/// The server refused, for a reason the customer can act on.
class MerchantPaymentRejected extends MerchantPaymentOutcome {
  const MerchantPaymentRejected(this.failure, {this.message});
  final MerchantPaymentFailure failure;
  final String? message;
}

/// The attempt did not go through, and the request is still payable.
///
/// Safe to offer "try again": the follow-up lookup confirmed the request is
/// still awaiting payment, so nothing was debited.
class MerchantPaymentNotCompleted extends MerchantPaymentOutcome {
  const MerchantPaymentNotCompleted({this.message});
  final String? message;
}

/// We genuinely do not know: no response, and the state could not be read back
/// either. The pending record is kept so the next launch reconciles it.
///
/// The customer must not be shown a failure here.
class MerchantPaymentUnresolved extends MerchantPaymentOutcome {
  const MerchantPaymentUnresolved();
}

/// Drives a single merchant payment, from confirmation screen to receipt.
///
/// One controller per confirmation screen, because one payment gets exactly one
/// idempotency key: [idempotencyKey] is generated when the controller is built
/// and never changes, so every retry of *this* payment reuses it and no other
/// payment can ever borrow it.
class MerchantPaymentController {
  MerchantPaymentController({
    MerchantPaymentsApiService? api,
    String? idempotencyKey,
  }) : _api = api ?? MerchantPaymentsApiService(),
       idempotencyKey = idempotencyKey ?? const Uuid().v4();

  final MerchantPaymentsApiService _api;

  /// The key for this payment. Generated once, held for the life of the screen,
  /// and sent on every retry.
  final String idempotencyKey;

  /// How many times a lost response is retried before falling back to
  /// reconciling against the server's state.
  static const int maxAttempts = 3;

  static const List<Duration> _backoff = [
    Duration(seconds: 2),
    Duration(seconds: 4),
  ];

  bool _inFlight = false;

  /// True while a pay call is running. A second tap must do nothing.
  bool get isInFlight => _inFlight;

  /// Pays [lookup] from [accountNumber].
  ///
  /// A lost response is retried with the same key — which returns the original
  /// receipt rather than debiting twice — and only then reconciled against a
  /// fresh lookup. Failure is reported only once the server has actually said
  /// so.
  Future<MerchantPaymentOutcome> pay({
    required MerchantPaymentLookup lookup,
    required String? accountNumber,
    String? languageCode,
  }) async {
    if (_inFlight) return const MerchantPaymentUnresolved();
    _inFlight = true;

    // Persist the attempt before the first call: if the app dies between here
    // and the response, the next launch still knows which key to reuse.
    await PendingMerchantPaymentStore.save(
      PendingMerchantPayment(
        paymentId: lookup.id,
        idempotencyKey: idempotencyKey,
        merchantName: lookup.merchantName,
        amount: lookup.amount,
        assetSymbol: lookup.assetSymbol,
        startedAt: DateTime.now(),
        accountNumber: accountNumber,
      ),
    );

    try {
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        final result = await _api.payMerchantPayment(
          paymentId: lookup.id,
          idempotencyKey: idempotencyKey,
          accountNumber: accountNumber,
          languageCode: languageCode,
        );

        if (result.isSuccess && result.data != null) {
          final payment = result.data!;
          if (payment.isPaid) {
            await PendingMerchantPaymentStore.clear();
            return MerchantPaymentPaid(payment);
          }
          // A 200 that is not PAID: PROCESSING, or a status this build does not
          // know. Never call that paid — read the server's state instead.
          return await _reconcile(
            lookup: lookup,
            languageCode: languageCode,
            keepPendingWhenUnknown: true,
          );
        }

        final failure = MerchantPaymentErrors.classifyPayment(result);

        if (failure == MerchantPaymentFailure.noResponse) {
          if (attempt < maxAttempts - 1) {
            await Future<void>.delayed(_backoff[attempt]);
            continue;
          }
          // Out of retries with no answer: ask the server what happened rather
          // than guessing.
          return await _reconcile(
            lookup: lookup,
            languageCode: languageCode,
            keepPendingWhenUnknown: true,
          );
        }

        // The server answered. Whatever it said, this attempt is resolved.
        await PendingMerchantPaymentStore.clear();
        return _outcomeForFailure(failure, result.errorMessage);
      }

      return const MerchantPaymentUnresolved();
    } finally {
      _inFlight = false;
    }
  }

  /// Reads the request back and turns its current state into an outcome.
  Future<MerchantPaymentOutcome> _reconcile({
    required MerchantPaymentLookup lookup,
    required String? languageCode,
    required bool keepPendingWhenUnknown,
  }) async {
    final refreshed = await _api.lookupMerchantPayment(
      code: lookup.id,
      languageCode: languageCode,
    );

    if (refreshed.isSuccess && refreshed.data != null) {
      final current = refreshed.data!;

      if (current.status.isSettled) {
        await PendingMerchantPaymentStore.clear();
        return MerchantPaymentPaidWithoutReceipt(current);
      }

      if (current.payable) {
        // Still awaiting payment: nothing was debited, so the customer can
        // safely try again.
        await PendingMerchantPaymentStore.clear();
        return const MerchantPaymentNotCompleted();
      }

      await PendingMerchantPaymentStore.clear();
      return MerchantPaymentNotPayable(
        MerchantPaymentFailure.notPayable,
        lookup: current,
      );
    }

    // Could not read the state either. Keep the pending record so the next
    // launch tries again, and say nothing about success or failure.
    if (!keepPendingWhenUnknown) {
      await PendingMerchantPaymentStore.clear();
    }
    return const MerchantPaymentUnresolved();
  }

  MerchantPaymentOutcome _outcomeForFailure(
    MerchantPaymentFailure failure,
    String? serverMessage,
  ) {
    switch (failure) {
      case MerchantPaymentFailure.kycRequired:
        return MerchantPaymentNeedsKyc(message: serverMessage);
      case MerchantPaymentFailure.alreadyPaid:
      case MerchantPaymentFailure.notPayable:
        return MerchantPaymentNotPayable(failure, message: serverMessage);
      case MerchantPaymentFailure.noResponse:
        return const MerchantPaymentUnresolved();
      default:
        return MerchantPaymentRejected(failure, message: serverMessage);
    }
  }

  /// Resolves an unfinished attempt left behind by a kill or a crash.
  ///
  /// Call this on launch, before any screen tells the customer their payment
  /// failed. Returns null when there was nothing pending.
  static Future<MerchantPaymentOutcome?> reconcilePendingAttempt({
    MerchantPaymentsApiService? api,
    String? languageCode,
  }) async {
    final pending = await PendingMerchantPaymentStore.read();
    if (pending == null) return null;

    final service = api ?? MerchantPaymentsApiService();

    // Retrying with the stored key is the cheapest way to learn the outcome:
    // if the original call did go through, this returns that same receipt.
    final retry = await service.payMerchantPayment(
      paymentId: pending.paymentId,
      idempotencyKey: pending.idempotencyKey,
      accountNumber: pending.accountNumber,
      languageCode: languageCode,
    );

    if (retry.isSuccess && retry.data != null && retry.data!.isPaid) {
      await PendingMerchantPaymentStore.clear();
      return MerchantPaymentPaid(retry.data!);
    }

    if (retry.isTimeoutOrConnectionLoss) {
      // Still offline. Leave the record for the next launch.
      return const MerchantPaymentUnresolved();
    }

    final current = await service.lookupMerchantPayment(
      code: pending.paymentId,
      languageCode: languageCode,
    );

    if (current.isSuccess && current.data != null) {
      await PendingMerchantPaymentStore.clear();
      final lookup = current.data!;
      if (lookup.status.isSettled) {
        return MerchantPaymentPaidWithoutReceipt(lookup);
      }
      return const MerchantPaymentNotCompleted();
    }

    if (kDebugMode) {
      debugPrint(
        '[TrydosWallet] pending merchant payment ${pending.paymentId} '
        'still unresolved',
      );
    }
    return const MerchantPaymentUnresolved();
  }
}
