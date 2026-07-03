import '../entities/permission_catalog.dart';
import '../entities/role_permissions.dart';

abstract class RolePermissionRepository {
  Future<PermissionCatalog> getPermissionCatalog();

  Future<RolePermissions> getRolePermissions(String roleId);

  Future<RolePermissions> updateRolePermissions(
    String roleId,
    UpdateRolePermissionsRequest request,
  );
}
