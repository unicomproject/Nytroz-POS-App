import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/access/tenant_admin_access_codes.dart';
import '../../../../../core/network/dio_provider.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../application/usecases/get_tenant_dashboard.dart';
import '../../data/datasources/tenant_dashboard_remote_datasource.dart';
import '../../data/repositories/tenant_dashboard_repository_impl.dart';
import '../../domain/entities/tenant_dashboard.dart';
import '../../domain/repositories/tenant_dashboard_repository.dart';
import '../../../domain/services/tenant_admin_access_checker.dart';

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

final tenantDashboardProvider = FutureProvider<TenantDashboard?>((ref) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);

  if (!accessChecker.canLoadDashboardData()) {
    return null;
  }

  return ref.watch(getTenantDashboardProvider).call();
});

final tenantDashboardVisibilityProvider =
    Provider<AsyncValue<TenantDashboardVisibility>>((ref) {
  final accessState = ref.watch(tenantAdminAccessCheckerProvider);
  final dashboardState = ref.watch(tenantDashboardProvider);

  return accessState.when(
    loading: () => const AsyncLoading(),
    error: AsyncError.new,
    data: (accessChecker) {
      if (!accessChecker.can(TenantAdminPermissionCodes.tenantAdminDashboardView)) {
        return AsyncData(
          TenantDashboardVisibility.resolve(
            access: accessChecker,
          ),
        );
      }

      return dashboardState.when(
        loading: () => const AsyncLoading(),
        error: (_, __) => AsyncData(
          TenantDashboardVisibility.resolve(
            access: accessChecker,
          ),
        ),
        data: (dashboard) => AsyncData(
          TenantDashboardVisibility.resolve(
            access: accessChecker,
            dashboard: dashboard,
          ),
        ),
      );
    },
  );
});
