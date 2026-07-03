import '../../domain/entities/role_permissions.dart';
import '../../domain/repositories/role_permission_repository.dart';

class UpdateRolePermissions {
  const UpdateRolePermissions(this._repository);

  final RolePermissionRepository _repository;

  Future<RolePermissions> call(
    String roleId,
    UpdateRolePermissionsRequest request,
  ) {
    return _repository.updateRolePermissions(roleId, request);
  }
}
