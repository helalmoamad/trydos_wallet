/// نتيجة رفع الملف عبر API.
class MediaUploadResponse {
  const MediaUploadResponse({
    required this.id,
    required this.url,
    this.key,
    this.originalName,
    this.mimeType,
    this.size,
    this.type,
    this.uploaderId,
    this.uploaderType,
    this.metadata,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory MediaUploadResponse.fromJson(Map<String, dynamic> json) {
    return MediaUploadResponse(
      id: json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      key: json['key'] as String?,
      originalName: json['originalName'] as String?,
      mimeType: json['mimeType'] as String?,
      size: json['size'] as int?,
      type: json['type'] as String?,
      uploaderId: json['uploaderId'] as String?,
      uploaderType: json['uploaderType'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      deletedAt: json['deletedAt'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  final String id;
  final String url;
  final String? key;
  final String? originalName;
  final String? mimeType;
  final int? size;
  final String? type;
  final String? uploaderId;
  final String? uploaderType;
  final Map<String, dynamic>? metadata;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;
}
