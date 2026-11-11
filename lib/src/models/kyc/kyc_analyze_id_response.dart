class KycExtractedData {
  final String? idType;
  final String? idName;
  final String? country;

  /// ISO-3166 alpha-3 country code, when the server resolved one.
  ///
  /// The Textract path sets it; the Syrian / Turkish / Lebanese parser paths
  /// set [country] only. Submit it whenever it is present — the backend falls
  /// back to matching the country name, which is weaker.
  final String? countryIso3;

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
    this.countryIso3,
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
      countryIso3: json['countryIso3'] as String?,
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
    if (countryIso3 != null) 'countryIso3': countryIso3,
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

  /// Which critical fields the OCR could not read, when [code] is
  /// `MISSING_CRITICAL_DATA` — e.g. `['firstName','birthday']`. Branch on this
  /// rather than on the message text.
  final List<String> missingFields;

  const KycAnalyzeIdResponse({
    required this.status,
    this.nextStep,
    this.side,
    this.croppedImageData,
    this.idFaceImageData,
    this.extractedData,
    this.code,
    this.message,
    this.missingFields = const [],
  });

  bool get isSuccess => status == 'success';
  bool get isError => status == 'error';
  bool get isNotFound => status == 'not_found';

  /// A passport: the front alone completes the document, so no back is asked
  /// for and `backImageData` is omitted at submit.
  bool get isPassport => nextStep == 'COMPLETE' && side != 'back';

  /// Whether this front result carries the photo cropped from the ID.
  ///
  /// The server only returns it when it actually found a face. A front without
  /// it cannot be face-matched, so it is treated as a rejection rather than
  /// passed on — see [frontMissingIdFace].
  bool get hasIdFace => (idFaceImageData?.isNotEmpty ?? false);

  /// A front that succeeded but shows no face — the user photographed the
  /// wrong side, or the photo page of a passport was not open.
  ///
  /// Sending the whole card to compare-face instead would spend a liveness
  /// attempt and come back `FACE_NOT_DETECTED` much later.
  bool get frontMissingIdFace => isSuccess && side != 'back' && !hasIdFace;

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
      missingFields: (json['missingFields'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(growable: false),
    );
  }
}
