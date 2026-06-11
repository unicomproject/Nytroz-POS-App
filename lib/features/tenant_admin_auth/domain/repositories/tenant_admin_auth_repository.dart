import '../entities/setup_token_validation.dart';
import '../entities/tenant_admin_session.dart';
import '../entities/tenant_payment_status.dart';
import '../entities/tenant_payment_summary.dart';

abstract class TenantAdminAuthRepository {
  Future<TenantPaymentSummary> getPaymentSummary(String paymentToken);
  Future<TenantPaymentStatus> startPayment(String paymentToken);
  Future<TenantPaymentStatus> verifyPaymentStatus(String paymentToken);
  Future<SetupTokenValidation> validateSetupToken(String setupToken);
  Future<void> setPassword({
    required String setupToken,
    required String password,
    required String confirmPassword,
  });
  Future<TenantAdminSession> login({
    required String email,
    required String password,
  });
}
