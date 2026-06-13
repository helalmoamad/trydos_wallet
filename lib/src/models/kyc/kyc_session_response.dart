/// Response of `POST /api/kyc/session`.
///
/// Starts a single-use KYC onboarding session. The returned [sessionId] must
/// be sent at submit time; [expiresAt] (ISO-8601) marks when the session
/// expires and the in-app flow must be abandoned.
class KycSessionResponse {
  /// Server-issued session id (single-use — spent once `submit` succeeds).
  final String sessionId;

  /// Raw ISO-8601 expiry timestamp as returned by the server.
  final String? expiresAt;

  const KycSessionResponse({required this.sessionId, this.expiresAt});

  factory KycSessionResponse.fromJson(Map<String, dynamic> json) {
    return KycSessionResponse(
      sessionId: (json['sessionId'] as String?) ?? '',
      expiresAt: json['expiresAt'] as String?,
    );
  }

  /// Parsed expiry as a local [DateTime], or null when missing/unparseable.
  DateTime? get expiresAtDate {
    final raw = expiresAt;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }
}
