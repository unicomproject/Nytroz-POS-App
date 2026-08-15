class Brand {
  const Brand({
    required this.id,
    required this.code,
    required this.name,
    required this.status,
    this.description,
    this.logoUrl,
    this.logoMediaAssetId,
    this.sortOrder = 0,
    this.productCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String code;
  final String name;
  final String status;
  final String? description;
  final String? logoUrl;
  final String? logoMediaAssetId;
  final int sortOrder;
  final int productCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  bool get hasLogo => logoUrl != null && logoUrl!.trim().isNotEmpty;
}

class BrandListResult {
  const BrandListResult({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
  });

  final List<Brand> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;

  int get totalPages => pageSize <= 0 ? 1 : (totalCount / pageSize).ceil();
}

class BrandUpsertInput {
  const BrandUpsertInput({
    required this.code,
    required this.name,
    required this.status,
    this.description,
    this.sortOrder = 0,
    this.logoUrl,
  });

  final String code;
  final String name;
  final String status;
  final String? description;
  final int sortOrder;
  final String? logoUrl;
}
