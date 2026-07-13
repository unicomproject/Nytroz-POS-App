class Brand {
  const Brand({
    required this.id,
    required this.code,
    required this.name,
    required this.status,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String code;
  final String name;
  final String status;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isActive => status.toUpperCase() == 'ACTIVE';
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
}

class BrandUpsertInput {
  const BrandUpsertInput({
    required this.code,
    required this.name,
    required this.status,
    this.description,
  });

  final String code;
  final String name;
  final String status;
  final String? description;
}
