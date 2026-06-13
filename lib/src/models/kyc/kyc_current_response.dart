/// Nationality country sub-object inside the KYC record.
class KycNationalityCountry {
  final String? id;
  final String? name;
  final String? displayName;
  final String? code;
  final String? flagImageUrl;

  const KycNationalityCountry({
    this.id,
    this.name,
    this.displayName,
    this.code,
    this.flagImageUrl,
  });

  factory KycNationalityCountry.fromJson(Map<String, dynamic> json) {
    return KycNationalityCountry(
      id: json['_id'] as String?,
      name: json['name'] as String?,
      displayName: json['displayName'] as String?,
      code: json['code'] as String?,
      flagImageUrl: json['flagImageUrl'] as String?,
    );
  }
}

/// Response of `GET /api/kyc/current` — the verified user's KYC record.
///
/// The server nests the record under `kycRequest` (sometimes doubly:
/// `kycRequest.kycRequest`); [fromJson] unwraps to the actual record.
class KycCurrentResponse {
  final String? id;
  final String? userId;
  final String? fullName;
  final String? documentType;
  final String? documentFrontImageUrl;
  final String? documentBackImageUrl;
  final String? selfieImageUrl;
  final String? nationalIdNumber;
  final String? status;
  final String? rejectionReason;
  final double? selfieVsIdScore;
  final double? livenessConfidence;
  final String? kycSessionId;
  final DateTime? decidedAt;
  final DateTime? expiresAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final KycNationalityCountry? nationalityCountry;

  const KycCurrentResponse({
    this.id,
    this.userId,
    this.fullName,
    this.documentType,
    this.documentFrontImageUrl,
    this.documentBackImageUrl,
    this.selfieImageUrl,
    this.nationalIdNumber,
    this.status,
    this.rejectionReason,
    this.selfieVsIdScore,
    this.livenessConfidence,
    this.kycSessionId,
    this.decidedAt,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
    this.nationalityCountry,
  });

  factory KycCurrentResponse.fromJson(Map<String, dynamic> json) {
    // Unwrap any nested `kycRequest` layers down to the actual record.
    Map<String, dynamic> node = json;
    while (node['kycRequest'] is Map) {
      node = Map<String, dynamic>.from(node['kycRequest'] as Map);
    }

    DateTime? parseDate(dynamic v) {
      final s = v?.toString();
      if (s == null || s.isEmpty) return null;
      return DateTime.tryParse(s)?.toLocal();
    }

    final country = node['nationalityCountry'];

    return KycCurrentResponse(
      id: node['_id'] as String?,
      userId: node['userId'] as String?,
      fullName: node['fullName'] as String?,
      documentType: node['documentType'] as String?,
      documentFrontImageUrl: node['documentFrontImageUrl'] as String?,
      documentBackImageUrl: node['documentBackImageUrl'] as String?,
      selfieImageUrl: node['selfieImageUrl'] as String?,
      nationalIdNumber: node['nationalIdNumber'] as String?,
      status: node['status'] as String?,
      rejectionReason: node['rejectionReason'] as String?,
      selfieVsIdScore: (node['selfieVsIdScore'] as num?)?.toDouble(),
      livenessConfidence: (node['livenessConfidence'] as num?)?.toDouble(),
      kycSessionId: node['kycSessionId'] as String?,
      decidedAt: parseDate(node['decidedAt']),
      expiresAt: parseDate(node['expiresAt']),
      createdAt: parseDate(node['createdAt']),
      updatedAt: parseDate(node['updatedAt']),
      nationalityCountry: country is Map
          ? KycNationalityCountry.fromJson(Map<String, dynamic>.from(country))
          : null,
    );
  }
}
