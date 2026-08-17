class UpdateRoleRequestDto {
  const UpdateRoleRequestDto({
    required this.roleName,
    required this.roleCode,
    this.roleDescription,
    this.expectedUpdatedAt,
  });

  final String roleName;
  final String roleCode;
  final String? roleDescription;
  final DateTime? expectedUpdatedAt;

  Map<String, dynamic> toJson() {
    return {
      'roleName': roleName,
      'roleCode': roleCode,
      if (roleDescription != null) 'roleDescription': roleDescription,
      if (expectedUpdatedAt != null) 'expectedUpdatedAt': expectedUpdatedAt!.toIso8601String(),
    };
  }
}
