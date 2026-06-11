import '../entities/setup_token_validation.dart';
import '../repositories/tenant_admin_auth_repository.dart';

class ValidateSetupToken {
  const ValidateSetupToken(this._repository);

  final TenantAdminAuthRepository _repository;

  Future<SetupTokenValidation> call(String setupToken) {
    return _repository.validateSetupToken(setupToken);
  }
}
