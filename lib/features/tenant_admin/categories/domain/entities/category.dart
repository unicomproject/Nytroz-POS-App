class Category {
  const Category({
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

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  bool get isRoot => parentCategoryId == null || parentCategoryId!.isEmpty;

  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  String get parentDisplayLabel =>
      isRoot ? 'Root' : (parentCategoryName ?? parentCategoryCode ?? '—');
}

class CategoryListResult {
  const CategoryListResult({
    required this.items,
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
  });

  final List<Category> items;
  final int pageNumber;
  final int pageSize;
  final int totalCount;
}

class CategoryUpsertInput {
  const CategoryUpsertInput({
    required this.categoryCode,
    required this.name,
    required this.status,
    this.parentCategoryId,
    this.description,
    this.sortOrder = 0,
    this.categorySlug,
  });

  final String categoryCode;
  final String name;
  final String status;
  final String? parentCategoryId;
  final String? description;
  final int sortOrder;
  final String? categorySlug;
}

class CategorySaveResult {
  const CategorySaveResult({
    required this.category,
    this.imageUploadFailed = false,
    this.imageRemoveFailed = false,
    this.imageUploadError,
  });

  final Category category;
  final bool imageUploadFailed;
  final bool imageRemoveFailed;
  final String? imageUploadError;

  bool get imageActionFailed => imageUploadFailed || imageRemoveFailed;
}
