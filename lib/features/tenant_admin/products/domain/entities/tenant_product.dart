class TenantProduct {
  const TenantProduct({
    required this.id,
    required this.productCode,
    required this.name,
    required this.sku,
    required this.status,
    this.stockQuantity,
    this.stockStatus,
    this.categoryName,
    this.categoryId,
    this.brandId,
    this.brandName,
    this.variantCount = 1,
    this.priceFrom,
    this.priceTo,
    this.primaryBarcode,
    this.currencyCode,
    this.imageUrl,
    this.rowVersion = 1,
    this.isLocalDraft = false,
    this.productStructure,
  });

  final String id;
  final String productCode;
  final String name;
  final String sku;
  final String? primaryBarcode;
  final String? categoryName;
  final String? categoryId;
  final String? brandId;
  final String? brandName;
  final int variantCount;
  final double? priceFrom;
  final double? priceTo;
  final String? currencyCode;
  final int? stockQuantity;
  final String? stockStatus;
  final String status;
  final String? imageUrl;
  final int rowVersion;

  /// True when this row is a device-local wizard draft (not a backend Product).
  /// When true, [id] is [localDraftId], never a ProductId.
  final bool isLocalDraft;

  /// Product type when known (SIMPLE / VARIANT / BUNDLE). Local drafts only.
  final String? productStructure;
}

class TenantProductListResult {
  const TenantProductListResult({
    required this.items,
    this.page = 1,
    this.pageSize = 6,
    this.totalCount = 0,
    this.catalogTotalCount = 0,
  });

  final List<TenantProduct> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int catalogTotalCount;

  int get totalPages {
    if (pageSize <= 0 || totalCount <= 0) {
      return totalCount > 0 ? 1 : 0;
    }

    return (totalCount / pageSize).ceil();
  }

  int get rangeStart {
    if (totalCount == 0) {
      return 0;
    }

    return ((page - 1) * pageSize) + 1;
  }

  int get rangeEnd {
    if (totalCount == 0) {
      return 0;
    }

    return (page * pageSize).clamp(0, totalCount);
  }
}

class TenantProductListQuery {
  const TenantProductListQuery({
    this.search,
    this.pageNumber = 1,
    this.pageSize = 6,
    this.sortBy = 'productName',
    this.sortDirection = 'asc',
    this.categoryId,
    this.brandId,
    this.productStatus,
    this.stockStatus,
  });

  final String? search;
  final int pageNumber;
  final int pageSize;
  final String sortBy;
  final String sortDirection;
  final String? categoryId;
  final String? brandId;
  final String? productStatus;
  final String? stockStatus;

  TenantProductListQuery copyWith({
    String? search,
    int? pageNumber,
    int? pageSize,
    String? sortBy,
    String? sortDirection,
    String? categoryId,
    String? brandId,
    String? productStatus,
    String? stockStatus,
  }) {
    return TenantProductListQuery(
      search: search ?? this.search,
      pageNumber: pageNumber ?? this.pageNumber,
      pageSize: pageSize ?? this.pageSize,
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
      categoryId: categoryId ?? this.categoryId,
      brandId: brandId ?? this.brandId,
      productStatus: productStatus ?? this.productStatus,
      stockStatus: stockStatus ?? this.stockStatus,
    );
  }
}

class TenantProductSummary {
  const TenantProductSummary({
    required this.totalProducts,
    required this.activeProducts,
    required this.inactiveProducts,
    required this.categoryCount,
  });

  final int totalProducts;
  final int activeProducts;
  final int inactiveProducts;
  final int categoryCount;
}
