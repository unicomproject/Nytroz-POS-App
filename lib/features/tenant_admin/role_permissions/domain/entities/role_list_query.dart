class RoleListQuery {
  const RoleListQuery({
    this.page = 1,
    this.pageSize = 5,
    this.search,
    this.status,
  });

  final int page;
  final int pageSize;
  final String? search;
  final String? status;

  RoleListQuery copyWith({
    int? page,
    int? pageSize,
    String? search,
    String? status,
  }) {
    return RoleListQuery(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search != null ? (search.isEmpty ? null : search) : this.search,
      status: status != null ? (status.isEmpty ? null : status) : this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is RoleListQuery &&
      other.page == page &&
      other.pageSize == pageSize &&
      other.search == search &&
      other.status == status;
  }

  @override
  int get hashCode {
    return page.hashCode ^
      pageSize.hashCode ^
      search.hashCode ^
      status.hashCode;
  }
}
