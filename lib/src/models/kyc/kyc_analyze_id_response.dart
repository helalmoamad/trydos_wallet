class KycExtractedData {
  final String? idType;
  final String? idName;
  final String? country;
  final String? name;
  final String? nationalNumber;
  final String? birthday;
  final String? firstName;
  final String? lastName;
  final String? documentNumber;
  final String? expiryDate;

  const KycExtractedData({
    this.idType,
    this.idName,
    this.country,
    this.name,
    this.nationalNumber,
    this.birthday,
    this.firstName,
    this.lastName,
    this.documentNumber,
    this.expiryDate,
  });

  factory KycExtractedData.fromJson(Map<String, dynamic> json) {
    return KycExtractedData(
      idType: json['idType'] as String?,
      idName: json['idName'] as String?,
      country: json['country'] as String?,
      name: json['name'] as String?,
      nationalNumber: json['nationalNumber'] as String?,
      birthday: json['birthday'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      documentNumber: json['documentNumber'] as String?,
      expiryDate: json['expiryDate'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (idType != null) 'idType': idType,
    if (idName != null) 'idName': idName,
    if (country != null) 'country': country,
    if (name != null) 'name': name,
    if (nationalNumber != null) 'nationalNumber': nationalNumber,
    if (birthday != null) 'birthday': birthday,
    if (firstName != null) 'firstName': firstName,
    if (lastName != null) 'lastName': lastName,
    if (documentNumber != null) 'documentNumber': documentNumber,
    if (expiryDate != null) 'expiryDate': expiryDate,
  };
}

class KycAnalyzeIdResponse {
  /// 'success' | 'error' | 'not_found'
  final String status;

  /// 'REQUIRE_BACK' | 'COMPLETE' (only on success)
  final String? nextStep;

  /// 'front' | 'back'
  final String? side;

  /// Base64 data URL of the cropped ID image (on success)
  final String? croppedImageData;

  /// Base64 data URL of the face extracted from the ID (front success only)
  final String? idFaceImageData;

  /// Extracted text fields (front success only)
  final KycExtractedData? extractedData;

  /// Error code e.g. 'MISSING_CRITICAL_DATA', 'INVALID_ID_TYPE' (on error)
  final String? code;

  /// Human-readable error message (on error)
  final String? message;

  const KycAnalyzeIdResponse({
    required this.status,
    this.nextStep,
    this.side,
    this.croppedImageData,
    this.idFaceImageData,
    this.extractedData,
    this.code,
    this.message,
  });

  bool get isSuccess => status == 'success';
  bool get isError => status == 'error';
  bool get isNotFound => status == 'not_found';

  factory KycAnalyzeIdResponse.fromJson(Map<String, dynamic> json) {
    final extractedRaw = json['extractedData'];
    return KycAnalyzeIdResponse(
      status: (json['status'] as String?) ?? '',
      nextStep: json['nextStep'] as String?,
      side: json['side'] as String?,
      croppedImageData: json['croppedImageData'] as String?,
      idFaceImageData: json['idFaceImageData'] as String?,
      extractedData: extractedRaw is Map<String, dynamic>
          ? KycExtractedData.fromJson(extractedRaw)
          : null,
      code: json['code'] as String?,
      message: json['message'] as String?,
    );
  }
}
