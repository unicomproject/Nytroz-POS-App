import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../data/datasources/customer_remote_datasource.dart';
import '../../data/repositories/customer_repository_impl.dart';
import '../../domain/entities/pos_customer.dart';
import '../../domain/repositories/customer_repository.dart';
import '../../domain/usecases/create_pos_customer.dart';
import '../../domain/usecases/search_pos_customers.dart';

final customerRemoteDatasourceProvider =
    Provider<CustomerRemoteDatasource>((ref) {
  return CustomerRemoteDatasource(ref.watch(appDioProvider));
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepositoryImpl(ref.watch(customerRemoteDatasourceProvider));
});

final searchPosCustomersProvider = Provider<SearchPosCustomers>((ref) {
  return SearchPosCustomers(ref.watch(customerRepositoryProvider));
});

final createPosCustomerProvider = Provider<CreatePosCustomer>((ref) {
  return CreatePosCustomer(ref.watch(customerRepositoryProvider));
});

/// Live search query typed in the Add Customer dialog.
final customerSearchQueryProvider = StateProvider<String>((ref) => '');

/// Locally selected/attached customer for the current sale (UI state only).
///
/// Holds the cashier's selection so the New Sale flow can attach it to the
/// sale draft. Selection is set from a backend-returned customer (search or
/// create); it never creates a sale or local-only permanent customer.
final selectedCustomerProvider = StateProvider<PosCustomer?>((ref) => null);

/// Tenant-scoped recent/searched customers loaded from the backend.
///
/// Empty query → recent customers; non-empty query → debounced search by
/// name/phone/email. Returns an empty list when the cashier lacks the
/// customer view/create permission or the device/session is not ready. API
/// failures surface as an [AsyncError] so the UI shows an error state instead
/// of faking success.
final customerSearchResultsProvider =
    FutureProvider.autoDispose<List<PosCustomer>>((ref) async {
  final session = ref.watch(authSessionProvider);
  final deviceContext = ref.watch(deviceActivationProvider).deviceContext;
  final query = ref.watch(customerSearchQueryProvider);

  if (session == null || !session.isAuthenticated || deviceContext == null) {
    return const <PosCustomer>[];
  }

  if (!PosPermissionAccess.canViewCustomers(session.permissionCodes.toSet())) {
    return const <PosCustomer>[];
  }

  // Debounce typed search so each keystroke doesn't hit the backend. When the
  // query changes this provider rebuilds and the superseded request's result
  // is discarded by Riverpod.
  if (query.trim().isNotEmpty) {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  _ensureAuthorizationHeader(ref.read(appDioProvider), session);

  return ref.watch(searchPosCustomersProvider).call(
        deviceId: deviceContext.deviceId,
        query: query,
      );
});

void _ensureAuthorizationHeader(Dio dio, AuthSession session) {
  final currentValue = dio.options.headers['Authorization'];
  if (currentValue is String && currentValue.trim().isNotEmpty) {
    return;
  }

  dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
}
