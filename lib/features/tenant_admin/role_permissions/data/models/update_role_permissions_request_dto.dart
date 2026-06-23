class UpdateRolePermissionsRequestDto {
  const UpdateRolePermissionsRequestDto({
    required this.permissionCodes,
  });

  Map<String, dynamic> toJson() {
    return {
      'permissionCodes': permissionCodes,
    };
  }

  final List<String> permissionCodes;
}
