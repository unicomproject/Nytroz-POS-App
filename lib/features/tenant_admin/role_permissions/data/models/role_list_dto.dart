class RoleListResponseDto {
  const RoleListResponseDto({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  final List<RoleListItemDto> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  factory RoleListResponseDto.fromJson(Map<String, dynamic> json) {
    return RoleListResponseDto(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => RoleListItemDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 5,
      totalCount: json['totalCount'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
    );
  }
}

class RoleListItemDto {
  const RoleListItemDto({
    required this.roleId,
    required this.roleCode,
    required this.roleName,
    this.roleDescription,
    required this.isActive,
    required this.isSystem,
    required this.permissionCount,
    required this.userCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String roleId;
  final String roleCode;
  final String roleName;
  final String? roleDescription;
  final bool isActive;
  final bool isSystem;
  final int permissionCount;
  final int userCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory RoleListItemDto.fromJson(Map<String, dynamic> json) {
    return RoleListItemDto(
      roleId: json['roleId'] as String,
      roleCode: json['roleCode'] as String,
      roleName: json['roleName'] as String,
      roleDescription: json['roleDescription'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isSystem: json['isSystem'] as bool? ?? false,
      permissionCount: json['permissionCount'] as int? ?? 0,
      userCount: json['userCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
