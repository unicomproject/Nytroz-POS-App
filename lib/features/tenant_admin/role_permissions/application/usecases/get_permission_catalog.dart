import '../../domain/entities/permission_catalog.dart';
import '../../domain/repositories/role_permission_repository.dart';

class GetPermissionCatalog {
  const GetPermissionCatalog(this._repository);

  final RolePermissionRepository _repository;

  Future<PermissionCatalog> call() {
    return _repository.getPermissionCatalog();
  }
}
