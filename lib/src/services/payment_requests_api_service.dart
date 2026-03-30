import '../api/api.dart';
import '../config/trydos_wallet_config.dart';
import '../models/models.dart';
import 'package:dio/dio.dart';

/// API service for payment requests.
class PaymentRequestsApiService {
  PaymentRequestsApiService({ApiClient? client})
    : _client = client ?? TrydosWallet.apiClient;

  final ApiClient _client;

  Future<ApiResult<PaymentRequestLookupResponse>> lookupPaymentRequest({
    required String requestCode,
    String? languageCode,
  }) async {
    final headers = <String, String>{};
    if (languageCode != null && languageCode.isNotEmpty) {
      headers['Accept-Language'] = languageCode;
      headers['x-lang'] = languageCode;
    }

    return _client.get<PaymentRequestLookupResponse>(
      ApiPaths.lookupPaymentRequest(requestCode),
      options: headers.isEmpty ? null : Options(headers: headers),
      fromJson: (d) =>
          PaymentRequestLookupResponse.fromJson(d as Map<String, dynamic>),
    );
  }

  /// Create a payment request.
  Future<ApiResult<PaymentRequestResponse>> createPaymentRequest({
    required String accountNumber,
    required String assetType,
    required String assetSymbol,
    required double amount,
    required String purposeId,
    required String reference,
    String? note,
    int? expiryMinutes,
    bool isPermanent = false,
    required String idempotencyKey,
  }) async {
    final normalizedAssetType = assetType.toUpperCase() == 'METAL'
        ? 'METAL'
        : 'CURRENCY';

    final data = <String, dynamic>{
      'accountNumber': accountNumber,
      'assetType': normalizedAssetType,
      'assetSymbol': assetSymbol,
      'amount': amount,
      'purposeId': purposeId,
      'reference': reference,
      'isPermanent': isPermanent,
      'idempotencyKey': idempotencyKey,
    };

    if (note != null && note.isNotEmpty) {
      data['note'] = note;
    }

    if (expiryMinutes != null && expiryMinutes > 0) {
      data['expiryMinutes'] = expiryMinutes;
    }

    return _client.post<PaymentRequestResponse>(
      ApiPaths.paymentRequests,
      data: data,
      fromJson: (d) =>
          PaymentRequestResponse.fromJson(d as Map<String, dynamic>),
    );
  }

  /// Fulfill a payment request (pay).
  Future<ApiResult<PaymentRequestFulfillResponse>> fulfillPaymentRequest({
    required String requestId,
    required String accountNumber,
    required String idempotencyKey,
    String? note,
    String? languageCode,
  }) async {
    final data = <String, dynamic>{
      'accountNumber': accountNumber,
      'idempotencyKey': idempotencyKey,
    };

    if (note != null && note.trim().isNotEmpty) {
      data['note'] = note.trim();
    }

    final headers = <String, String>{};
    if (languageCode != null && languageCode.isNotEmpty) {
      headers['Accept-Language'] = languageCode;
      headers['x-lang'] = languageCode;
    }

    return _client.post<PaymentRequestFulfillResponse>(
      ApiPaths.fulfillPaymentRequest(requestId),
      data: data,
      options: headers.isEmpty ? null : Options(headers: headers),
      fromJson: (d) =>
          PaymentRequestFulfillResponse.fromJson(d as Map<String, dynamic>),
    );
  }
}
