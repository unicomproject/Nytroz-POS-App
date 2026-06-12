import '../../domain/entities/tenant_payment_summary.dart';
import '../../domain/repositories/auth_repository.dart';

class GetPaymentSummary {
  const GetPaymentSummary(this._repository);

  final AuthRepository _repository;

  Future<TenantPaymentSummary> call(String paymentToken) {
    return _repository.getPaymentSummary(paymentToken);
  }
}
