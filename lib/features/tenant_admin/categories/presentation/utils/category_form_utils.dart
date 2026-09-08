import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_list_query.dart';
import '../../domain/entities/category_tree_node.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';

String formatCategoryUpdatedOn(DateTime? value) {
  if (value == null) {
    return '—';
  }

  final local = value.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${months[local.month - 1]} ${local.day}, ${local.year} $hour:$minute $period';
}

String deriveCategoryCode(String name) {
  final normalized = name
      .trim()
      .toUpperCase()
      .replaceAll(RegExp(r'[^A-Z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  return normalized.isEmpty ? 'CATEGORY' : normalized;
}

CategoryTreeNode? findCategoryTreeNode(
  List<CategoryTreeNode> nodes,
  String id,
) {
  for (final node in nodes) {
    if (node.id == id) {
      return node;
    }
    final nested = findCategoryTreeNode(node.children, id);
    if (nested != null) {
      return nested;
    }
  }
  return null;
}

class FilteredCategoryTree {
  const FilteredCategoryTree({
    required this.nodes,
    this.expandedIds = const {},
  });

  final List<CategoryTreeNode> nodes;
  final Set<String> expandedIds;
}

FilteredCategoryTree filterCategoryTree({
  required List<CategoryTreeNode> nodes,
  String search = '',
  CategoryStatusFilter statusFilter = CategoryStatusFilter.all,
  CategoryParentFilter parentFilter = const CategoryParentFilter(),
}) {
  var working = nodes;
  if (parentFilter.kind == CategoryParentFilterKind.specific &&
      parentFilter.parentCategoryId != null) {
    final found = findCategoryTreeNode(nodes, parentFilter.parentCategoryId!);
    working = found == null ? const [] : [found];
  }

  final query = search.trim().toLowerCase();
  final filtered = working
      .map((node) => _filterCategoryTreeNode(node, query, statusFilter))
      .whereType<CategoryTreeNode>()
      .toList(growable: false);

  final expandedIds = <String>{};
  final shouldAutoExpand = query.isNotEmpty ||
      parentFilter.kind == CategoryParentFilterKind.specific;
  if (shouldAutoExpand) {
    _collectExpandedIds(filtered, expandedIds);
  }

  return FilteredCategoryTree(nodes: filtered, expandedIds: expandedIds);
}

CategoryTreeNode? _filterCategoryTreeNode(
  CategoryTreeNode node,
  String query,
  CategoryStatusFilter statusFilter,
) {
  final matchesQuery = query.isEmpty ||
      node.categoryName.toLowerCase().contains(query) ||
      node.categoryCode.toLowerCase().contains(query);
  final matchesStatus = _matchesStatusFilter(node, statusFilter);

  final filteredChildren = node.children
      .map((child) => _filterCategoryTreeNode(child, query, statusFilter))
      .whereType<CategoryTreeNode>()
      .toList(growable: false);

  if (matchesQuery && matchesStatus) {
    final children = query.isEmpty
        ? filteredChildren
        : node.children
            .map((child) => _filterCategoryTreeNode(child, '', statusFilter))
            .whereType<CategoryTreeNode>()
            .toList(growable: false);
    return _copyTreeNode(node, children);
  }

  if (filteredChildren.isNotEmpty) {
    return _copyTreeNode(node, filteredChildren);
  }

  return null;
}

bool _matchesStatusFilter(
  CategoryTreeNode node,
  CategoryStatusFilter statusFilter,
) {
  switch (statusFilter) {
    case CategoryStatusFilter.all:
      return true;
    case CategoryStatusFilter.active:
      return node.isActive;
    case CategoryStatusFilter.inactive:
      return !node.isActive;
  }
}

CategoryTreeNode _copyTreeNode(
  CategoryTreeNode node,
  List<CategoryTreeNode> children,
) {
  return CategoryTreeNode(
    id: node.id,
    categoryCode: node.categoryCode,
    categoryName: node.categoryName,
    status: node.status,
    sortOrder: node.sortOrder,
    level: node.level,
    hierarchyPath: node.hierarchyPath,
    childCount: children.length,
    productCount: node.productCount,
    hasChildren: children.isNotEmpty,
    children: children,
    parentCategoryId: node.parentCategoryId,
  );
}

void _collectExpandedIds(List<CategoryTreeNode> nodes, Set<String> ids) {
  for (final node in nodes) {
    if (node.children.isNotEmpty) {
      ids.add(node.id);
      _collectExpandedIds(node.children, ids);
    }
  }
}

class VisibleCategoryTreeRow {
  const VisibleCategoryTreeRow({
    required this.node,
    required this.depth,
    this.parentName,
  });

  final CategoryTreeNode node;
  final int depth;
  final String? parentName;
}

List<VisibleCategoryTreeRow> visibleCategoryTreeRows({
  required List<CategoryTreeNode> nodes,
  required Set<String> expandedIds,
  int depth = 0,
  String? parentName,
}) {
  final rows = <VisibleCategoryTreeRow>[];
  for (final node in nodes) {
    rows.add(
      VisibleCategoryTreeRow(
        node: node,
        depth: depth,
        parentName: parentName,
      ),
    );
    if (expandedIds.contains(node.id) && node.children.isNotEmpty) {
      rows.addAll(
        visibleCategoryTreeRows(
          nodes: node.children,
          expandedIds: expandedIds,
          depth: depth + 1,
          parentName: node.categoryName,
        ),
      );
    }
  }
  return rows;
}

List<T> paginateList<T>(
  List<T> items, {
  required int page,
  required int pageSize,
}) {
  if (items.isEmpty || pageSize <= 0) {
    return <T>[];
  }

  final totalPages = (items.length / pageSize).ceil();
  final safePage = page.clamp(1, totalPages);
  final start = (safePage - 1) * pageSize;
  final end = (start + pageSize).clamp(0, items.length);
  return items.sublist(start, end);
}

Category categoryFromTreeNode(CategoryTreeNode node, {String? parentName}) {
  return Category(
    id: node.id,
    parentCategoryId: node.parentCategoryId,
    parentCategoryName: parentName,
    categoryCode: node.categoryCode,
    categoryName: node.categoryName,
    categorySlug: node.categoryCode.toLowerCase(),
    status: node.status,
    sortOrder: node.sortOrder,
    level: node.level,
    hierarchyPath: node.hierarchyPath,
    childCount: node.childCount,
    productCount: node.productCount,
    hasChildren: node.hasChildren,
  );
}

Widget treeNodeImageAvatar(CategoryTreeNode node, {double size = 32}) {
  return categoryImageAvatar(categoryFromTreeNode(node), size: size);
}

String? deriveParentHierarchyPath(Category category) {
  if (category.isRoot) {
    return null;
  }

  const separator = ' > ';
  final path = category.hierarchyPath.trim();
  final index = path.lastIndexOf(separator);
  if (index > 0) {
    return path.substring(0, index);
  }

  return category.parentCategoryName;
}

String formatEditParentSelectorLabel({
  required String? parentId,
  required String? parentName,
  required bool parentIsInactive,
}) {
  if (parentId == null || parentId.isEmpty) {
    return 'No parent selected';
  }

  final name = parentName?.trim().isNotEmpty == true
      ? parentName!.trim()
      : 'Selected parent';

  return parentIsInactive ? '$name (Inactive)' : name;
}

Widget categoryImageAvatar(Category category, {double size = 40}) {
  final url = category.imageUrl?.trim();
  if (url == null || url.isEmpty) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: TenantAdminColors.border.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      ),
      child: Icon(Icons.category_outlined, size: size * 0.45),
    );
  }

  return ClipRRect(
    borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
    child: Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        color: TenantAdminColors.border.withValues(alpha: 0.35),
        child: Icon(Icons.broken_image_outlined, size: size * 0.45),
      ),
    ),
  );
}

