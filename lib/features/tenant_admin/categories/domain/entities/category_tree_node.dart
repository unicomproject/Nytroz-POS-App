class CategoryTreeNode {
  const CategoryTreeNode({
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
  final List<CategoryTreeNode> children;

  bool get isActive => status.toUpperCase() == 'ACTIVE';
}
