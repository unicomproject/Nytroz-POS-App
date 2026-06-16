import '../../domain/entities/tenant_admin_context.dart';
import '../models/tenant_admin_context_dto.dart';

extension TenantAdminContextMapper on TenantAdminContextDto {
  TenantAdminContext toEntity() {
    return TenantAdminContext(
      tenantId: tenantId,
      tenantName: tenantName,
      userId: userId,
      userDisplayName: userDisplayName,
      roleNames: roleNames,
      outletScope: outletScope.map((outlet) => outlet.toEntity()).toList(),
      featureEntitlements:
          featureEntitlements.map((feature) => feature.toEntity()).toList(),
      permissions:
          permissions.map((permission) => permission.toEntity()).toList(),
      runtimeFlags: runtimeFlags.map((flag) => flag.toEntity()).toList(),
      subscriptionStatus: subscriptionStatus,
    );
  }
}

extension TenantAdminOutletScopeMapper on TenantAdminOutletScopeDto {
  TenantAdminOutletScope toEntity() {
    return TenantAdminOutletScope(
      outletId: outletId,
      outletName: outletName,
      isDefault: isDefault,
    );
  }
}

extension TenantAdminFeatureEntitlementMapper
    on TenantAdminFeatureEntitlementDto {
  TenantAdminFeatureEntitlement toEntity() {
    return TenantAdminFeatureEntitlement(
      featureCode: featureCode,
      featureName: featureName,
      enabled: enabled,
    );
  }
}

extension TenantAdminPermissionMapper on TenantAdminPermissionDto {
  TenantAdminPermission toEntity() {
    return TenantAdminPermission(
      permissionCode: permissionCode,
      permissionName: permissionName,
    );
  }
}

extension TenantAdminRuntimeFlagMapper on TenantAdminRuntimeFlagDto {
  TenantAdminRuntimeFlag toEntity() {
    return TenantAdminRuntimeFlag(
      featureCode: featureCode,
      enabled: enabled,
      scope: scope,
    );
  }
}
