import '../entities/tenant_admin_session.dart';
import '../repositories/tenant_admin_auth_repository.dart';

class LoginTenantAdmin {
  const LoginTenantAdmin(this._repository);

  final TenantAdminAuthRepository _repository;

  Future<TenantAdminSession> call({
    required String email,
    required String password,
  }) {
    return _repository.login(email: email, password: password);
  }
}
