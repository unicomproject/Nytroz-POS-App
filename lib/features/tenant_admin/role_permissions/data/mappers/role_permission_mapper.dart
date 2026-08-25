import '../../domain/entities/permission_catalog.dart';
import '../../domain/entities/role_details.dart';
import '../../domain/entities/role_list_item.dart';
import '../../domain/entities/role_permissions.dart';
import '../models/permission_catalog_dto.dart';
import '../models/role_list_dto.dart';
import '../models/role_permissions_dto.dart';

class RolePermissionMapper {
  static PaginatedRoleList toPaginatedRoleList(RoleListResponseDto dto) {
    return PaginatedRoleList(
      items: dto.items.map(toRoleListItem).toList(),
      page: dto.page,
      pageSize: dto.pageSize,
      totalCount: dto.totalCount,
      totalPages: dto.totalPages,
    );
  }

  static RoleListItem toRoleListItem(RoleListItemDto dto) {
    return RoleListItem(
      id: dto.roleId,
      code: dto.roleCode,
      name: dto.roleName,
      description: dto.roleDescription,
      isActive: dto.isActive,
      isSystem: dto.isSystem,
      permissionCount: dto.permissionCount,
      userCount: dto.userCount,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  static RoleDetails toRoleDetails(Map<String, dynamic> response) {
    return RoleDetails(
      id: response['roleId'] as String,
      name: response['roleName'] as String,
      description: response['roleDescription'] as String?,
      templateCode: response['roleCode'] as String,
      status: (response['isActive'] as bool?) == true ? 'Active' : 'Inactive',
      isSystem: (response['isSystem'] as bool?) == true,
    );
  }
}

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
      permissions:
          permissions.map((permission) => permission.toEntity()).toList(),
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

extension UpdateRolePermissionsRequestEntityMapper
    on UpdateRolePermissionsRequest {
  List<String> toPermissionCodes() => permissionCodes;
}
