import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class Login {
  const Login(this._repository);

  final AuthRepository _repository;

  Future<AuthSession> call({
    required String tenantCode,
    required String login,
    required String password,
  }) {
    return _repository.login(
      tenantCode: tenantCode,
      login: login,
      password: password,
    );
  }
}
