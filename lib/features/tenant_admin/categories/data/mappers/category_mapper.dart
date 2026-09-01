import '../../domain/entities/category.dart';
import '../../domain/entities/category_tree_node.dart';
import '../models/category_dto.dart';

class CategoryMapper {
  const CategoryMapper._();

  static Category toEntity(CategoryDto dto) {
    return Category(
      id: dto.id,
      parentCategoryId: dto.parentCategoryId,
      parentCategoryCode: dto.parentCategoryCode,
      parentCategoryName: dto.parentCategoryName,
      categoryCode: dto.categoryCode,
      categoryName: dto.categoryName,
      categorySlug: dto.categorySlug,
      description: dto.description,
      imageMediaAssetId: dto.imageMediaAssetId,
      imageUrl: dto.imageUrl,
      status: dto.status,
      sortOrder: dto.sortOrder,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
      level: dto.level,
      hierarchyPath: dto.hierarchyPath,
      childCount: dto.childCount,
      productCount: dto.productCount,
      hasChildren: dto.hasChildren,
    );
  }

  static CategoryListResult toListResult(CategoryListResultDto dto) {
    return CategoryListResult(
      items: dto.items.map(toEntity).toList(growable: false),
      pageNumber: dto.pageNumber,
      pageSize: dto.pageSize,
      totalCount: dto.totalCount,
    );
  }

  static CategoryTreeNode toTreeNode(CategoryTreeNodeDto dto) {
    return CategoryTreeNode(
      id: dto.id,
      categoryCode: dto.categoryCode,
      categoryName: dto.categoryName,
      status: dto.status,
      parentCategoryId: dto.parentCategoryId,
      sortOrder: dto.sortOrder,
      level: dto.level,
      hierarchyPath: dto.hierarchyPath,
      childCount: dto.childCount,
      productCount: dto.productCount,
      hasChildren: dto.hasChildren,
      children: dto.children.map(toTreeNode).toList(growable: false),
    );
  }

  static CategoryUpsertRequestDto toRequestDto(CategoryUpsertInput input) {
    return CategoryUpsertRequestDto(
      categoryCode: input.categoryCode.trim().toUpperCase(),
      name: input.name.trim(),
      status: input.status.toUpperCase(),
      parentCategoryId: input.parentCategoryId,
      description: input.description,
      categorySlug: input.categorySlug,
      sortOrder: input.sortOrder,
    );
  }
}
