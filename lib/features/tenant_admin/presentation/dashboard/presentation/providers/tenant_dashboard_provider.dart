import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/tenant_admin_context_provider.dart';
import '../../data/datasources/tenant_dashboard_remote_datasource.dart';
import '../../data/repositories/tenant_dashboard_repository_impl.dart';
import '../../domain/entities/tenant_dashboard.dart';
import '../../domain/repositories/tenant_dashboard_repository.dart';
import '../../domain/usecases/get_tenant_dashboard.dart';

final tenantDashboardRemoteDatasourceProvider =
    Provider<TenantDashboardRemoteDatasource>((ref) {
  return TenantDashboardRemoteDatasource(ref.watch(tenantAdminDioProvider));
});

final tenantDashboardRepositoryProvider =
    Provider<TenantDashboardRepository>((ref) {
  return TenantDashboardRepositoryImpl(
    ref.watch(tenantDashboardRemoteDatasourceProvider),
  );
});

final getTenantDashboardProvider = Provider<GetTenantDashboard>((ref) {
  return GetTenantDashboard(ref.watch(tenantDashboardRepositoryProvider));
});

final tenantDashboardProvider = FutureProvider<TenantDashboard>((ref) async {
  return ref.watch(getTenantDashboardProvider).call();
});
