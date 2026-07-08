class TenantUserListItemDto {
  const TenantUserListItemDto({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.roleId,
    required this.roleName,
    required this.outletName,
    required this.status,
    this.lastActiveAt,
  });

  factory TenantUserListItemDto.fromJson(Map<String, dynamic> json) {
    return TenantUserListItemDto(
      id: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phoneNumber'] as String? ?? json['phone'] as String?,
      roleId: json['roleId']?.toString(),
      roleName: json['roleName'] as String? ?? '',
      outletName: json['outletName'] as String? ?? '',
      status: json['status'] as String? ?? '',
      lastActiveAt: _dateValue(json['lastActiveAt']),
    );
  }

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? roleId;
  final String roleName;
  final String outletName;
  final String status;
  final DateTime? lastActiveAt;
}

class TenantUserListResultDto {
  const TenantUserListResultDto({
    required this.items,
    this.page = 1,
    this.pageSize = 10,
    this.totalCount = 0,
  });

  factory TenantUserListResultDto.fromJson(Map<String, dynamic> json) {
    final items = _mapList(json['items'], TenantUserListItemDto.fromJson);
    final page = _intValue(json['page'], fallback: 1);
    final pageSize = _intValue(json['pageSize'], fallback: 10);
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
  });

  factory RoleOptionDto.fromJson(Map<String, dynamic> json) {
    return RoleOptionDto(
      id: json['roleId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['roleName'] as String? ?? json['name'] as String? ?? '',
      code: json['roleCode'] as String? ?? json['code'] as String? ?? '',
    );
  }

  final String id;
  final String name;
  final String code;
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
  });

  factory PermissionItemDto.fromJson(Map<String, dynamic> json) {
    return PermissionItemDto(
      id: json['permissionId']?.toString() ?? json['id']?.toString() ?? '',
      code: json['permissionCode'] as String? ?? json['code'] as String? ?? '',
      actionType: json['actionType'] as String? ?? '',
      description: json['description'] as String?,
    );
  }

  final String id;
  final String code;
  final String actionType;
  final String? description;
}

class PermissionGroupDto {
  const PermissionGroupDto({
    required this.groupName,
    required this.permissions,
  });

  factory PermissionGroupDto.fromJson(Map<String, dynamic> json) {
    return PermissionGroupDto(
      groupName: json['groupName'] as String? ?? '',
      permissions: _mapList(json['permissions'], PermissionItemDto.fromJson),
    );
  }

  final String groupName;
  final List<PermissionItemDto> permissions;
}

class TenantUserCreateOptionsDto {
  const TenantUserCreateOptionsDto({
    required this.roles,
    required this.outlets,
    required this.permissionGroups,
  });

  factory TenantUserCreateOptionsDto.fromJson(Map<String, dynamic> json) {
    return TenantUserCreateOptionsDto(
      roles: _mapList(json['roles'], RoleOptionDto.fromJson),
      outlets: _mapList(json['outlets'], UserOutletOptionDto.fromJson),
      permissionGroups:
          _mapList(json['permissionGroups'], PermissionGroupDto.fromJson),
    );
  }

  final List<RoleOptionDto> roles;
  final List<UserOutletOptionDto> outlets;
  final List<PermissionGroupDto> permissionGroups;
}

class TenantUserDetailDto {
  const TenantUserDetailDto({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.roleId,
    required this.roleName,
    required this.outlets,
    required this.status,
    required this.permissionOverrideEnabled,
    required this.overriddenPermissionIds,
    this.lastActiveAt,
    this.createdAt,
    this.profileImageUrl,
  });

  factory TenantUserDetailDto.fromJson(Map<String, dynamic> json) {
    return TenantUserDetailDto(
      id: json['userId']?.toString() ?? json['id']?.toString() ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phoneNumber'] as String? ?? json['phone'] as String?,
      roleId: json['roleId']?.toString(),
      roleName: json['roleName'] as String? ?? '',
      outlets: _mapList(json['outlets'], UserOutletOptionDto.fromJson),
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
    );
  }

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? roleId;
  final String roleName;
  final List<UserOutletOptionDto> outlets;
  final String status;
  final bool permissionOverrideEnabled;
  final List<String> overriddenPermissionIds;
  final DateTime? lastActiveAt;
  final DateTime? createdAt;
  final String? profileImageUrl;
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
