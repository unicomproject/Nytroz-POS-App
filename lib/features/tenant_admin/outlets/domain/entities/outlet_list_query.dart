class OutletListQuery {
  const OutletListQuery({
    this.search,
    this.page = 1,
    this.pageSize = 10,
    this.status,
    this.outletType,
    this.sortBy = 'name',
    this.sortDirection = 'asc',
  });

  final String? search;
  final int page;
  final int pageSize;
  final String? status;
  final String? outletType;
  final String sortBy;
  final String sortDirection;

  OutletListQuery copyWith({
    String? search,
    int? page,
    int? pageSize,
    String? status,
    String? outletType,
    String? sortBy,
    String? sortDirection,
    bool clearStatus = false,
    bool clearOutletType = false,
  }) {
    return OutletListQuery(
      search: search ?? this.search,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      status: clearStatus ? null : status ?? this.status,
      outletType: clearOutletType ? null : outletType ?? this.outletType,
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
    );
  }
}
