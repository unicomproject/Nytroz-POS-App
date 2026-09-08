class TenantUserListItemDto {
  const TenantUserListItemDto({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.staffCode,
    this.profileImageUrl,
    this.roleId,
    required this.roleName,
    this.roleDescription,
    required this.outletName,
    this.outlets = const [],
    this.outletCount,
    required this.status,
    this.lastActiveAt,
  });

  factory TenantUserListItemDto.fromJson(Map<String, dynamic> json) {
    return TenantUserListItemDto(
      id: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phoneNumber'] as String? ?? json['phone'] as String?,
      staffCode: json['staffCode'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      roleId: json['roleId']?.toString(),
      roleName: json['roleName'] as String? ?? '',
      roleDescription: json['roleDescription'] as String?,
      outletName: json['outletName'] as String? ?? '',
      outlets: _mapList(json['outlets'], UserOutletOptionDto.fromJson),
      outletCount: json.containsKey('outletCount')
          ? _intValue(json['outletCount'])
          : null,
      status: json['status'] as String? ?? '',
      lastActiveAt: _dateValue(json['lastActiveAt']),
    );
  }

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? staffCode;
  final String? profileImageUrl;
  final String? roleId;
  final String roleName;
  final String? roleDescription;
  final String outletName;
  final List<UserOutletOptionDto> outlets;
  final int? outletCount;
  final String status;
  final DateTime? lastActiveAt;
}

class TenantUserListResultDto {
  const TenantUserListResultDto({
    required this.items,
    this.page = 1,
    this.pageSize = 5,
    this.totalCount = 0,
  });

  factory TenantUserListResultDto.fromJson(Map<String, dynamic> json) {
    final items = _mapList(json['items'], TenantUserListItemDto.fromJson);
    final page = _intValue(json['page'], fallback: 1);
    final pageSize = _intValue(json['pageSize'], fallback: 5);
    final totalCount = _intValue(json['totalCount'], fallback: items.length);

    return TenantUserListResultDto(
      items: items,
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
    );
  }

  final List<TenantUserListItemDto> items;
  final int page;
  final int pageSize;
  final int totalCount;
}

class RoleOptionDto {
  const RoleOptionDto({
    required this.id,
    required this.name,
    required this.code,
    this.roleDescription,
    this.isActive = true,
    this.moduleCount = 0,
    this.permissionCount = 0,
    this.modulePreview = const [],
    this.permissionPreview = const [],
  });

  factory RoleOptionDto.fromJson(Map<String, dynamic> json) {
    return RoleOptionDto(
      id: json['roleId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['roleName'] as String? ?? json['name'] as String? ?? '',
      code: json['roleCode'] as String? ?? json['code'] as String? ?? '',
      roleDescription: json['roleDescription'] as String?,
      isActive: json['isActive'] != false,
      moduleCount: _intValue(json['moduleCount']),
      permissionCount: _intValue(json['permissionCount']),
      modulePreview: _stringList(json['modulePreview']),
      permissionPreview: _stringList(json['permissionPreview']),
    );
  }

  final String id;
  final String name;
  final String code;
  final String? roleDescription;
  final bool isActive;
  final int moduleCount;
  final int permissionCount;
  final List<String> modulePreview;
  final List<String> permissionPreview;
}

class UserOutletOptionDto {
  const UserOutletOptionDto({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
  });

  factory UserOutletOptionDto.fromJson(Map<String, dynamic> json) {
    return UserOutletOptionDto(
      id: json['outletId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['outletName'] as String? ?? json['name'] as String? ?? '',
      code: json['outletCode'] as String? ?? json['code'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String code;
  final String status;
}

class PermissionItemDto {
  const PermissionItemDto({
    required this.id,
    required this.code,
    required this.actionType,
    this.description,
    this.name,
    this.moduleId,
    this.moduleCode,
    this.moduleName,
    this.sortOrder = 0,
    this.isAssignable = true,
    this.isLocked = false,
  });

  factory PermissionItemDto.fromJson(Map<String, dynamic> json) {
    return PermissionItemDto(
      id: json['permissionId']?.toString() ?? json['id']?.toString() ?? '',
      code: json['permissionCode'] as String? ?? json['code'] as String? ?? '',
      actionType: json['actionType'] as String? ?? '',
      description: json['description'] as String?,
      name: json['permissionName'] as String? ?? json['name'] as String?,
      moduleId: json['moduleId']?.toString(),
      moduleCode: json['moduleCode'] as String?,
      moduleName: json['moduleName'] as String?,
      sortOrder: _intValue(json['sortOrder']),
      isAssignable: json['isAssignable'] != false,
      isLocked: json['isLocked'] == true,
    );
  }

  final String id;
  final String code;
  final String actionType;
  final String? description;
  final String? name;
  final String? moduleId;
  final String? moduleCode;
  final String? moduleName;
  final int sortOrder;
  final bool isAssignable;
  final bool isLocked;
}

class PermissionGroupDto {
  const PermissionGroupDto({
    required this.groupName,
    required this.permissions,
    this.moduleId,
    this.moduleCode,
    this.description,
    this.sortOrder = 0,
  });

  factory PermissionGroupDto.fromJson(Map<String, dynamic> json) {
    return PermissionGroupDto(
      groupName: json['groupName'] as String? ?? '',
      permissions: _mapList(json['permissions'], PermissionItemDto.fromJson),
      moduleId: json['moduleId']?.toString(),
      moduleCode: json['moduleCode'] as String?,
      description: json['description'] as String?,
      sortOrder: _intValue(json['sortOrder']),
    );
  }

  final String groupName;
  final List<PermissionItemDto> permissions;
  final String? moduleId;
  final String? moduleCode;
  final String? description;
  final int sortOrder;
}

class UserTillOptionDto {
  const UserTillOptionDto({
    required this.id,
    required this.outletId,
    required this.name,
    required this.code,
    required this.status,
  });

  factory UserTillOptionDto.fromJson(Map<String, dynamic> json) {
    return UserTillOptionDto(
      id: json['tillId']?.toString() ?? json['id']?.toString() ?? '',
      outletId: json['outletId']?.toString() ?? '',
      name: json['tillName'] as String? ?? json['name'] as String? ?? '',
      code: json['tillCode'] as String? ?? json['code'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  final String id;
  final String outletId;
  final String name;
  final String code;
  final String status;
}

class TenantUserCreateCapabilitiesDto {
  const TenantUserCreateCapabilitiesDto({
    this.supportsInvitedUserCreation = false,
    this.supportsDirectActiveCreation = false,
    this.supportsUserPermissionOverrides = false,
    this.supportsPermissionDenies = false,
    this.supportsAllOutletAccess = false,
    this.supportsNoOutletAccess = false,
    this.supportsExplicitTillAccess = false,
    this.supportsDefaultOutlet = false,
    this.supportsDefaultTill = false,
    this.supportsAccessStartDate = false,
    this.supportsTemporaryPassword = false,
    this.supportsForcePasswordChange = false,
    this.supportsTwoFactorDuringCreation = false,
    this.supportsSaveDraft = false,
  });

  factory TenantUserCreateCapabilitiesDto.fromJson(
    Map<String, dynamic> json,
  ) {
    return TenantUserCreateCapabilitiesDto(
      supportsInvitedUserCreation: json['supportsInvitedUserCreation'] == true,
      supportsDirectActiveCreation:
          json['supportsDirectActiveCreation'] == true,
      supportsUserPermissionOverrides:
          json['supportsUserPermissionOverrides'] == true,
      supportsPermissionDenies: json['supportsPermissionDenies'] == true,
      supportsAllOutletAccess: json['supportsAllOutletAccess'] == true,
      supportsNoOutletAccess: json['supportsNoOutletAccess'] == true,
      supportsExplicitTillAccess: json['supportsExplicitTillAccess'] == true,
      supportsDefaultOutlet: json['supportsDefaultOutlet'] == true,
      supportsDefaultTill: json['supportsDefaultTill'] == true,
      supportsAccessStartDate: json['supportsAccessStartDate'] == true,
      supportsTemporaryPassword: json['supportsTemporaryPassword'] == true,
      supportsForcePasswordChange: json['supportsForcePasswordChange'] == true,
      supportsTwoFactorDuringCreation:
          json['supportsTwoFactorDuringCreation'] == true,
      supportsSaveDraft: json['supportsSaveDraft'] == true,
    );
  }

  final bool supportsInvitedUserCreation;
  final bool supportsDirectActiveCreation;
  final bool supportsUserPermissionOverrides;
  final bool supportsPermissionDenies;
  final bool supportsAllOutletAccess;
  final bool supportsNoOutletAccess;
  final bool supportsExplicitTillAccess;
  final bool supportsDefaultOutlet;
  final bool supportsDefaultTill;
  final bool supportsAccessStartDate;
  final bool supportsTemporaryPassword;
  final bool supportsForcePasswordChange;
  final bool supportsTwoFactorDuringCreation;
  final bool supportsSaveDraft;
}

class TenantUserCreateOptionsDto {
  const TenantUserCreateOptionsDto({
    required this.roles,
    required this.outlets,
    required this.permissionGroups,
    this.supportedStatuses = const [],
    this.tills = const [],
    this.supportedOutletAccessScopes = const [],
    this.supportedTillAccessScopes = const [],
    this.capabilities = const TenantUserCreateCapabilitiesDto(),
    this.permissionCatalogVersion,
  });

  factory TenantUserCreateOptionsDto.fromJson(Map<String, dynamic> json) {
    return TenantUserCreateOptionsDto(
      roles: _mapList(json['roles'], RoleOptionDto.fromJson),
      outlets: _mapList(json['outlets'], UserOutletOptionDto.fromJson),
      permissionGroups:
          _mapList(json['permissionGroups'], PermissionGroupDto.fromJson),
      supportedStatuses: _stringList(json['supportedStatuses']),
      tills: _mapList(json['tills'], UserTillOptionDto.fromJson),
      supportedOutletAccessScopes:
          _stringList(json['supportedOutletAccessScopes']),
      supportedTillAccessScopes: _stringList(json['supportedTillAccessScopes']),
      capabilities: json['capabilities'] is Map
          ? TenantUserCreateCapabilitiesDto.fromJson(
              Map<String, dynamic>.from(json['capabilities'] as Map),
            )
          : const TenantUserCreateCapabilitiesDto(),
      permissionCatalogVersion: json['permissionCatalogVersion'] as String?,
    );
  }

  final List<RoleOptionDto> roles;
  final List<UserOutletOptionDto> outlets;
  final List<PermissionGroupDto> permissionGroups;
  final List<String> supportedStatuses;
  final List<UserTillOptionDto> tills;
  final List<String> supportedOutletAccessScopes;
  final List<String> supportedTillAccessScopes;
  final TenantUserCreateCapabilitiesDto capabilities;
  final String? permissionCatalogVersion;
}

class TenantUserDetailDto {
  const TenantUserDetailDto({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.employeeId,
    this.staffCode,
    this.roleId,
    required this.roleName,
    this.roleDescription,
    required this.outlets,
    this.outletCount,
    this.accessSummary,
    required this.status,
    required this.permissionOverrideEnabled,
    required this.overriddenPermissionIds,
    this.lastActiveAt,
    this.createdAt,
    this.profileImageUrl,
    this.profileMediaAssetId,
  });

  factory TenantUserDetailDto.fromJson(Map<String, dynamic> json) {
    return TenantUserDetailDto(
      id: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phoneNumber'] as String? ?? json['phone'] as String?,
      employeeId: json['employeeId'] as String?,
      staffCode: json['staffCode'] as String?,
      roleId: json['roleId']?.toString(),
      roleName: json['roleName'] as String? ?? '',
      roleDescription: json['roleDescription'] as String?,
      outlets: _mapList(json['outlets'], UserOutletOptionDto.fromJson),
      outletCount: json.containsKey('outletCount')
          ? _intValue(json['outletCount'])
          : null,
      accessSummary: json['accessSummary'] is Map
          ? TenantUserAccessSummaryDto.fromJson(
              Map<String, dynamic>.from(json['accessSummary'] as Map),
            )
          : null,
      status: json['status'] as String? ?? '',
      permissionOverrideEnabled: json['permissionOverrideEnabled'] == true,
      overriddenPermissionIds: (json['overriddenPermissionIds'] is List)
          ? (json['overriddenPermissionIds'] as List)
              .map((item) => item.toString())
              .toList(growable: false)
          : const [],
      lastActiveAt: _dateValue(json['lastActiveAt']),
      createdAt: _dateValue(json['createdAt']),
      profileImageUrl: json['profileImageUrl'] as String?,
      profileMediaAssetId: json['profileMediaAssetId']?.toString() ??
          json['profileImageMediaAssetId']?.toString(),
    );
  }

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? employeeId;
  final String? staffCode;
  final String? roleId;
  final String roleName;
  final String? roleDescription;
  final List<UserOutletOptionDto> outlets;
  final int? outletCount;
  final TenantUserAccessSummaryDto? accessSummary;
  final String status;
  final bool permissionOverrideEnabled;
  final List<String> overriddenPermissionIds;
  final DateTime? lastActiveAt;
  final DateTime? createdAt;
  final String? profileImageUrl;
  final String? profileMediaAssetId;
}

class TenantUserAccessSummaryDto {
  const TenantUserAccessSummaryDto({
    required this.outletCount,
    required this.moduleCount,
    required this.permissionCount,
  });

  factory TenantUserAccessSummaryDto.fromJson(Map<String, dynamic> json) {
    return TenantUserAccessSummaryDto(
      outletCount: _intValue(json['outletCount']),
      moduleCount: _intValue(json['moduleCount']),
      permissionCount: _intValue(json['permissionCount']),
    );
  }

  final int outletCount;
  final int moduleCount;
  final int permissionCount;
}

int _intValue(dynamic value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime? _dateValue(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value.toString());
}

List<T> _mapList<T>(
  dynamic raw,
  T Function(Map<String, dynamic> json) mapper,
) {
  if (raw is! List) {
    return const [];
  }

  return raw
      .whereType<Map>()
      .map((item) => mapper(Map<String, dynamic>.from(item)))
      .toList(growable: false);
}

List<String> _stringList(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map((item) => item.toString()).toList(growable: false);
}
