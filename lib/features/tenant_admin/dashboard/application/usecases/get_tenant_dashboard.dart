import '../../domain/entities/tenant_dashboard.dart';
import '../../domain/repositories/tenant_dashboard_repository.dart';

class GetTenantDashboard {
  const GetTenantDashboard(this._repository);

  final TenantDashboardRepository _repository;

  Future<TenantDashboard> call() {
    return _repository.getDashboard();
  }
}
