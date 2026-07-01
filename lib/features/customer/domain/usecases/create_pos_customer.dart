import '../entities/pos_customer.dart';
import '../repositories/customer_repository.dart';

/// Creates a tenant-scoped POS customer through the backend and returns the
/// saved record so it can be attached to the current sale.
class CreatePosCustomer {
  const CreatePosCustomer(this._repository);

  final CustomerRepository _repository;

  Future<PosCustomer> call({
    required String deviceId,
    required String fullName,
    required String phone,
    String? email,
  }) {
    return _repository.createCustomer(
      deviceId: deviceId,
      fullName: fullName,
      phone: phone,
      email: email,
    );
  }
}
