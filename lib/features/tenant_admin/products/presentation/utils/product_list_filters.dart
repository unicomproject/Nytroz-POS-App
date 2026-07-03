enum ProductStatusFilter {
  all,
  active,
  inactive,
  draft,
}

extension ProductStatusFilterX on ProductStatusFilter {
  String? get apiStatus {
    switch (this) {
      case ProductStatusFilter.all:
        return null;
      case ProductStatusFilter.active:
        return 'active';
      case ProductStatusFilter.inactive:
        return 'inactive';
      case ProductStatusFilter.draft:
        return 'draft';
    }
  }

  String get label {
    switch (this) {
      case ProductStatusFilter.all:
        return 'All';
      case ProductStatusFilter.active:
        return 'Active';
      case ProductStatusFilter.inactive:
        return 'Inactive';
      case ProductStatusFilter.draft:
        return 'Draft';
    }
  }
}
