import '../entities/tenant_payment_status.dart';
import '../repositories/tenant_admin_auth_repository.dart';

class StartPayment {
  const StartPayment(this._repository);

  final TenantAdminAuthRepository _repository;

  Future<TenantPaymentStatus> call(String paymentToken) {
    return _repository.startPayment(paymentToken);
  }
}
