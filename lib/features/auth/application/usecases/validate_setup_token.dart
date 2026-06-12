import '../../domain/entities/setup_token_validation.dart';
import '../../domain/repositories/auth_repository.dart';

class ValidateSetupToken {
  const ValidateSetupToken(this._repository);

  final AuthRepository _repository;

  Future<SetupTokenValidation> call(String setupToken) {
    return _repository.validateSetupToken(setupToken);
  }
}
