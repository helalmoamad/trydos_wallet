/// إعدادات PayTab للعملة.
class CurrencyPaytabFees {
  const CurrencyPaytabFees({
    this.enabled = false,
    this.type = 'percentage',
    this.percentage = 0,
    this.fixedAmount = 0,
  });

  factory CurrencyPaytabFees.fromJson(Map<String, dynamic> json) {
    return CurrencyPaytabFees(
      enabled: json['enabled'] as bool? ?? false,
      type: json['type'] as String? ?? 'percentage',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      fixedAmount: (json['fixedAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  final bool enabled;
  final String type;
  final double percentage;
  final double fixedAmount;
}

/// إعدادات ضريبة PayTab.
class CurrencyPaytabTax {
  const CurrencyPaytabTax({
    this.enabled = false,
    this.type = 'percentage',
    this.percentage = 0,
    this.fixedAmount = 0,
  });

  factory CurrencyPaytabTax.fromJson(Map<String, dynamic> json) {
    return CurrencyPaytabTax(
      enabled: json['enabled'] as bool? ?? false,
      type: json['type'] as String? ?? 'percentage',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0,
      fixedAmount: (json['fixedAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  final bool enabled;
  final String type;
  final double percentage;
  final double fixedAmount;
}

/// إعدادات PayTab للعملة.
class CurrencyPaytab {
  const CurrencyPaytab({
    this.paytabEnabled = false,
    this.paytabFees = const CurrencyPaytabFees(),
    this.paytabTax = const CurrencyPaytabTax(),
  });

  factory CurrencyPaytab.fromJson(Map<String, dynamic> json) {
    return CurrencyPaytab(
      paytabEnabled: json['paytabEnabled'] as bool? ?? false,
      paytabFees: json['paytabFees'] != null
          ? CurrencyPaytabFees.fromJson(
              json['paytabFees'] as Map<String, dynamic>,
            )
          : const CurrencyPaytabFees(),
      paytabTax: json['paytabTax'] != null
          ? CurrencyPaytabTax.fromJson(
              json['paytabTax'] as Map<String, dynamic>,
            )
          : const CurrencyPaytabTax(),
    );
  }

  final bool paytabEnabled;
  final CurrencyPaytabFees paytabFees;
  final CurrencyPaytabTax paytabTax;
}
