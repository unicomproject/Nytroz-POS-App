import '../entities/permission_catalog.dart';
import '../entities/role_assignment.dart';
import '../entities/role_details.dart';
import '../entities/role_list_item.dart';
import '../entities/role_list_query.dart';
import '../entities/role_permissions.dart';

abstract class RolePermissionRepository {
  Future<PermissionCatalog> getPermissionCatalog();

  Future<RolePermissions> getRolePermissions(String roleId);

  Future<RolePermissions> updateRolePermissions(
    String roleId,
    UpdateRolePermissionsRequest request,
  );

  Future<RoleDetails> createRole(
    String roleName,
    String? description,
    String roleCode, {
    List<String>? permissionCodes,
    List<RoleAssignment>? assignments,
  });

  Future<PaginatedRoleList> getRoles(RoleListQuery query);

  Future<RoleDetails> getRoleById(String roleId);

  Future<void> updateRole(
    String roleId,
    String roleName,
    String? description,
    String roleCode,
    DateTime? expectedUpdatedAt,
  );

  Future<void> updateRoleStatus(
    String roleId,
    bool isActive,
    DateTime? expectedUpdatedAt,
  );

  Future<void> deleteRole(String roleId, DateTime? expectedUpdatedAt);

  Future<List<RoleAssignment>> getRoleAssignments(String roleId);

  Future<void> updateRoleAssignments(String roleId, List<RoleAssignment> assignments);
}
