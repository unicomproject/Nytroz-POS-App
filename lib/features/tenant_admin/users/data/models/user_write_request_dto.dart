class UserWriteRequestDto {
  const UserWriteRequestDto({
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.employeeId,
    required this.roleId,
    this.outletIds = const [],
    this.permissionOverrideEnabled = false,
    this.overriddenPermissionIds = const [],
    this.sendInviteEmail,
    this.status,
    this.profileMediaAssetId,
  });

  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? employeeId;
  final String roleId;
  final List<String> outletIds;
  final bool permissionOverrideEnabled;
  final List<String> overriddenPermissionIds;
  final bool? sendInviteEmail;
  final String? status;
  final String? profileMediaAssetId;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName.trim(),
      'email': email.trim(),
      if (phoneNumber != null && phoneNumber!.trim().isNotEmpty)
        'phoneNumber': phoneNumber!.trim(),
      if (employeeId != null && employeeId!.trim().isNotEmpty)
        'employeeId': employeeId!.trim(),
      'roleId': roleId,
      'outletIds': outletIds,
      'permissionOverrideEnabled': permissionOverrideEnabled,
      'overriddenPermissionIds': overriddenPermissionIds,
      if (sendInviteEmail != null) 'sendInviteEmail': sendInviteEmail,
      if (status != null) 'status': status,
      if (profileMediaAssetId != null &&
          profileMediaAssetId!.trim().isNotEmpty)
        'profileMediaAssetId': profileMediaAssetId!.trim(),
    };
  }
}
