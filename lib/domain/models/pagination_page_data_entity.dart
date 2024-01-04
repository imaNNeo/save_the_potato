class PaginationPageDataEntity {
  final bool hasMore;
  final int total;

  PaginationPageDataEntity({
    required this.hasMore,
    required this.total,
  });

  Map<String, dynamic> toJson() => {
        'has_more': hasMore,
        'total': total,
      };

  factory PaginationPageDataEntity.fromJson(Map<String, dynamic> json) => PaginationPageDataEntity(
        hasMore: json['has_more'],
        total: json['total'],
      );
}
