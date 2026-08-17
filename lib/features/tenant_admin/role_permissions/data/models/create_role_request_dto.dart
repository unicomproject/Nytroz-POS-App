import 'role_assignments_dto.dart';

class CreateRoleRequestDto {
  const CreateRoleRequestDto({
    required this.roleName,
    required this.roleCode,
    this.roleDescription,
    this.permissionCodes,
    this.assignments,
  });

  Map<String, dynamic> toJson() {
    return {
      'roleName': roleName,
      'roleCode': roleCode,
      if (roleDescription != null) 'roleDescription': roleDescription,
      if (permissionCodes != null) 'permissionCodes': permissionCodes,
      if (assignments != null)
        'assignments': assignments?.map((e) => e.toJson()).toList(growable: false),
    };
  }

  final String roleName;
  final String roleCode;
  final String? roleDescription;
  final List<String>? permissionCodes;
  final List<UserRoleAssignmentDto>? assignments;
}
