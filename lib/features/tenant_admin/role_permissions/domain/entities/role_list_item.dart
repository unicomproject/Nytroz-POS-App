class RoleListItem {
  const RoleListItem({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.isActive,
    required this.isSystem,
    required this.permissionCount,
    required this.userCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final bool isActive;
  final bool isSystem;
  final int permissionCount;
  final int userCount;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class PaginatedRoleList {
  const PaginatedRoleList({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  final List<RoleListItem> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;
}
