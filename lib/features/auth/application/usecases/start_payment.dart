import '../../domain/entities/tenant_payment_status.dart';
import '../../domain/repositories/auth_repository.dart';

class StartPayment {
  const StartPayment(this._repository);

  final AuthRepository _repository;

  Future<TenantPaymentStatus> call(String paymentToken) {
    return _repository.startPayment(paymentToken);
  }
}
