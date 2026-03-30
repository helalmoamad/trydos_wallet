import 'currency_paytab.dart';

/// نموذج العملة.
class Currency {
  const Currency({
    required this.id,
    required this.assetType,
    required this.name,
    required this.displayName,
    required this.symbol,
    this.symbolImageUrl,
    this.nameEn,
    this.nameAr,
    this.paytab = const CurrencyPaytab(),
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    final parsedNames = _parseNames(json['name']);

    return Currency(
      id: json['id'] as String,
      assetType: (json['assetType'] as String? ?? 'CURRENCY').toUpperCase(),
      name: parsedNames.en,
      displayName: json['displayName'] as String? ?? parsedNames.ar,
      symbol: json['symbol'] as String? ?? '',
      symbolImageUrl: json['symbolImageUrl'] as String?,
      nameEn: parsedNames.en,
      nameAr: parsedNames.ar,
      paytab: json['paytab'] != null
          ? CurrencyPaytab.fromJson(json['paytab'] as Map<String, dynamic>)
          : const CurrencyPaytab(),
      deletedAt: json['deletedAt'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  final String id;
  final String assetType;
  final String name;
  final String displayName;
  final String symbol;
  final String? symbolImageUrl;
  final String? nameEn;
  final String? nameAr;
  final CurrencyPaytab paytab;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;

  String localizedName(String languageCode) {
    final normalized = languageCode.toLowerCase();
    final isArabic = normalized == 'ar' || normalized.startsWith('ar-');

    if (isArabic) {
      if ((nameAr ?? '').isNotEmpty) return nameAr!;
      if (displayName.isNotEmpty) return displayName;
      if ((nameEn ?? '').isNotEmpty) return nameEn!;
      if (name.isNotEmpty) return name;
      return symbol;
    }

    if ((nameEn ?? '').isNotEmpty) return nameEn!;
    if (name.isNotEmpty) return name;
    if ((nameAr ?? '').isNotEmpty) return nameAr!;
    if (displayName.isNotEmpty) return displayName;
    return symbol;
  }

  static _ParsedNames _parseNames(dynamic rawName) {
    if (rawName is Map<String, dynamic>) {
      final en = rawName['en'] as String? ?? '';
      final ar = rawName['ar'] as String? ?? '';
      return _ParsedNames(en: en, ar: ar);
    }

    if (rawName is String) {
      return _ParsedNames(en: rawName, ar: '');
    }

    return const _ParsedNames(en: '', ar: '');
  }
}

class _ParsedNames {
  const _ParsedNames({required this.en, required this.ar});

  final String en;
  final String ar;
}
