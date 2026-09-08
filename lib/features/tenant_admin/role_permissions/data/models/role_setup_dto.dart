import 'role_assignments_dto.dart';

class RoleSetupOptionsDto {
  const RoleSetupOptionsDto({required this.roles});

  factory RoleSetupOptionsDto.fromJson(Map<String, dynamic> json) {
    final roles = json['roles'];
    return RoleSetupOptionsDto(
      roles: roles is List
          ? roles
              .whereType<Map>()
              .map((item) => RoleSetupOptionDto.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false)
          : const [],
    );
  }

  final List<RoleSetupOptionDto> roles;
}

class RoleSetupOptionDto {
  const RoleSetupOptionDto({
    required this.roleId,
    required this.roleCode,
    required this.roleName,
    required this.isActive,
    required this.isSystem,
    required this.permissionCount,
    required this.userCount,
    this.roleDescription,
    this.updatedAt,
  });

  factory RoleSetupOptionDto.fromJson(Map<String, dynamic> json) {
    return RoleSetupOptionDto(
      roleId: json['roleId']?.toString() ?? '',
      roleCode: json['roleCode']?.toString() ?? '',
      roleName: json['roleName']?.toString() ?? '',
      roleDescription: json['roleDescription']?.toString(),
      isActive: json['isActive'] as bool? ?? false,
      isSystem: json['isSystem'] as bool? ?? false,
      permissionCount: json['permissionCount'] as int? ?? 0,
      userCount: json['userCount'] as int? ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  final String roleId;
  final String roleCode;
  final String roleName;
  final String? roleDescription;
  final bool isActive;
  final bool isSystem;
  final int permissionCount;
  final int userCount;
  final DateTime? updatedAt;
}

class SaveRoleSetupRequestDto {
  const SaveRoleSetupRequestDto({
    required this.permissionCodes,
    required this.assignments,
    this.expectedUpdatedAt,
  });

  final List<String> permissionCodes;
  final List<UserRoleAssignmentDto> assignments;
  final DateTime? expectedUpdatedAt;

  Map<String, dynamic> toJson() => {
        'permissionCodes': permissionCodes,
        'assignments':
            assignments.map((assignment) => assignment.toJson()).toList(),
        if (expectedUpdatedAt != null)
          'expectedUpdatedAt': expectedUpdatedAt!.toIso8601String(),
      };
}
