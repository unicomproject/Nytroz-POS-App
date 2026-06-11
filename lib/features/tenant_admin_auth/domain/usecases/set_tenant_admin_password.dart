import '../repositories/tenant_admin_auth_repository.dart';

class SetTenantAdminPassword {
  const SetTenantAdminPassword(this._repository);

  final TenantAdminAuthRepository _repository;

  Future<void> call({
    required String setupToken,
    required String password,
    required String confirmPassword,
  }) {
    return _repository.setPassword(
      setupToken: setupToken,
      password: password,
      confirmPassword: confirmPassword,
    );
  }
}
