class TenantProduct {
  const TenantProduct({
    required this.id,
    required this.name,
    required this.sku,
    required this.status,
    required this.stockQuantity,
    this.categoryName,
    this.barcode,
    this.sellingPrice,
    this.currencyCode,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String sku;
  final String? barcode;
  final String? categoryName;
  final double? sellingPrice;
  final String? currencyCode;
  final int stockQuantity;
  final String status;
  final String? imageUrl;
}

class TenantProductListResult {
  const TenantProductListResult({
    required this.items,
    this.page = 1,
    this.pageSize = 10,
    this.totalCount = 0,
  });

  final List<TenantProduct> items;
  final int page;
  final int pageSize;
  final int totalCount;

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
    this.page = 1,
    this.pageSize = 10,
    this.sortBy,
    this.sortDirection,
    this.categoryId,
    this.status,
  });

  final String? search;
  final int page;
  final int pageSize;
  final String? sortBy;
  final String? sortDirection;
  final String? categoryId;
  final String? status;
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
