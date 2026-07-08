import '../../domain/entities/tenant_user.dart';
import '../../domain/repositories/tenant_user_repository.dart';

class CreateUser {
  const CreateUser(this._repository);

  final TenantUserRepository _repository;

  Future<TenantUserDetail> call(UserFormData form) {
    return _repository.createUser(form);
  }
}
