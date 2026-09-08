class CategoryDto {
  const CategoryDto({
    required this.id,
    required this.categoryCode,
    required this.categoryName,
    required this.categorySlug,
    required this.status,
    required this.sortOrder,
    required this.level,
    required this.hierarchyPath,
    required this.childCount,
    required this.productCount,
    required this.hasChildren,
    this.parentCategoryId,
    this.parentCategoryCode,
    this.parentCategoryName,
    this.description,
    this.imageMediaAssetId,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      id: json['id']?.toString() ?? '',
      parentCategoryId: json['parentCategoryId']?.toString(),
      parentCategoryCode: json['parentCategoryCode']?.toString(),
      parentCategoryName: json['parentCategoryName']?.toString(),
      categoryCode: json['categoryCode']?.toString() ?? '',
      categoryName:
          json['categoryName']?.toString() ?? json['name']?.toString() ?? '',
      categorySlug: json['categorySlug']?.toString() ?? '',
      description: json['description']?.toString(),
      imageMediaAssetId: json['imageMediaAssetId']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      status: json['status']?.toString() ?? 'ACTIVE',
      sortOrder: _readInt(json['sortOrder'], fallback: 0),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      level: _readInt(json['level'], fallback: 1),
      hierarchyPath: json['hierarchyPath']?.toString() ?? '',
      childCount: _readInt(json['childCount'], fallback: 0),
      productCount: _readInt(json['productCount'], fallback: 0),
      hasChildren: json['hasChildren'] == true,
    );
  }

  final String id;
  final String? parentCategoryId;
  final String? parentCategoryCode;
  final String? parentCategoryName;
  final String categoryCode;
  final String categoryName;
  final String categorySlug;
  final String? description;
  final String? imageMediaAssetId;
  final String? imageUrl;
  final String status;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int level;
  final String hierarchyPath;
  final int childCount;
  final int productCount;
  final bool hasChildren;

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value.toString());
  }

  static int _readInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class CategoryListResultDto {
  const CategoryListResultDto({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
  });

  factory CategoryListResultDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map(
              (item) => CategoryDto.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false)
        : <CategoryDto>[];

    return CategoryListResultDto(
      items: items,
      pageNumber: _readInt(json['pageNumber'], fallback: 1),
      pageSize: _readInt(json['pageSize'], fallback: items.length),
      totalCount: _readInt(json['totalCount'], fallback: items.length),
    );
  }

  final List<CategoryDto> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;

  static int _readInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class CategoryTreeNodeDto {
  const CategoryTreeNodeDto({
    required this.id,
    required this.categoryCode,
    required this.categoryName,
    required this.status,
    required this.sortOrder,
    required this.level,
    required this.hierarchyPath,
    required this.childCount,
    required this.productCount,
    required this.hasChildren,
    required this.children,
    this.parentCategoryId,
  });

  factory CategoryTreeNodeDto.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'];
    final children = rawChildren is List
        ? rawChildren
            .whereType<Map>()
            .map(
              (item) =>
                  CategoryTreeNodeDto.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false)
        : <CategoryTreeNodeDto>[];

    return CategoryTreeNodeDto(
      id: json['id']?.toString() ?? '',
      categoryCode: json['categoryCode']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
      parentCategoryId: json['parentCategoryId']?.toString(),
      sortOrder: CategoryDto._readInt(json['sortOrder'], fallback: 0),
      level: CategoryDto._readInt(json['level'], fallback: 1),
      hierarchyPath: json['hierarchyPath']?.toString() ?? '',
      childCount: CategoryDto._readInt(json['childCount'], fallback: 0),
      productCount: CategoryDto._readInt(json['productCount'], fallback: 0),
      hasChildren: json['hasChildren'] == true,
      children: children,
    );
  }

  final String id;
  final String categoryCode;
  final String categoryName;
  final String status;
  final String? parentCategoryId;
  final int sortOrder;
  final int level;
  final String hierarchyPath;
  final int childCount;
  final int productCount;
  final bool hasChildren;
  final List<CategoryTreeNodeDto> children;
}

class CategoryTreeResultDto {
  const CategoryTreeResultDto({required this.items});

  factory CategoryTreeResultDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map(
              (item) =>
                  CategoryTreeNodeDto.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList(growable: false)
        : <CategoryTreeNodeDto>[];

    return CategoryTreeResultDto(items: items);
  }

  final List<CategoryTreeNodeDto> items;
}

class CategoryUpsertRequestDto {
  const CategoryUpsertRequestDto({
    required this.categoryCode,
    required this.name,
    required this.status,
    this.parentCategoryId,
    this.description,
    this.categorySlug,
    this.sortOrder = 0,
  });

  final String categoryCode;
  final String name;
  final String status;
  final String? parentCategoryId;
  final String? description;
  final String? categorySlug;
  final int sortOrder;

  Map<String, dynamic> toJson() {
    return {
      'categoryCode': categoryCode,
      'name': name,
      'status': status,
      'sortOrder': sortOrder,
      if (parentCategoryId != null && parentCategoryId!.trim().isNotEmpty)
        'parentCategoryId': parentCategoryId,
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      if (categorySlug != null && categorySlug!.trim().isNotEmpty)
        'categorySlug': categorySlug!.trim(),
    };
  }
}
