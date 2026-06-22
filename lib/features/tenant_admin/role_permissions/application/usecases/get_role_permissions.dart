import '../../domain/entities/role_permissions.dart';
import '../../domain/repositories/role_permission_repository.dart';

class GetRolePermissions {
  const GetRolePermissions(this._repository);

  final RolePermissionRepository _repository;

  Future<RolePermissions> call(String roleId) {
    return _repository.getRolePermissions(roleId);
  }
}
