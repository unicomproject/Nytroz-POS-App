import '../entities/tenant_payment_summary.dart';
import '../repositories/tenant_admin_auth_repository.dart';

class GetPaymentSummary {
  const GetPaymentSummary(this._repository);

  final TenantAdminAuthRepository _repository;

  Future<TenantPaymentSummary> call(String paymentToken) {
    return _repository.getPaymentSummary(paymentToken);
  }
}
