import '../entities/pos_customer.dart';
import '../repositories/customer_repository.dart';

/// Loads recent/searched tenant-scoped customers for the Add Customer flow.
class SearchPosCustomers {
  const SearchPosCustomers(this._repository);

  final CustomerRepository _repository;

  Future<List<PosCustomer>> call({
    required String deviceId,
    String? query,
  }) {
    return _repository.searchCustomers(deviceId: deviceId, query: query);
  }
}
