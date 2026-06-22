import '../../domain/entities/permission_catalog.dart';
import '../../domain/entities/role_permissions.dart';
import '../models/permission_catalog_dto.dart';
import '../models/role_permissions_dto.dart';

extension PermissionCatalogMapper on PermissionCatalogDto {
  PermissionCatalog toEntity() {
    return PermissionCatalog(
      modules: modules.map((module) => module.toEntity()).toList(),
    );
  }
}

extension PermissionCatalogModuleMapper on PermissionCatalogModuleDto {
  PermissionCatalogModule toEntity() {
    return PermissionCatalogModule(
      id: id,
      code: code,
      name: name,
      description: description,
      scope: scope,
      sortOrder: sortOrder,
      isActive: isActive,
      features: features.map((feature) => feature.toEntity()).toList(),
    );
  }
}

extension PermissionCatalogFeatureMapper on PermissionCatalogFeatureDto {
  PermissionCatalogFeature toEntity() {
    return PermissionCatalogFeature(
      id: id,
      code: code,
      name: name,
      description: description,
      entitlementKey: entitlementKey,
      sortOrder: sortOrder,
      isActive: isActive,
      permissions: permissions.map((permission) => permission.toEntity()).toList(),
    );
  }
}

extension PermissionCatalogPermissionMapper on PermissionCatalogPermissionDto {
  PermissionCatalogPermission toEntity() {
    return PermissionCatalogPermission(
      id: id,
      code: code,
      name: name,
      description: description,
      action: action,
      scope: scope,
      sortOrder: sortOrder,
      isActive: isActive,
      source: source,
    );
  }
}

extension RolePermissionsMapper on RolePermissionsDto {
  RolePermissions toEntity() {
    return RolePermissions(
      roleId: roleId,
      roleCode: roleCode,
      roleName: roleName,
      roleScope: roleScope,
      isSystem: isSystem,
      assignedPermissionCodes: assignedPermissionCodes,
      assignedPermissionIds: assignedPermissionIds,
    );
  }
}

extension UpdateRolePermissionsRequestEntityMapper on UpdateRolePermissionsRequest {
  List<String> toPermissionCodes() => permissionCodes;
}
