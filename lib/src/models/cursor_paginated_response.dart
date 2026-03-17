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
    this.page,
    this.totalPages,
  });

  factory CursorPaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    final page = json['page'] as int?;
    final hasNextPage =
        json['hasNextPage'] as bool? ?? json['hasNext'] as bool? ?? false;
    return CursorPaginatedResponse(
      items: itemsJson.map((e) => fromJsonT(e)).toList(),
      startCursor: json['startCursor'] as String?,
      endCursor:
          json['endCursor'] as String? ??
          json['cursor'] as String? ??
          (hasNextPage && page != null ? (page + 1).toString() : null),
      limit: json['limit'] as int? ?? 10,
      hasNextPage: hasNextPage,
      hasPreviousPage:
          json['hasPreviousPage'] as bool? ??
          json['hasPrevious'] as bool? ??
          false,
      total: json['total'] as int? ?? 0,
      page: page,
      totalPages: json['totalPages'] as int?,
    );
  }

  final List<T> items;
  final String? startCursor;
  final String? endCursor;
  final int limit;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final int total;
  final int? page;
  final int? totalPages;
}