String? categoryApiErrorCode(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final code = data['code']?.toString();
      if (code != null && code.isNotEmpty) {
        return code;
      }

      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is Map) {
          return first['code']?.toString();
        }
      }
    }
  }

  return null;
}

String categoryApiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }

      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is Map) {
          final errorMessage = first['message']?.toString();
          if (errorMessage != null && errorMessage.trim().isNotEmpty) {
            return errorMessage;
          }
        }
      }

      final code = data['code']?.toString();
      switch (code) {
        case 'category.duplicate_code':
          return 'Category code already exists.';
        case 'category.duplicate_name':
          return 'Category name already exists.';
        case 'category.parent_inactive':
          return 'Selected parent category is inactive.';
        case 'category.parent_not_found':
          return 'Selected parent category was not found.';
        case 'category.parent_self_reference':
          return 'A category cannot be its own parent.';
        case 'category.parent_cycle':
          return 'Selected parent would create a circular hierarchy.';
        case 'category.max_depth_exceeded':
          return 'Category hierarchy cannot exceed 5 levels.';
        case 'category.delete_conflict':
          return categoryArchiveConflictMessage(message);
        case 'category.not_found':
          return 'Category was not found.';
        case 'category.permission_denied':
        case 'category.entitlement_denied':
          return 'You do not have permission to perform this action.';
      }
    }

    return error.message ?? 'Unable to complete category request.';
  }

  return error.toString();
}

Map<String, String> categoryFieldErrorsFromError(Object error) {
  final code = categoryApiErrorCode(error);
  final message = categoryApiErrorMessage(error);

  switch (code) {
    case 'category.duplicate_name':
      return {'name': message};
    case 'category.duplicate_code':
      return {'code': message};
    case 'category.parent_inactive':
    case 'category.parent_not_found':
    case 'category.parent_self_reference':
    case 'category.parent_cycle':
    case 'category.max_depth_exceeded':
      return {'parent': message};
    default:
      return const {};
  }
}

bool isCategoryNotFoundError(Object error) {
  if (categoryApiErrorCode(error) == 'category.not_found') {
    return true;
  }

  if (error is DioException && error.response?.statusCode == 404) {
    return true;
  }

  return false;
}

bool isCategoryPermissionDeniedError(Object error) {
  final code = categoryApiErrorCode(error);
  return code == 'category.permission_denied' ||
      code == 'category.entitlement_denied';
}

String categoryArchiveConflictMessage(String? backendMessage) {
  final normalized = backendMessage?.toLowerCase() ?? '';
  if (normalized.contains('child categor')) {
    return 'This category cannot be archived because it still has child categories. Move or archive the child categories first.';
  }
  if (normalized.contains('product')) {
    return 'This category cannot be archived because products are still assigned to it. Reassign or remove the product mappings first.';
  }

  return 'This category cannot be archived because it still has child categories or mapped products.';
}

String categoryArchiveErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message']?.toString();
      final code = data['code']?.toString();

      if (code == 'category.delete_conflict') {
        return categoryArchiveConflictMessage(message);
      }
    }
  }

  return categoryApiErrorMessage(error);
}

Future<bool> confirmDiscardCategoryForm(BuildContext context) async {
  final discard = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Discard changes?'),
      content: const Text(
        'You have unsaved changes. Are you sure you want to discard them?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep editing'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Discard'),
        ),
      ],
    ),
  );

  return discard == true;
}
