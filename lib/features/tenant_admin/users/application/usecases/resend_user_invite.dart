import '../../domain/entities/tenant_user.dart';
import '../../domain/repositories/tenant_user_repository.dart';

class ResendUserInvite {
  const ResendUserInvite(this._repository);

  final TenantUserRepository _repository;

  Future<TenantUserDetail> call(String id) => _repository.resendInvite(id);
}
