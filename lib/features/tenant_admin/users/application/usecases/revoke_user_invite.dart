import '../../domain/entities/tenant_user.dart';
import '../../domain/repositories/tenant_user_repository.dart';

class RevokeUserInvite {
  const RevokeUserInvite(this._repository);

  final TenantUserRepository _repository;

  Future<TenantUserDetail> call(String id) => _repository.revokeInvite(id);
}
