import 'currency_paytab.dart';

/// نموذج العملة.
class Currency {
  const Currency({
    required this.id,
    required this.name,
    required this.displayName,
    required this.symbol,
    this.symbolImageUrl,
    this.paytab = const CurrencyPaytab(),
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '',
      symbolImageUrl: json['symbolImageUrl'] as String?,
      paytab: json['paytab'] != null
          ? CurrencyPaytab.fromJson(json['paytab'] as Map<String, dynamic>)
          : const CurrencyPaytab(),
      deletedAt: json['deletedAt'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  final String id;
  final String name;
  final String displayName;
  final String symbol;
  final String? symbolImageUrl;
  final CurrencyPaytab paytab;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;
}
