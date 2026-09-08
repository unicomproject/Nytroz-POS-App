class RoleAssignmentsDto {
  const RoleAssignmentsDto({
    required this.roleId,
    required this.assignments,
    this.roleCode = '',
    this.roleName = '',
    this.isSystem = false,
    this.updatedAt,
  });

  factory RoleAssignmentsDto.fromJson(Map<String, dynamic> json) {
    return RoleAssignmentsDto(
      roleId: json['roleId']?.toString() ?? '',
      roleCode: json['roleCode']?.toString() ?? '',
      roleName: json['roleName']?.toString() ?? '',
      isSystem: json['isSystem'] as bool? ?? false,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      assignments: (json['assignments'] as List?)
              ?.map((e) =>
                  UserRoleAssignmentDto.fromJson(e as Map<String, dynamic>))
              .toList(growable: false) ??
          [],
    );
  }

  final String roleId;
  final String roleCode;
  final String roleName;
  final bool isSystem;
  final DateTime? updatedAt;
  final List<UserRoleAssignmentDto> assignments;
}

class UserRoleAssignmentDto {
  const UserRoleAssignmentDto({
    required this.userId,
    required this.accessScope,
    required this.outletIds,
    this.fullName,
    this.email,
  });

  factory UserRoleAssignmentDto.fromJson(Map<String, dynamic> json) {
    return UserRoleAssignmentDto(
      userId: json['userId']?.toString() ?? '',
      accessScope: json['accessScope']?.toString() ?? 'TENANT_WIDE',
      outletIds: (json['outletIds'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          [],
      fullName: json['fullName']?.toString(),
      email: json['email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'accessScope': accessScope,
      if (outletIds.isNotEmpty) 'outletIds': outletIds,
    };
  }

  final String userId;
  final String accessScope;
  final List<String> outletIds;
  final String? fullName;
  final String? email;
}
