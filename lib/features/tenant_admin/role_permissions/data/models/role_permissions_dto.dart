class RolePermissionsDto {
  const RolePermissionsDto({
    required this.roleId,
    required this.roleCode,
    required this.roleName,
    required this.roleScope,
    required this.isSystem,
    required this.assignedPermissionCodes,
    required this.assignedPermissionIds,
    this.updatedAt,
  });

  factory RolePermissionsDto.fromJson(Map<String, dynamic> json) {
    return RolePermissionsDto(
      roleId: json['roleId']?.toString() ?? '',
      roleCode: json['roleCode'] as String? ?? '',
      roleName: json['roleName'] as String? ?? '',
      roleScope: json['roleScope'] as String? ?? '',
      isSystem: json['isSystem'] as bool? ?? false,
      assignedPermissionCodes: _stringList(json['assignedPermissionCodes']),
      assignedPermissionIds: _idList(json['assignedPermissionIds']),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  final String roleId;
  final String roleCode;
  final String roleName;
  final String roleScope;
  final bool isSystem;
  final List<String> assignedPermissionCodes;
  final List<String> assignedPermissionIds;
  final DateTime? updatedAt;
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value.map((item) => item.toString()).toList(growable: false);
}

List<String> _idList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value.map((item) => item.toString()).toList(growable: false);
}
