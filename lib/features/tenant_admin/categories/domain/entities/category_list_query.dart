enum CategoryStatusFilter {
  all,
  active,
  inactive,
}

enum CategoryParentFilterKind {
  all,
  rootOnly,
  specific,
}

class CategoryParentFilter {
  const CategoryParentFilter({
    this.kind = CategoryParentFilterKind.all,
    this.parentCategoryId,
    this.parentCategoryName,
  });

  final CategoryParentFilterKind kind;
  final String? parentCategoryId;
  final String? parentCategoryName;

  static const all = CategoryParentFilter();

  CategoryParentFilter copyWith({
    CategoryParentFilterKind? kind,
    String? parentCategoryId,
    String? parentCategoryName,
  }) {
    return CategoryParentFilter(
      kind: kind ?? this.kind,
      parentCategoryId: parentCategoryId ?? this.parentCategoryId,
      parentCategoryName: parentCategoryName ?? this.parentCategoryName,
    );
  }
}

class CategoryListQuery {
  const CategoryListQuery({
    required this.search,
    required this.pageNumber,
    required this.pageSize,
    this.statusFilter = CategoryStatusFilter.all,
    this.parentFilter = CategoryParentFilter.all,
  });

  final String search;
  final int pageNumber;
  final int pageSize;
  final CategoryStatusFilter statusFilter;
  final CategoryParentFilter parentFilter;

  String? get statusValue {
    switch (statusFilter) {
      case CategoryStatusFilter.all:
        return null;
      case CategoryStatusFilter.active:
        return 'ACTIVE';
      case CategoryStatusFilter.inactive:
        return 'INACTIVE';
    }
  }

  bool get rootOnly => parentFilter.kind == CategoryParentFilterKind.rootOnly;

  String? get parentCategoryId {
    if (parentFilter.kind != CategoryParentFilterKind.specific) {
      return null;
    }
    return parentFilter.parentCategoryId;
  }
}
