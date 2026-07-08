import '../../domain/entities/tenant_user.dart';
import '../../domain/repositories/tenant_user_repository.dart';

class GetUserDetail {
  const GetUserDetail(this._repository);

  final TenantUserRepository _repository;

  Future<TenantUserDetail> call(String id) {
    return _repository.getUserById(id);
  }
}
