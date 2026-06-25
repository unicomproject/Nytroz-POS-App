class TenantAdminContext {
  const TenantAdminContext({
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

  final String tenantId;
  final String tenantName;
  final String userId;
  final String userDisplayName;
  final List<TenantAdminRoleScope> roles;
  final List<String> roleNames;
  final List<TenantAdminOutletScope> outletScope;
  final List<TenantAdminFeatureEntitlement> featureEntitlements;
  final List<TenantAdminPermission> permissions;
  final List<TenantAdminRuntimeFlag> runtimeFlags;
  final String? subscriptionStatus;
}

class TenantAdminRoleScope {
  const TenantAdminRoleScope({
    required this.roleId,
    required this.roleName,
  });

  final String roleId;
  final String roleName;
}

class TenantAdminOutletScope {
  const TenantAdminOutletScope({
    required this.outletId,
    required this.outletName,
    required this.isDefault,
  });

  final String outletId;
  final String outletName;
  final bool isDefault;
}

class TenantAdminFeatureEntitlement {
  const TenantAdminFeatureEntitlement({
    required this.featureCode,
    required this.featureName,
    required this.enabled,
  });

  final String featureCode;
  final String featureName;
  final bool enabled;
}

class TenantAdminPermission {
  const TenantAdminPermission({
    required this.permissionCode,
    required this.permissionName,
  });

  final String permissionCode;
  final String permissionName;
}

class TenantAdminRuntimeFlag {
  const TenantAdminRuntimeFlag({
    required this.featureCode,
    required this.enabled,
    this.scope,
  });

  final String featureCode;
  final bool enabled;
  final String? scope;
}
