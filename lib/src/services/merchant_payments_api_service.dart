import 'package:dio/dio.dart';

import '../api/api.dart';
import '../config/trydos_wallet_config.dart';
import '../models/models.dart';

/// The customer side of paying a merchant.
///
/// Three endpoints, all with the normal user access token — exactly like every
/// other screen in the wallet:
///
/// * [resolveCode] — the scanner. Resolves a peer **or** a merchant code.
/// * [payMerchantPayment] — pay it.
/// * [fetchMyMerchantPayments] — history, with receipts and refunds.
///
/// Everything else under `/merchant/…` — creating, cancelling and refunding
/// requests — belongs to the shop's own server and is authenticated with a
/// signature rather than a login. This client never calls those routes, and
/// never signs anything.
class MerchantPaymentsApiService {
  MerchantPaymentsApiService({ApiClient? client})
    : _client = client ?? TrydosWallet.apiClient;

  final ApiClient _client;

  /// Language headers the backend uses to localize `message` in error bodies.
  Options? _languageOptions(String? languageCode) {
    final lang = (languageCode ?? '').trim();
    if (lang.isEmpty) return null;
    return Options(headers: {'Accept-Language': lang, 'x-lang': lang});
  }

  /// Resolves a scanned or typed code into whatever it turned out to be.
  ///
  /// This is the single entry point for the scanner: pass whatever was read and
  /// branch on [PaymentCodeResolution.kind]. Do not pre-classify the code to
  /// pick an endpoint — the server owns that routing.
  ///
  /// Callers should reject a string in no known namespace *before* calling
  /// this (see `PaymentCode.isResolvable`): failed lookups are throttled at 10
  /// per 15 minutes, and a stray scan should not spend one of those attempts.
  Future<ApiResult<PaymentCodeResolution>> resolveCode({
    required String code,
    String? languageCode,
  }) {
    return _client.get<PaymentCodeResolution>(
      ApiPaths.lookupPaymentRequest(code),
      options: _languageOptions(languageCode),
      fromJson: (d) => PaymentCodeResolution.fromJson(d as Map<String, dynamic>),
    );
  }

  /// The merchant-only resolver.
  ///
  /// [resolveCode] already delegates to it, so reach for this only when the
  /// code is known to be a merchant one — for example when re-checking a
  /// request whose id the app is already holding.
  Future<ApiResult<MerchantPaymentLookup>> lookupMerchantPayment({
    required String code,
    String? languageCode,
  }) {
    return _client.get<MerchantPaymentLookup>(
      ApiPaths.lookupMerchantPayment(code),
      options: _languageOptions(languageCode),
      fromJson: (d) => merchantLookupFromJson(d as Map<String, dynamic>),
    );
  }

  /// Pays a merchant payment request. Requires verified KYC.
  ///
  /// [idempotencyKey] must be **the same key on every retry of the same
  /// payment**, and must never be reused for a different one. A retry after a
  /// timeout returns the original receipt instead of debiting the customer a
  /// second time — which is why a lost response is retried rather than
  /// reported as a failure.
  ///
  /// [accountNumber] names the wallet to debit. It is chosen to match the
  /// request's own asset; omitting it lets the backend fall back to the MAIN
  /// wallet.
  Future<ApiResult<MerchantPaymentResult>> payMerchantPayment({
    required String paymentId,
    required String idempotencyKey,
    String? accountNumber,
    String? languageCode,
  }) {
    final data = <String, dynamic>{'idempotencyKey': idempotencyKey};

    final account = (accountNumber ?? '').trim();
    if (account.isNotEmpty) {
      data['accountNumber'] = account;
    }

    return _client.post<MerchantPaymentResult>(
      ApiPaths.payMerchantPayment(paymentId),
      data: data,
      options: _languageOptions(languageCode),
      fromJson: (d) => MerchantPaymentResult.fromJson(d as Map<String, dynamic>),
    );
  }

  /// History of merchant payments, newest first, with receipts and refunds.
  ///
  /// [page] is 0-indexed and [limit] is clamped to the API's 1–100 range.
  Future<ApiResult<MerchantPaymentHistoryPage>> fetchMyMerchantPayments({
    int page = 0,
    int limit = 20,
    String? languageCode,
  }) {
    final safePage = page < 0 ? 0 : page;
    final safeLimit = limit < 1
        ? 1
        : limit > 100
        ? 100
        : limit;

    return _client.get<MerchantPaymentHistoryPage>(
      ApiPaths.myMerchantPayments,
      queryParameters: {'page': safePage, 'limit': safeLimit},
      options: _languageOptions(languageCode),
      fromJson: (d) =>
          MerchantPaymentHistoryPage.fromJson(d as Map<String, dynamic>),
    );
  }
}
