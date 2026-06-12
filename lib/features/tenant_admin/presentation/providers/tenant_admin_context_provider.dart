import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../application/usecases/get_tenant_admin_context.dart';
import '../../data/datasources/tenant_admin_remote_datasource.dart';
import '../../data/repositories/tenant_admin_repository_impl.dart';
import '../../domain/entities/tenant_admin_context.dart';
import '../../domain/repositories/tenant_admin_repository.dart';

final tenantAdminRemoteDatasourceProvider =
    Provider<TenantAdminRemoteDatasource>((ref) {
  return TenantAdminRemoteDatasource(ref.watch(appDioProvider));
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
