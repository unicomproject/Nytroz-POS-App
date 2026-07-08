import '../../domain/entities/tenant_user.dart';
import '../../domain/repositories/tenant_user_repository.dart';

class GetUsers {
  const GetUsers(this._repository);

  final TenantUserRepository _repository;

  Future<TenantUserListResult> call({required TenantUserListQuery query}) {
    return _repository.getUsers(query: query);
  }
}
