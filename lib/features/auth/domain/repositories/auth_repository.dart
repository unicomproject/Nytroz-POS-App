import '../entities/setup_token_validation.dart';
import '../entities/auth_branding.dart';
import '../entities/auth_session.dart';
import '../entities/tenant_payment_status.dart';
import '../entities/tenant_payment_summary.dart';

abstract class AuthRepository {
  Future<AuthBranding> getAuthBranding();
  Future<TenantPaymentSummary> getPaymentSummary(String paymentToken);
  Future<TenantPaymentStatus> startPayment(String paymentToken);
  Future<TenantPaymentStatus> verifyPaymentStatus(String paymentToken);
  Future<SetupTokenValidation> validateSetupToken(String setupToken);
  Future<void> setPassword({
    required String setupToken,
    required String password,
    required String confirmPassword,
  });
  Future<AuthSession> login({
    required String login,
    required String password,
  });
}
