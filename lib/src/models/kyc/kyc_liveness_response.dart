class KycLivenessMetrics {
  final double? yaw;
  final double? pitch;
  final double? roll;
  final double? brightness;
  final double? sharpness;
  final bool? eyesOpen;
  final double? eyesOpenConfidence;
  final bool? sunglasses;
  final double? confidence;
  final KycBoundingBox? boundingBox;

  const KycLivenessMetrics({
    this.yaw,
    this.pitch,
    this.roll,
    this.brightness,
    this.sharpness,
    this.eyesOpen,
    this.eyesOpenConfidence,
    this.sunglasses,
    this.confidence,
    this.boundingBox,
  });

  factory KycLivenessMetrics.fromJson(Map<String, dynamic> json) {
    final bboxRaw = json['boundingBox'];
    return KycLivenessMetrics(
      yaw: (json['yaw'] as num?)?.toDouble(),
      pitch: (json['pitch'] as num?)?.toDouble(),
      roll: (json['roll'] as num?)?.toDouble(),
      brightness: (json['brightness'] as num?)?.toDouble(),
      sharpness: (json['sharpness'] as num?)?.toDouble(),
      eyesOpen: json['eyesOpen'] as bool?,
      eyesOpenConfidence: (json['eyesOpenConfidence'] as num?)?.toDouble(),
      sunglasses: json['sunglasses'] as bool?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      boundingBox: bboxRaw is Map<String, dynamic>
          ? KycBoundingBox.fromJson(bboxRaw)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (yaw != null) 'yaw': yaw,
    if (pitch != null) 'pitch': pitch,
    if (roll != null) 'roll': roll,
    if (brightness != null) 'brightness': brightness,
    if (sharpness != null) 'sharpness': sharpness,
    if (eyesOpen != null) 'eyesOpen': eyesOpen,
    if (eyesOpenConfidence != null) 'eyesOpenConfidence': eyesOpenConfidence,
    if (sunglasses != null) 'sunglasses': sunglasses,
    if (confidence != null) 'confidence': confidence,
    if (boundingBox != null) 'boundingBox': boundingBox!.toJson(),
  };
}

class KycBoundingBox {
  final double? left;
  final double? top;
  final double? width;
  final double? height;

  const KycBoundingBox({this.left, this.top, this.width, this.height});

  factory KycBoundingBox.fromJson(Map<String, dynamic> json) {
    return KycBoundingBox(
      left: (json['left'] as num?)?.toDouble(),
      top: (json['top'] as num?)?.toDouble(),
      width: (json['width'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    if (left != null) 'left': left,
    if (top != null) 'top': top,
    if (width != null) 'width': width,
    if (height != null) 'height': height,
  };
}

class KycLivenessResponse {
  final bool isLive;
  final String? challengeStep;
  final String? faceImageData;
  final KycLivenessMetrics? metrics;
  final int? timestamp;

  const KycLivenessResponse({
    required this.isLive,
    this.challengeStep,
    this.faceImageData,
    this.metrics,
    this.timestamp,
  });

  factory KycLivenessResponse.fromJson(Map<String, dynamic> json) {
    final metricsRaw = json['metrics'];
    return KycLivenessResponse(
      isLive: json['isLive'] as bool? ?? false,
      challengeStep: json['challengeStep'] as String?,
      faceImageData: json['faceImageData'] as String?,
      metrics: metricsRaw is Map<String, dynamic>
          ? KycLivenessMetrics.fromJson(metricsRaw)
          : null,
      timestamp: json['timestamp'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'isLive': isLive,
    if (challengeStep != null) 'challengeStep': challengeStep,
    if (faceImageData != null) 'faceImageData': faceImageData,
    if (metrics != null) 'metrics': metrics!.toJson(),
    if (timestamp != null) 'timestamp': timestamp,
  };
}
