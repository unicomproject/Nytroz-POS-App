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
    this.profileMediaAction,
    this.outletAccessScope = 'ALL_OUTLETS',
    this.defaultOutletId,
    this.tillAccessScope = 'ALL_ACCESSIBLE_TILLS',
    this.tillIds = const [],
    this.defaultTillId,
    this.permissionCatalogVersion,
    this.deniedPermissionIds = const [],
    this.password,
    this.confirmPassword,
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
  final String? profileMediaAction;
  final String outletAccessScope;
  final String? defaultOutletId;
  final String tillAccessScope;
  final List<String> tillIds;
  final String? defaultTillId;
  final String? permissionCatalogVersion;
  final List<String> deniedPermissionIds;
  final String? password;
  final String? confirmPassword;

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
      if (status != null) 'createStatus': status,
      'outletAccessScope': outletAccessScope,
      if (defaultOutletId != null) 'defaultOutletId': defaultOutletId,
      'tillAccessScope': tillAccessScope,
      'tillIds': tillIds,
      if (defaultTillId != null) 'defaultTillId': defaultTillId,
      if (permissionCatalogVersion != null &&
          permissionCatalogVersion!.trim().isNotEmpty)
        'permissionCatalogVersion': permissionCatalogVersion!.trim(),
      'deniedPermissionIds': deniedPermissionIds,
      if (password != null) 'password': password,
      if (confirmPassword != null) 'confirmPassword': confirmPassword,
      if (profileMediaAssetId != null && profileMediaAssetId!.trim().isNotEmpty)
        'profileMediaAssetId': profileMediaAssetId!.trim(),
      if (profileMediaAction != null && profileMediaAction!.trim().isNotEmpty)
        'profileMediaAction': profileMediaAction!.trim(),
    };
  }
}
