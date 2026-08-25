import 'role_assignment.dart';

class RoleSetupOption {
  const RoleSetupOption({
    required this.id,
    required this.code,
    required this.name,
    required this.isActive,
    required this.isSystem,
    required this.permissionCount,
    required this.userCount,
    required this.updatedAt,
    this.description,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final bool isActive;
  final bool isSystem;
  final int permissionCount;
  final int userCount;
  final DateTime? updatedAt;
}

class SaveRoleSetupRequest {
  const SaveRoleSetupRequest({
    required this.permissionCodes,
    required this.assignments,
    required this.expectedUpdatedAt,
  });

  final List<String> permissionCodes;
  final List<RoleAssignment> assignments;
  final DateTime? expectedUpdatedAt;
}

class SaveRoleSetupResult {
  const SaveRoleSetupResult({
    required this.roleId,
    this.updatedAt,
  });

  final String roleId;
  final DateTime? updatedAt;
}
