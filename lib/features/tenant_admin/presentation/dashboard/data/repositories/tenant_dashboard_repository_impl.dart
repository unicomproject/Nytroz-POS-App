import '../../domain/entities/tenant_dashboard.dart';
import '../../domain/repositories/tenant_dashboard_repository.dart';
import '../datasources/tenant_dashboard_remote_datasource.dart';
import '../mappers/tenant_dashboard_mapper.dart';

class TenantDashboardRepositoryImpl implements TenantDashboardRepository {
  const TenantDashboardRepositoryImpl(this._remoteDatasource);

  final TenantDashboardRemoteDatasource _remoteDatasource;

  @override
  Future<TenantDashboard> getDashboard() async {
    final dto = await _remoteDatasource.getDashboard();
    return dto.toEntity();
  }
}
