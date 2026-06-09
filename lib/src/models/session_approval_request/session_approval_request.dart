/// طلب الموافقة على تسجيل دخول جلسة (يصل عبر WebSocket: session:approval_request).
class SessionApprovalRequest {
  const SessionApprovalRequest({
    required this.requestId,
    this.ipAddress,
    this.deviceInfo,
    this.expiresAt,
  });

  factory SessionApprovalRequest.fromJson(Map<String, dynamic> json) {
    return SessionApprovalRequest(
      // Accept requestId, or fall back to id/_id used by some payloads.
      requestId:
          (json['requestId'] ?? json['id'] ?? json['_id'])?.toString() ?? '',
      ipAddress: (json['ipAddress']?.toString().trim().isEmpty ?? true)
          ? null
          : json['ipAddress'].toString().trim(),
      deviceInfo: _deviceInfoLabel(
        json['deviceInfo'] ?? json['title'] ?? json['subtitle'],
      ),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
    );
  }

  final String requestId;
  final String? ipAddress;
  final String? deviceInfo;
  final DateTime? expiresAt;

  /// عنوان عرض مختصر للجهاز/الموقع.
  String get displaySource {
    final parts = [
      if (deviceInfo != null && deviceInfo!.isNotEmpty) deviceInfo!,
      if (ipAddress != null && ipAddress!.isNotEmpty) ipAddress!,
    ];
    return parts.isEmpty ? 'Unknown device' : parts.join(' · ');
  }

  /// يبني وصفًا مقروءًا للجهاز سواء وصل كنص أو كائن.
  static String? _deviceInfoLabel(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final parts =
          [
                map['browser'],
                map['os'],
                map['deviceName'],
                map['name'],
                map['platform'],
              ]
              .where((e) => e != null && e.toString().trim().isNotEmpty)
              .map((e) => e.toString().trim())
              .toList();
      if (parts.isNotEmpty) return parts.join(' · ');
      return map.toString();
    }
    return value.toString();
  }
}
