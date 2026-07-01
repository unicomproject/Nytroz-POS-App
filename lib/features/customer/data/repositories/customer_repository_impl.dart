import '../../domain/entities/pos_customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../datasources/customer_remote_datasource.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  const CustomerRepositoryImpl(this._remote);

  final CustomerRemoteDatasource _remote;

  @override
  Future<List<PosCustomer>> searchCustomers({
    required String deviceId,
    String? query,
  }) {
    return _remote.searchCustomers(deviceId: deviceId, query: query);
  }

  @override
  Future<PosCustomer> createCustomer({
    required String deviceId,
    required String fullName,
    required String phone,
    String? email,
  }) {
    return _remote.createCustomer(
      deviceId: deviceId,
      fullName: fullName,
      phone: phone,
      email: email,
    );
  }
}
