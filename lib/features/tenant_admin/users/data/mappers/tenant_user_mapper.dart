import '../../domain/entities/tenant_user.dart';
import '../models/tenant_user_dto.dart';

class TenantUserMapper {
  const TenantUserMapper._();

  static TenantUser toEntity(TenantUserListItemDto dto) {
    return TenantUser(
      id: dto.id,
      fullName: dto.fullName,
      email: dto.email,
      phone: dto.phone,
      staffCode: dto.staffCode,
      profileImageUrl: dto.profileImageUrl,
      roleId: dto.roleId,
      roleName: dto.roleName,
      roleDescription: dto.roleDescription,
      outletName: dto.outletName,
      outlets: dto.outlets.map(toOutletOption).toList(growable: false),
      outletCount: dto.outletCount,
      status: dto.status,
      lastActiveAt: dto.lastActiveAt,
    );
  }

  static TenantUserListResult toListResult(TenantUserListResultDto dto) {
    return TenantUserListResult(
      items: dto.items.map(toEntity).toList(growable: false),
      page: dto.page,
      pageSize: dto.pageSize,
      totalCount: dto.totalCount,
    );
  }

  static RoleOption toRoleOption(RoleOptionDto dto) {
    return RoleOption(
      id: dto.id,
      name: dto.name,
      code: dto.code,
      roleDescription: dto.roleDescription,
    );
  }

  static UserOutletOption toOutletOption(UserOutletOptionDto dto) {
    return UserOutletOption(
      id: dto.id,
      name: dto.name,
      code: dto.code,
      status: dto.status,
    );
  }

  static PermissionItem toPermissionItem(PermissionItemDto dto) {
    return PermissionItem(
      id: dto.id,
      code: dto.code,
      actionType: dto.actionType,
      description: dto.description,
    );
  }

  static PermissionGroup toPermissionGroup(PermissionGroupDto dto) {
    return PermissionGroup(
      groupName: dto.groupName,
      permissions:
          dto.permissions.map(toPermissionItem).toList(growable: false),
    );
  }

  static TenantUserCreateOptions toCreateOptions(
    TenantUserCreateOptionsDto dto,
  ) {
    return TenantUserCreateOptions(
      roles: dto.roles.map(toRoleOption).toList(growable: false),
      outlets: dto.outlets.map(toOutletOption).toList(growable: false),
      permissionGroups:
          dto.permissionGroups.map(toPermissionGroup).toList(growable: false),
    );
  }

  static TenantUserDetail toDetailEntity(TenantUserDetailDto dto) {
    return TenantUserDetail(
      id: dto.id,
      fullName: dto.fullName,
      email: dto.email,
      phone: dto.phone,
      roleId: dto.roleId,
      roleName: dto.roleName,
      roleDescription: dto.roleDescription,
      outlets: dto.outlets.map(toOutletOption).toList(growable: false),
      outletCount: dto.outletCount,
      accessSummary: dto.accessSummary == null
          ? null
          : TenantUserAccessSummary(
              outletCount: dto.accessSummary!.outletCount,
              moduleCount: dto.accessSummary!.moduleCount,
              permissionCount: dto.accessSummary!.permissionCount,
            ),
      status: dto.status,
      permissionOverrideEnabled: dto.permissionOverrideEnabled,
      overriddenPermissionIds: dto.overriddenPermissionIds,
      lastActiveAt: dto.lastActiveAt,
      createdAt: dto.createdAt,
      profileImageUrl: dto.profileImageUrl,
      profileMediaAssetId: dto.profileMediaAssetId,
    );
  }
}
