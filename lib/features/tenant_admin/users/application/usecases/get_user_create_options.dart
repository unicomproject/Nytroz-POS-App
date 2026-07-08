import '../../domain/entities/tenant_user.dart';
import '../../domain/repositories/tenant_user_repository.dart';

class GetUserCreateOptions {
  const GetUserCreateOptions(this._repository);

  final TenantUserRepository _repository;

  Future<TenantUserCreateOptions> call() {
    return _repository.getCreateOptions();
  }
}
