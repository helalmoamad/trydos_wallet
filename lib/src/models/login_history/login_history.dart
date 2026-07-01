/// Device details attached to a login-history entry.
class LoginHistoryDevice {
  const LoginHistoryDevice({
    this.userAgent,
    this.browser,
    this.browserVersion,
    this.device,
    this.operatingSystem,
  });

  factory LoginHistoryDevice.fromJson(Map<String, dynamic> json) {
    String? clean(dynamic v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return LoginHistoryDevice(
      userAgent: clean(json['userAgent']),
      browser: clean(json['browser']),
      browserVersion: clean(json['browserVersion']),
      device: clean(json['device']),
      operatingSystem: clean(json['operatingSystem']),
    );
  }

  final String? userAgent;
  final String? browser;
  final String? browserVersion;
  final String? device;
  final String? operatingSystem;

  /// Short readable label, e.g. "chrome 126.0 · android · mobile".
  String get label {
    final browserPart = [
      if (browser != null) browser!,
      if (browserVersion != null) browserVersion!,
    ].join(' ');
    final parts = [
      if (browserPart.isNotEmpty) browserPart,
      if (operatingSystem != null) operatingSystem!,
      if (device != null) device!,
    ];
    return parts.join(' · ');
  }
}

/// A single login attempt in `GET /users/me/login-history`.
class LoginHistoryItem {
  const LoginHistoryItem({
    required this.id,
    required this.userId,
    required this.status,
    required this.method,
    this.failureReason,
    this.failureReasonLabel,
    this.ipAddress,
    this.city,
    this.country,
    this.device,
    this.createdAt,
    this.updatedAt,
  });

  factory LoginHistoryItem.fromJson(Map<String, dynamic> json) {
    return LoginHistoryItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'unknown',
      method: json['method']?.toString() ?? 'unknown',
      failureReason: json['failureReason']?.toString(),
      failureReasonLabel: json['failureReasonLabel']?.toString(),
      ipAddress: json['ipAddress']?.toString(),
      city: json['city']?.toString(),
      country: json['country']?.toString(),
      device: json['device'] is Map
          ? LoginHistoryDevice.fromJson(
              Map<String, dynamic>.from(json['device'] as Map),
            )
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  final String id;
  final String userId;

  /// "success" | "failure".
  final String status;

  /// phone_otp · trydos_otp · session_complete · passcode · ip_verification ·
  /// qr · unknown.
  final String method;

  /// Present on failures only.
  final String? failureReason;

  /// Localized (per Accept-Language) failure text — display this on failures.
  final String? failureReasonLabel;
  final String? ipAddress;
  final String? city;
  final String? country;
  final LoginHistoryDevice? device;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isSuccess => status.toLowerCase() == 'success';
  bool get isFailure => status.toLowerCase() == 'failure';

  /// "Cairo · EG" when available.
  String get location {
    final parts = [
      if (city != null && city!.isNotEmpty) city!,
      if (country != null && country!.isNotEmpty) country!,
    ];
    return parts.join(' · ');
  }
}
