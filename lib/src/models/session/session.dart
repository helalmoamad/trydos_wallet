class WalletSession {
  const WalletSession({
    required this.id,
    required this.platform,
    required this.deviceName,
    required this.browser,
    required this.os,
    required this.ipAddress,
    required this.lastActiveAt,
    required this.expiresAt,
    required this.status,
    required this.isCurrent,
  });

  factory WalletSession.fromJson(Map<String, dynamic> json) {
    final deviceInfo = json['deviceInfo'] as Map<String, dynamic>?;
    final id = json['_id']?.toString() ?? json['id']?.toString() ?? '';
    return WalletSession(
      id: id,
      platform: json['platform']?.toString() ?? 'unknown',
      deviceName:
          deviceInfo?['deviceName']?.toString() ??
          deviceInfo?['browser']?.toString() ??
          deviceInfo?['os']?.toString() ??
          'Unknown Device',
      browser: deviceInfo?['browser']?.toString() ?? '',
      os: deviceInfo?['os']?.toString() ?? '',
      ipAddress: json['ipAddress']?.toString() ?? 'Unknown IP',
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.tryParse(json['lastActiveAt'].toString())
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
      status: json['status']?.toString() ?? 'unknown',
      isCurrent: json['isCurrent'] == true || json['current'] == true,
    );
  }

  final String id;
  final String platform;
  final String deviceName;
  final String browser;
  final String os;
  final String ipAddress;
  final DateTime? lastActiveAt;
  final DateTime? expiresAt;
  final String status;
  final bool isCurrent;
}
