import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A payment attempt that was started but never confirmed.
class PendingMerchantPayment {
  const PendingMerchantPayment({
    required this.paymentId,
    required this.idempotencyKey,
    required this.merchantName,
    required this.amount,
    required this.assetSymbol,
    required this.startedAt,
    this.accountNumber,
  });

  final String paymentId;

  /// The key the attempt used. Reusing it is the whole point of this record:
  /// retrying with it returns the original receipt instead of paying twice.
  final String idempotencyKey;

  final String merchantName;
  final String amount;
  final String assetSymbol;
  final DateTime startedAt;
  final String? accountNumber;

  Map<String, dynamic> toJson() => {
    'paymentId': paymentId,
    'idempotencyKey': idempotencyKey,
    'merchantName': merchantName,
    'amount': amount,
    'assetSymbol': assetSymbol,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'accountNumber': accountNumber,
  };

  static PendingMerchantPayment? fromJson(Map<String, dynamic> json) {
    String text(dynamic value) => value?.toString().trim() ?? '';

    final paymentId = text(json['paymentId']);
    final idempotencyKey = text(json['idempotencyKey']);
    if (paymentId.isEmpty || idempotencyKey.isEmpty) return null;

    final account = text(json['accountNumber']);
    return PendingMerchantPayment(
      paymentId: paymentId,
      idempotencyKey: idempotencyKey,
      merchantName: text(json['merchantName']),
      amount: text(json['amount']),
      assetSymbol: text(json['assetSymbol']),
      startedAt:
          DateTime.tryParse(text(json['startedAt']))?.toLocal() ??
          DateTime.now(),
      accountNumber: account.isEmpty ? null : account,
    );
  }
}

/// Survives the app being killed in the middle of a payment.
///
/// A payment that times out is the case that matters most in this flow: the
/// money may have moved even though no response came back. The attempt — and
/// above all its idempotency key — is written here *before* the network call,
/// so that the next launch can reconcile with the server before telling the
/// customer anything.
///
/// The record is cleared as soon as the outcome is known, whichever way it
/// went.
abstract class PendingMerchantPaymentStore {
  PendingMerchantPaymentStore._();

  static const String _key = 'trydos_wallet_pending_merchant_payment';

  /// Attempts older than this are abandoned rather than reconciled: the
  /// customer has long since seen the result in their history, and a stale
  /// "checking your payment" on launch would only confuse them.
  static const Duration maxAge = Duration(hours: 24);

  static Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (e) {
      debugPrint('[TrydosWallet] pending payment store unavailable: $e');
      return null;
    }
  }

  /// Records an attempt about to be made. Call this *before* the pay request.
  static Future<void> save(PendingMerchantPayment payment) async {
    final prefs = await _prefs();
    if (prefs == null) return;
    try {
      await prefs.setString(_key, jsonEncode(payment.toJson()));
    } catch (e) {
      debugPrint('[TrydosWallet] could not persist pending payment: $e');
    }
  }

  /// The unresolved attempt, if there is one and it is still recent.
  static Future<PendingMerchantPayment?> read() async {
    final prefs = await _prefs();
    if (prefs == null) return null;

    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;

    PendingMerchantPayment? pending;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        pending = PendingMerchantPayment.fromJson(decoded);
      }
    } catch (e) {
      debugPrint('[TrydosWallet] discarding unreadable pending payment: $e');
    }

    if (pending == null) {
      await clear();
      return null;
    }

    if (DateTime.now().difference(pending.startedAt) > maxAge) {
      await clear();
      return null;
    }

    return pending;
  }

  /// Drops the record once the outcome is known — paid, refused or abandoned.
  static Future<void> clear() async {
    final prefs = await _prefs();
    if (prefs == null) return;
    try {
      await prefs.remove(_key);
    } catch (e) {
      debugPrint('[TrydosWallet] could not clear pending payment: $e');
    }
  }
}
