class RoleAssignmentsDto {
  const RoleAssignmentsDto({
    required this.roleId,
    required this.assignments,
  });

  factory RoleAssignmentsDto.fromJson(Map<String, dynamic> json) {
    return RoleAssignmentsDto(
      roleId: json['roleId']?.toString() ?? '',
      assignments: (json['assignments'] as List?)
              ?.map((e) => UserRoleAssignmentDto.fromJson(e as Map<String, dynamic>))
              .toList(growable: false) ??
          [],
    );
  }

  final String roleId;
  final List<UserRoleAssignmentDto> assignments;
}

class UserRoleAssignmentDto {
  const UserRoleAssignmentDto({
    required this.userId,
    required this.accessScope,
    required this.outletIds,
  });

  factory UserRoleAssignmentDto.fromJson(Map<String, dynamic> json) {
    return UserRoleAssignmentDto(
      userId: json['userId']?.toString() ?? '',
      accessScope: json['accessScope']?.toString() ?? 'TENANT_WIDE',
      outletIds: (json['outletIds'] as List?)
              ?.map((e) => e.toString())
              .toList(growable: false) ??
          [],
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
}
