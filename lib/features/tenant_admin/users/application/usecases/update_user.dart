import '../../domain/entities/tenant_user.dart';
import '../../domain/repositories/tenant_user_repository.dart';

class UpdateUser {
  const UpdateUser(this._repository);

  final TenantUserRepository _repository;

  Future<TenantUserDetail> call(String id, UserFormData form) {
    return _repository.updateUser(id, form);
  }
}
