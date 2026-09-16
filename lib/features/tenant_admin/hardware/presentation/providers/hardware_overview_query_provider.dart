import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../presentation/providers/tenant_admin_context_provider.dart';
import 'hardware_dashboard_provider.dart';

/// Retain navigation filters for this session; refresh scope resets the query.
final hardwareOverviewQueryProvider =
    StateProvider<HardwareDashboardQuery>((ref) {
  ref.watch(tenantAdminContextProvider);
  return (
    page: 1,
    outletId: null,
    search: '',
    type: '',
    status: '',
    sort: 'name'
  );
});
