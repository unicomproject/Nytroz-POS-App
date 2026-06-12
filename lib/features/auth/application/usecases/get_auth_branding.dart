import '../../domain/entities/auth_branding.dart';
import '../../domain/repositories/auth_repository.dart';

class GetAuthBranding {
  const GetAuthBranding(this._repository);

  final AuthRepository _repository;

  Future<AuthBranding> call() {
    return _repository.getAuthBranding();
  }
}
