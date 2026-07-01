import '../entities/pos_customer.dart';

/// Tenant-scoped POS customer data contract. Implementations talk to the
/// backend (`/api/v1/customers`) through the remote datasource; the UI must
/// never call the API directly.
abstract class CustomerRepository {
  /// Loads tenant-scoped customers. When [query] is empty the backend returns
  /// recent/active customers; otherwise it searches by name, phone or email.
  Future<List<PosCustomer>> searchCustomers({
    required String deviceId,
    String? query,
  });

  /// Creates a tenant-scoped POS customer and returns the saved record.
  Future<PosCustomer> createCustomer({
    required String deviceId,
    required String fullName,
    required String phone,
    String? email,
  });
}
