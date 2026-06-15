import '../../domain/entities/setup_token_validation.dart';
import '../../domain/entities/auth_branding.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/tenant_payment_status.dart';
import '../../domain/entities/tenant_payment_summary.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../mappers/auth_mapper.dart';
import '../models/set_password_request_dto.dart';
import '../models/login_request_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDatasource);

  final AuthRemoteDatasource _remoteDatasource;

  @override
  Future<AuthBranding> getAuthBranding() async {
    return (await _remoteDatasource.getAuthBranding()).toEntity();
  }

  @override
  Future<TenantPaymentSummary> getPaymentSummary(String paymentToken) async {
    return (await _remoteDatasource.getPaymentSummary(paymentToken)).toEntity();
  }

  @override
  Future<TenantPaymentStatus> startPayment(String paymentToken) async {
    return (await _remoteDatasource.startPayment(paymentToken)).toEntity();
  }

  @override
  Future<TenantPaymentStatus> verifyPaymentStatus(String paymentToken) async {
    return (await _remoteDatasource.verifyPaymentStatus(paymentToken))
        .toEntity();
  }

  @override
  Future<SetupTokenValidation> validateSetupToken(String setupToken) async {
    return (await _remoteDatasource.validateSetupToken(setupToken)).toEntity();
  }

  @override
  Future<void> setPassword({
    required String setupToken,
    required String password,
    required String confirmPassword,
  }) {
    return _remoteDatasource.setPassword(
      SetPasswordRequestDto(
        setupToken: setupToken,
        password: password,
        confirmPassword: confirmPassword,
      ),
    );
  }

  @override
  Future<AuthSession> login({
    required String tenantCode,
    required String login,
    required String password,
  }) async {
    final json = await _remoteDatasource.login(
      LoginRequestDto(
        tenantCode: tenantCode,
        login: login,
        password: password,
      ),
    );
    return authSessionFromJson(json);
  }
}
