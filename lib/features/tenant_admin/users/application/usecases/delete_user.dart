import '../../domain/repositories/tenant_user_repository.dart';

class DeleteUser {
  const DeleteUser(this._repository);

  final TenantUserRepository _repository;

  Future<void> call(String id) {
    return _repository.deleteUser(id);
  }
}
