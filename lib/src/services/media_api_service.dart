import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../api/api.dart';
import '../config/trydos_wallet_config.dart';
import '../models/models.dart';

/// خدمة API لرفع الملفات.
class MediaApiService {
  MediaApiService({ApiClient? client})
    : _client = client ?? TrydosWallet.apiClient;

  final ApiClient _client;

  /// رفع ملف مباشرة.
  /// [filePath] مسار الملف على الجهاز.
  /// [type] فئة الملف، مثل: image, document, video.
  /// [metadata] بيانات اختيارية (مثل purpose: deposit_proof).
  Future<ApiResult<MediaUploadResponse>> uploadDirect({
    required String filePath,
    required String type,
    Map<String, dynamic>? metadata,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return ApiResult.failure(
        DioException(
          requestOptions: RequestOptions(path: filePath),
          error: 'File not found',
        ),
      );
    }
    final fileName = filePath.split(RegExp(r'[/\\]')).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      'type': type,
      if (metadata != null) 'metadata': jsonEncode(metadata),
    });
    return _client.post<MediaUploadResponse>(
      ApiPaths.mediaUploadDirect,
      data: formData,
      fromJson: (d) => MediaUploadResponse.fromJson(d as Map<String, dynamic>),
    );
  }
}
