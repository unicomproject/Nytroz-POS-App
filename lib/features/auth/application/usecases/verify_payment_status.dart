import '../../domain/entities/tenant_payment_status.dart';
import '../../domain/repositories/auth_repository.dart';

class VerifyPaymentStatus {
  const VerifyPaymentStatus(this._repository);

  final AuthRepository _repository;

  Future<TenantPaymentStatus> call(String paymentToken) {
    return _repository.verifyPaymentStatus(paymentToken);
  }
}
