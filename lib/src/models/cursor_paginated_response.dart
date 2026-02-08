/// استجابة cursor-based pagination.
class CursorPaginatedResponse<T> {
  const CursorPaginatedResponse({
    required this.items,
    this.startCursor,
    this.endCursor,
    required this.limit,
    required this.hasNextPage,
    required this.hasPreviousPage,
    required this.total,
  });

  factory CursorPaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return CursorPaginatedResponse(
      items: itemsJson.map((e) => fromJsonT(e)).toList(),
      startCursor: json['startCursor'] as String?,
      endCursor: json['endCursor'] as String?,
      limit: json['limit'] as int? ?? 10,
      hasNextPage: json['hasNextPage'] as bool? ?? false,
      hasPreviousPage: json['hasPreviousPage'] as bool? ?? false,
      total: json['total'] as int? ?? 0,
    );
  }

  final List<T> items;
  final String? startCursor;
  final String? endCursor;
  final int limit;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final int total;
}
