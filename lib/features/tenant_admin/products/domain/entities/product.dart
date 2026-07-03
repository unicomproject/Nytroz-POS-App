class Product {
  const Product({
    required this.id,
    required this.variantId,
    required this.name,
    required this.sku,
    required this.status,
    this.categoryName,
    this.barcode,
    this.sellingPrice,
    this.outletCount = 0,
    this.createdAt,
    this.imageStorageKey,
  });

  final String id;
  final String variantId;
  final String name;
  final String sku;
  final String status;
  final String? categoryName;
  final String? barcode;
  final double? sellingPrice;
  final int outletCount;
  final DateTime? createdAt;
  final String? imageStorageKey;
}

class ProductListSummary {
  const ProductListSummary({
    required this.totalProducts,
    required this.activeProducts,
    required this.inactiveProducts,
    required this.productCategories,
  });

  final int totalProducts;
  final int activeProducts;
  final int inactiveProducts;
  final int productCategories;
}

class ProductListResult {
  const ProductListResult({
    required this.summary,
    required this.items,
    this.page = 1,
    this.pageSize = 10,
    this.totalCount = 0,
  });

  final ProductListSummary summary;
  final List<Product> items;
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

  /// Prefer summary total because API totalCount can count variant rows.
  int get displayTotalCount =>
      summary.totalProducts > 0 ? summary.totalProducts : totalCount;
}

class ProductListQuery {
  const ProductListQuery({
    this.search,
    this.page = 1,
    this.pageSize = 10,
    this.status,
  });

  final String? search;
  final int page;
  final int pageSize;
  final String? status;
}

class ProductFormData {
  const ProductFormData({
    required this.name,
    required this.sku,
    this.categoryName,
    this.brandName,
    this.barcode,
    this.description,
    this.sellingPrice,
    this.trackStock = false,
  });

  final String name;
  final String sku;
  final String? categoryName;
  final String? brandName;
  final String? barcode;
  final String? description;
  final double? sellingPrice;
  final bool trackStock;
}

class CreatedProduct {
  const CreatedProduct({
    required this.id,
    required this.variantId,
    required this.name,
    required this.sku,
    required this.status,
    this.barcode,
    this.sellingPrice,
  });

  final String id;
  final String variantId;
  final String name;
  final String sku;
  final String status;
  final String? barcode;
  final double? sellingPrice;
}
