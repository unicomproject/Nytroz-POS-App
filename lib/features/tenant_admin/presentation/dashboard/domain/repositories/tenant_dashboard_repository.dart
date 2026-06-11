import '../entities/tenant_dashboard.dart';

abstract class TenantDashboardRepository {
  Future<TenantDashboard> getDashboard();
}
