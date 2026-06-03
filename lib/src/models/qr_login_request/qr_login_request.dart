class WalletQrLoginRequest {
  const WalletQrLoginRequest({
    required this.linkId,
    required this.browser,
    required this.os,
    required this.sameCity,
    this.webCity,
    this.appCity,
    this.expiresAt,
  });

  factory WalletQrLoginRequest.fromJson(Map<String, dynamic> json) {
    final webData = json['web'] as Map<String, dynamic>?;

    return WalletQrLoginRequest(
      linkId: json['linkId']?.toString() ?? '',
      browser: webData?['browser']?.toString() ?? 'Unknown',
      os: webData?['os']?.toString() ?? 'Unknown',
      sameCity: json['sameCity'] == true,
      webCity: json['webCity']?.toString(),
      appCity: json['appCity']?.toString(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'].toString())
          : null,
    );
  }

  final String linkId;
  final String browser;
  final String os;
  final bool sameCity;
  final String? webCity;
  final String? appCity;
  final DateTime? expiresAt;
}
