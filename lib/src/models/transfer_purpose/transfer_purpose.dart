class TransferPurpose {
  const TransferPurpose({required this.id, required this.name});

  factory TransferPurpose.fromJson(Map<String, dynamic> json) {
    return TransferPurpose(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  final String id;
  final String name;
}
