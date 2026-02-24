/// Paginated Response Model
///
/// Generic wrapper for all paginated API responses from the backend.
/// Matches the backend shape: `{ items, total_count, page, page_size, total_pages }`.
library;

/// A page of items returned by the catalog API.
class PaginatedResponse<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;
  final int totalPages;

  const PaginatedResponse({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  /// Build from JSON using a per-item deserializer.
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonItem,
  ) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return PaginatedResponse<T>(
      items: rawItems
          .map((e) => fromJsonItem(e as Map<String, dynamic>))
          .toList(),
      totalCount: (json['total_count'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? 20,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
    );
  }

  /// Whether there are more pages available.
  bool get hasMore => page < totalPages;

  /// Whether this is the first page.
  bool get isFirstPage => page == 1;
}
