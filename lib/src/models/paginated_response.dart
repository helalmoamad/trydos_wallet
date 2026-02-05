/// استجابة صفحة مع pagination.
class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return PaginatedResponse(
      items: itemsJson.map((e) => fromJsonT(e)).toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 0,
      limit: json['limit'] as int? ?? 10,
      totalPages: json['totalPages'] as int? ?? 0,
      hasNext: json['hasNext'] as bool? ?? false,
      hasPrevious: json['hasPrevious'] as bool? ?? false,
    );
  }

  final List<T> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;
}
