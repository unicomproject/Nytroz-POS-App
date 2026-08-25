class RolePermissions {
  const RolePermissions({
    required this.roleId,
    required this.roleCode,
    required this.roleName,
    required this.roleScope,
    required this.isSystem,
    required this.assignedPermissionCodes,
    required this.assignedPermissionIds,
    this.updatedAt,
  });

  final String roleId;
  final String roleCode;
  final String roleName;
  final String roleScope;
  final bool isSystem;
  final List<String> assignedPermissionCodes;
  final List<String> assignedPermissionIds;
  final DateTime? updatedAt;
}

class UpdateRolePermissionsRequest {
  const UpdateRolePermissionsRequest({
    required this.permissionCodes,
  });

  final List<String> permissionCodes;
}
