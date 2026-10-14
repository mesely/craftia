class Paged<T> {
  const Paged({
    required this.items,
    required this.total,
    required this.page,
    required this.hasMore,
  });

  final List<T> items;
  final int total;
  final int page;
  final bool hasMore;
}
