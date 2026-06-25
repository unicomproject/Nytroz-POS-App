import '../mappers/tenant_admin_backend_feature_mapper.dart';

class TenantAdminContextDto {
  const TenantAdminContextDto({
    required this.tenantId,
    required this.tenantName,
    required this.userId,
    required this.userDisplayName,
    required this.roles,
    required this.roleNames,
    required this.outletScope,
    required this.featureEntitlements,
    required this.permissions,
    required this.runtimeFlags,
    this.subscriptionStatus,
  });

  factory TenantAdminContextDto.fromApiJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    if (payload.containsKey('tenant') && payload.containsKey('user')) {
      return TenantAdminContextDto.fromBackendJson(payload);
    }

    return TenantAdminContextDto.fromJson(payload);
  }

  factory TenantAdminContextDto.fromBackendJson(Map<String, dynamic> json) {
    final tenant = _map(json['tenant']);
    final user = _map(json['user']);
    final roles = _mapList(json['roles'], (item) => item);
    final outlets = _mapList(json['outlets'], (item) => item);
    final features = _stringList(json['features']);
    final permissions = _stringList(json['permissions']);
    final runtimeFlags = _stringList(json['runtimeFlags']);
    final subscription = _map(json['subscription']);

    return TenantAdminContextDto(
      tenantId: tenant['id']?.toString() ?? '',
      tenantName: tenant['name']?.toString() ?? '',
      userId: user['id']?.toString() ?? '',
      userDisplayName: user['fullName']?.toString() ?? '',
      roles: [
        for (final role in roles)
          TenantAdminRoleScopeDto(
            roleId: role['id']?.toString() ?? '',
            roleName: role['name']?.toString() ?? '',
          ),
      ],
      roleNames: roles
          .map((role) => role['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList(growable: false),
      outletScope: [
        for (var index = 0; index < outlets.length; index++)
          TenantAdminOutletScopeDto(
            outletId: outlets[index]['id']?.toString() ?? '',
            outletName: outlets[index]['name']?.toString() ?? '',
            isDefault: index == 0,
          ),
      ],
      featureEntitlements: [
        for (final feature in features)
          TenantAdminFeatureEntitlementDto(
            featureCode:
                TenantAdminBackendFeatureMapper.toAppFeatureCode(feature),
            featureName: feature,
            enabled: true,
          ),
      ],
      permissions: [
        for (final permission in permissions)
          TenantAdminPermissionDto(
            permissionCode: permission,
            permissionName: permission,
          ),
      ],
      runtimeFlags: [
        for (final flag in runtimeFlags)
          TenantAdminRuntimeFlagDto(
            featureCode: flag,
            enabled: true,
          ),
      ],
      subscriptionStatus: subscription['status']?.toString(),
    );
  }

  factory TenantAdminContextDto.fromJson(Map<String, dynamic> json) {
    return TenantAdminContextDto(
      tenantId: json['tenantId'] as String? ?? '',
      tenantName: json['tenantName'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userDisplayName: json['userDisplayName'] as String? ?? '',
      roles: _mapList(
        json['roles'],
        TenantAdminRoleScopeDto.fromJson,
      ),
      roleNames: _stringList(json['roleNames']),
      outletScope: _mapList(
        json['outletScope'],
        TenantAdminOutletScopeDto.fromJson,
      ),
      featureEntitlements: _mapList(
        json['featureEntitlements'],
        TenantAdminFeatureEntitlementDto.fromJson,
      ),
      permissions: _mapList(
        json['permissions'],
        TenantAdminPermissionDto.fromJson,
      ),
      runtimeFlags: _mapList(
        json['runtimeFlags'],
        TenantAdminRuntimeFlagDto.fromJson,
      ),
      subscriptionStatus: json['subscriptionStatus'] as String?,
    );
  }

  final String tenantId;
  final String tenantName;
  final String userId;
  final String userDisplayName;
  final List<TenantAdminRoleScopeDto> roles;
  final List<String> roleNames;
  final List<TenantAdminOutletScopeDto> outletScope;
  final List<TenantAdminFeatureEntitlementDto> featureEntitlements;
  final List<TenantAdminPermissionDto> permissions;
  final List<TenantAdminRuntimeFlagDto> runtimeFlags;
  final String? subscriptionStatus;
}

class TenantAdminRoleScopeDto {
  const TenantAdminRoleScopeDto({
    required this.roleId,
    required this.roleName,
  });

  factory TenantAdminRoleScopeDto.fromJson(Map<String, dynamic> json) {
    return TenantAdminRoleScopeDto(
      roleId: (json['roleId'] ?? json['id'])?.toString() ?? '',
      roleName: (json['roleName'] ?? json['name'])?.toString() ?? '',
    );
  }

  final String roleId;
  final String roleName;
}

class TenantAdminOutletScopeDto {
  const TenantAdminOutletScopeDto({
    required this.outletId,
    required this.outletName,
    required this.isDefault,
  });

  factory TenantAdminOutletScopeDto.fromJson(Map<String, dynamic> json) {
    return TenantAdminOutletScopeDto(
      outletId: json['outletId'] as String? ?? '',
      outletName: json['outletName'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  final String outletId;
  final String outletName;
  final bool isDefault;
}

class TenantAdminFeatureEntitlementDto {
  const TenantAdminFeatureEntitlementDto({
    required this.featureCode,
    required this.featureName,
    required this.enabled,
  });

  factory TenantAdminFeatureEntitlementDto.fromJson(Map<String, dynamic> json) {
    return TenantAdminFeatureEntitlementDto(
      featureCode: json['featureCode'] as String? ?? '',
      featureName: json['featureName'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  final String featureCode;
  final String featureName;
  final bool enabled;
}

class TenantAdminPermissionDto {
  const TenantAdminPermissionDto({
    required this.permissionCode,
    required this.permissionName,
  });

  factory TenantAdminPermissionDto.fromJson(Map<String, dynamic> json) {
    return TenantAdminPermissionDto(
      permissionCode: json['permissionCode'] as String? ?? '',
      permissionName: json['permissionName'] as String? ?? '',
    );
  }

  final String permissionCode;
  final String permissionName;
}

class TenantAdminRuntimeFlagDto {
  const TenantAdminRuntimeFlagDto({
    required this.featureCode,
    required this.enabled,
    this.scope,
  });

  factory TenantAdminRuntimeFlagDto.fromJson(Map<String, dynamic> json) {
    return TenantAdminRuntimeFlagDto(
      featureCode: json['featureCode'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      scope: json['scope'] as String?,
    );
  }

  final String featureCode;
  final bool enabled;
  final String? scope;
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const [];
  }

  return value.whereType<String>().toList(growable: false);
}

List<T> _mapList<T>(
  Object? value,
  T Function(Map<String, dynamic> json) mapper,
) {
  if (value is! List) {
    return const [];
  }

  return value
      .whereType<Map>()
      .map((item) => mapper(Map<String, dynamic>.from(item)))
      .toList(growable: false);
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }

  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return const {};
}
