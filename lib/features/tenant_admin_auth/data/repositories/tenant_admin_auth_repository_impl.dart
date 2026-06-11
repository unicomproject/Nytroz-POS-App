import '../../domain/entities/setup_token_validation.dart';
import '../../domain/entities/tenant_admin_session.dart';
import '../../domain/entities/tenant_payment_status.dart';
import '../../domain/entities/tenant_payment_summary.dart';
import '../../domain/repositories/tenant_admin_auth_repository.dart';
import '../datasources/tenant_admin_auth_remote_datasource.dart';
import '../mappers/tenant_admin_auth_mapper.dart';
import '../models/set_password_request_dto.dart';
import '../models/tenant_admin_login_request_dto.dart';

class TenantAdminAuthRepositoryImpl implements TenantAdminAuthRepository {
  const TenantAdminAuthRepositoryImpl(this._remoteDatasource);

  final TenantAdminAuthRemoteDatasource _remoteDatasource;

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
  Future<TenantAdminSession> login({
    required String email,
    required String password,
  }) async {
    final json = await _remoteDatasource.login(
      TenantAdminLoginRequestDto(email: email, password: password),
    );
    return tenantAdminSessionFromJson(json);
  }
}
