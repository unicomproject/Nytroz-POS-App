class TenantAdminContextDto {
  const TenantAdminContextDto({
    required this.tenantId,
    required this.tenantName,
    required this.userId,
    required this.userDisplayName,
    required this.roleNames,
    required this.outletScope,
    required this.featureEntitlements,
    required this.permissions,
    required this.runtimeFlags,
    this.subscriptionStatus,
  });

  factory TenantAdminContextDto.fromJson(Map<String, dynamic> json) {
    return TenantAdminContextDto(
      tenantId: json['tenantId'] as String? ?? '',
      tenantName: json['tenantName'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userDisplayName: json['userDisplayName'] as String? ?? '',
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
  final List<String> roleNames;
  final List<TenantAdminOutletScopeDto> outletScope;
  final List<TenantAdminFeatureEntitlementDto> featureEntitlements;
  final List<TenantAdminPermissionDto> permissions;
  final List<TenantAdminRuntimeFlagDto> runtimeFlags;
  final String? subscriptionStatus;
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
