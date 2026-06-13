import 'package:dio/dio.dart';

import '../api/api.dart';
import '../config/trydos_wallet_config.dart';
import '../models/kyc/kyc_analyze_id_response.dart';
import '../models/kyc/kyc_current_response.dart';
import '../models/kyc/kyc_session_response.dart';
import '../models/kyc/kyc_status_response.dart';

/// API service for KYC ID analysis (front/back).
class KycApiService {
  KycApiService({ApiClient? client})
    : _client = client ?? TrydosWallet.kycApiClient;

  final ApiClient _client;

  /// The user-authed onboarding routes (session / status / submit) accept the
  /// `rdb_at` cookie today; native apps have no cookie jar, so we attach it
  /// explicitly from the access token. The Bearer header (set on the client)
  /// is also sent, so this works whether the backend reads the cookie or the
  /// token.
  Options? _userAuthOptions() {
    final token = TrydosWallet.config.token;
    if (token == null || token.isEmpty) return null;
    return Options(headers: {'Cookie': 'rdb_at=$token'});
  }

  /// Start a single-use KYC onboarding session (user-authed).
  /// Must be called before submit; the returned `sessionId` is spent on a
  /// successful submit and `expiresAt` bounds how long the flow stays valid.
  Future<ApiResult<KycSessionResponse>> startSession() {
    return _client.post<KycSessionResponse>(
      ApiPaths.kycSession,
      options: _userAuthOptions(),
      fromJson: (d) =>
          KycSessionResponse.fromJson(Map<String, dynamic>.from(d as Map)),
    );
  }

  /// Current KYC verification status (user-authed). Source of truth for the
  /// verified/pending/rejected/not_submitted decision made by the backend.
  Future<ApiResult<KycStatusResponse>> getStatus() {
    return _client.get<KycStatusResponse>(
      ApiPaths.kycStatus,
      options: _userAuthOptions(),
      fromJson: (d) =>
          KycStatusResponse.fromJson(Map<String, dynamic>.from(d as Map)),
    );
  }

  /// Current verified KYC record/details (user-authed). Requested on entering
  /// settings when the user is verified.
  Future<ApiResult<KycCurrentResponse>> getCurrent() {
    return _client.get<KycCurrentResponse>(
      ApiPaths.kycCurrent,
      options: _userAuthOptions(),
      fromJson: (d) =>
          KycCurrentResponse.fromJson(Map<String, dynamic>.from(d as Map)),
    );
  }

  Future<ApiResult<KycAnalyzeIdResponse>> analyzeId({
    required String imageData,
    required String side,
    String? sessionHint,
  }) {
    return _client.post<KycAnalyzeIdResponse>(
      ApiPaths.kycAnalyzeId,
      data: {
        'imageData': imageData,
        'side': side,
        if (sessionHint != null && sessionHint.isNotEmpty)
          'sessionHint': sessionHint,
      },
      fromJson: (d) =>
          KycAnalyzeIdResponse.fromJson(Map<String, dynamic>.from(d as Map)),
    );
  }

  /// Submit the final KYC request (user-authed, Worker origin). Terminal step
  /// of the flow: the backend makes the approved/pending/rejected decision.
  Future<ApiResult<Map<String, dynamic>>> submitKyc({
    required Map<String, dynamic> payload,
  }) {
    return _client.post<Map<String, dynamic>>(
      ApiPaths.kycSubmit,
      data: payload,
      options: _userAuthOptions(),
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
  }
}
