/// نموذج البنك.
class Bank {
  const Bank({
    required this.id,
    required this.name,
    this.description,
    this.code,
    this.swiftCode,
    this.depositAvailable = true,
    this.withdrawAvailable = true,
    this.isActive = true,
  });

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      code: json['code'] as String?,
      swiftCode: json['swiftCode'] as String?,
      depositAvailable: json['depositAvailable'] as bool? ?? true,
      withdrawAvailable: json['withdrawAvailable'] as bool? ?? true,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  final String id;
  final String name;
  final String? description;
  final String? code;
  final String? swiftCode;
  final bool depositAvailable;
  final bool withdrawAvailable;
  final bool isActive;

  /// اسم العرض مع الرمز إن وُجد.
  String get displayName =>
      code != null && code!.isNotEmpty ? '$name ($code)' : name;
}
