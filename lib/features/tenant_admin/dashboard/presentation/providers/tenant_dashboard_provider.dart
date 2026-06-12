import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../application/usecases/get_tenant_dashboard.dart';
import '../../data/datasources/tenant_dashboard_remote_datasource.dart';
import '../../data/repositories/tenant_dashboard_repository_impl.dart';
import '../../domain/entities/tenant_dashboard.dart';
import '../../domain/repositories/tenant_dashboard_repository.dart';

final tenantDashboardRemoteDatasourceProvider =
    Provider<TenantDashboardRemoteDatasource>((ref) {
  return TenantDashboardRemoteDatasource(ref.watch(appDioProvider));
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
