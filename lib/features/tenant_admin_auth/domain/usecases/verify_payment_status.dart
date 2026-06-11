import '../entities/tenant_payment_status.dart';
import '../repositories/tenant_admin_auth_repository.dart';

class VerifyPaymentStatus {
  const VerifyPaymentStatus(this._repository);

  final TenantAdminAuthRepository _repository;

  Future<TenantPaymentStatus> call(String paymentToken) {
    return _repository.verifyPaymentStatus(paymentToken);
  }
}
