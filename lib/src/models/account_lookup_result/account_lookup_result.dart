class AccountLookupResult {
  const AccountLookupResult({
    required this.found,
    required this.accountNumber,
    required this.name,
  });

  factory AccountLookupResult.fromJson(Map<String, dynamic> json) {
    return AccountLookupResult(
      found: json['found'] as bool? ?? false,
      accountNumber: json['accountNumber'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  final bool found;
  final String accountNumber;
  final String name;
}
