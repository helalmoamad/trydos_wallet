/// Response of `GET /api/kyc/status`.
///
/// Reflects the backend's current verification decision for the user. The
/// device never decides pass/fail — it just renders whatever lands here.
class KycStatusResponse {
  /// 'not_submitted' | 'pending' | 'verified' | 'rejected' | 'expired'
  final String status;

  /// Human-readable label for [status] (server-localized when provided).
  final String? statusLabel;

  /// Reason text when [status] == 'rejected'.
  final String? rejectionReason;

  /// Raw ISO-8601 expiry timestamp (nullable; usually null on this endpoint).
  final String? expiresAt;

  const KycStatusResponse({
    required this.status,
    this.statusLabel,
    this.rejectionReason,
    this.expiresAt,
  });

  /// Verified, under any of the names the backend uses for it.
  bool get isVerified =>
      status == 'verified' || status == 'approved' || status == 'passed';

  bool get isPending => status == 'pending';

  /// A verification that lapsed. Shown like a rejection — the user has to
  /// verify again — but it carries no [rejectionReason].
  bool get isExpired => status == 'expired';

  bool get isRejected => status == 'rejected';

  /// Nothing on file: never submitted, or a status this build does not know.
  /// Both lead to the same place — offer to start verification.
  bool get isNotSubmitted =>
      status == 'not_submitted' ||
      (!isVerified && !isPending && !isExpired && !isRejected);

  /// Whether the user should be offered the verification flow. Verified and
  /// pending users are sent home instead of into it.
  bool get canStartVerification => !isVerified && !isPending;

  factory KycStatusResponse.fromJson(Map<String, dynamic> json) {
    return KycStatusResponse(
      status: (json['status'] as String?)?.trim().toLowerCase() ?? '',
      statusLabel: json['statusLabel'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      expiresAt: json['expiresAt'] as String?,
    );
  }
}
