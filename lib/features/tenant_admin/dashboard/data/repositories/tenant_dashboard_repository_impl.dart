import 'package:dio/dio.dart';

import '../../domain/entities/tenant_dashboard.dart';
import '../../domain/repositories/tenant_dashboard_repository.dart';
import '../catalog/tenant_admin_dashboard_catalog.dart';
import '../datasources/tenant_dashboard_remote_datasource.dart';
import '../mappers/tenant_dashboard_mapper.dart';

class TenantDashboardRepositoryImpl implements TenantDashboardRepository {
  const TenantDashboardRepositoryImpl(this._remoteDatasource);

  final TenantDashboardRemoteDatasource _remoteDatasource;

  @override
  Future<TenantDashboard> getDashboard() async {
    try {
      final dto = await _remoteDatasource.getDashboard();
      return dto.toEntity();
    } on DioException catch (error) {
      if (_shouldUseCatalogFallback(error)) {
        return tenantAdminDashboardCatalogFallback.toEntity();
      }

      rethrow;
    }
  }
}

bool _shouldUseCatalogFallback(DioException error) {
  final statusCode = error.response?.statusCode;
  return statusCode == 404 || statusCode == 501 || statusCode == 405;
}
