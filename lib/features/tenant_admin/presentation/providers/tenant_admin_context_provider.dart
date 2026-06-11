import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/tenant_admin_remote_datasource.dart';
import '../../data/repositories/tenant_admin_repository_impl.dart';
import '../../domain/entities/tenant_admin_context.dart';
import '../../domain/repositories/tenant_admin_repository.dart';
import '../../domain/usecases/get_tenant_admin_context.dart';

final tenantAdminDioProvider = Provider<Dio>((ref) {
  throw UnimplementedError(
    'Override tenantAdminDioProvider with the app Dio client.',
  );
});

final tenantAdminRemoteDatasourceProvider =
    Provider<TenantAdminRemoteDatasource>((ref) {
  return TenantAdminRemoteDatasource(ref.watch(tenantAdminDioProvider));
});

final tenantAdminRepositoryProvider = Provider<TenantAdminRepository>((ref) {
  return TenantAdminRepositoryImpl(
    ref.watch(tenantAdminRemoteDatasourceProvider),
  );
});

final getTenantAdminContextProvider = Provider<GetTenantAdminContext>((ref) {
  return GetTenantAdminContext(ref.watch(tenantAdminRepositoryProvider));
});

final tenantAdminContextProvider =
    FutureProvider<TenantAdminContext>((ref) async {
  return ref.watch(getTenantAdminContextProvider).call();
});
