import '../../domain/entities/permission_catalog.dart';
import '../../domain/entities/role_permissions.dart';
import '../../domain/repositories/role_permission_repository.dart';
import '../datasources/role_permission_remote_datasource.dart';
import '../mappers/role_permission_mapper.dart';
import '../models/update_role_permissions_request_dto.dart';

class RolePermissionRepositoryImpl implements RolePermissionRepository {
  const RolePermissionRepositoryImpl(this._remoteDatasource);

  final RolePermissionRemoteDatasource _remoteDatasource;

  @override
  Future<PermissionCatalog> getPermissionCatalog() async {
    final dto = await _remoteDatasource.getPermissionCatalog();
    return dto.toEntity();
  }

  @override
  Future<RolePermissions> getRolePermissions(String roleId) async {
    final dto = await _remoteDatasource.getRolePermissions(roleId);
    return dto.toEntity();
  }

  @override
  Future<RolePermissions> updateRolePermissions(
    String roleId,
    UpdateRolePermissionsRequest request,
  ) async {
    final dto = await _remoteDatasource.updateRolePermissions(
      roleId,
      UpdateRolePermissionsRequestDto(
        permissionCodes: request.permissionCodes,
      ),
    );
    return dto.toEntity();
  }
}
