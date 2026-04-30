/// Response model for POST /api/kyc/compare-face
class KycCompareFaceResponse {
  final String status; // "success" | "error"
  final double? matchScore;
  final String? message;
  final String? code; // "FACE_MISMATCH" | "FACE_NOT_DETECTED" | etc.

  const KycCompareFaceResponse({
    required this.status,
    this.matchScore,
    this.message,
    this.code,
  });

  bool get isSuccess => status == 'success';
  bool get isError => status == 'error';

  factory KycCompareFaceResponse.fromJson(Map<String, dynamic> json) {
    return KycCompareFaceResponse(
      status: (json['status'] as String?) ?? 'error',
      matchScore: (json['matchScore'] as num?)?.toDouble(),
      message: json['message'] as String?,
      code: json['code'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    if (matchScore != null) 'matchScore': matchScore,
    if (message != null) 'message': message,
    if (code != null) 'code': code,
  };
}
