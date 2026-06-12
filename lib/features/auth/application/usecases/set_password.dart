import '../../domain/repositories/auth_repository.dart';

class SetPassword {
  const SetPassword(this._repository);

  final AuthRepository _repository;

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
