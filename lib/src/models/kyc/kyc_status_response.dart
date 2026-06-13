/// Response of `GET /api/kyc/status`.
///
/// Reflects the backend's current verification decision for the user. The
/// device never decides pass/fail — it just renders whatever lands here.
class KycStatusResponse {
  /// 'verified' | 'pending' | 'rejected' | 'not_submitted'
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

  bool get isVerified => status == 'verified';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
  bool get isNotSubmitted => status == 'not_submitted';

  factory KycStatusResponse.fromJson(Map<String, dynamic> json) {
    return KycStatusResponse(
      status: (json['status'] as String?)?.trim().toLowerCase() ?? '',
      statusLabel: json['statusLabel'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      expiresAt: json['expiresAt'] as String?,
    );
  }
}
