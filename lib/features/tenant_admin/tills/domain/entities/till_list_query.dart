class TillListQuery {
  const TillListQuery({
    this.search,
    this.page = 1,
    this.pageSize = 5,
    this.status,
    this.sortBy = 'name',
    this.sortDirection = 'asc',
  });

  final String? search;
  final int page;
  final int pageSize;
  final String? status;
  final String sortBy;
  final String sortDirection;
}
