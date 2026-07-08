import 'package:flutter/material.dart';

import '../../../../../core/access/tenant_admin_access_codes.dart';
import 'outlet_permission_config.dart';

class OutletDetailsTabConfig extends OutletWidgetPermissionConfig {
  const OutletDetailsTabConfig({
    required super.id,
    super.permission,
    super.permissionsAny = const [],
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}

const outletDetailsTabConfigs = <OutletDetailsTabConfig>[
  OutletDetailsTabConfig(
    id: 'revenue',
    permissionsAny: [
      TenantAdminPermissionCodes.tenantOutletsRevenueView,
      TenantAdminPermissionCodes.tenantReportsSalesView,
      TenantAdminPermissionCodes.outletSalesSummaryView,
    ],
    label: 'Revenue',
    icon: Icons.show_chart_outlined,
  ),
  OutletDetailsTabConfig(
    id: 'assigned-users',
    permissionsAny: [
      TenantAdminPermissionCodes.tenantOutletsUsersView,
      TenantAdminPermissionCodes.tenantUsersView,
      TenantAdminPermissionCodes.userView,
    ],
    label: 'Assigned Users',
    icon: Icons.people_outline,
  ),
  OutletDetailsTabConfig(
    id: 'tills',
    permissionsAny: [
      TenantAdminPermissionCodes.tenantOutletsTillsView,
      TenantAdminPermissionCodes.tenantTillsView,
      TenantAdminPermissionCodes.tillView,
    ],
    label: 'Tills',
    icon: Icons.point_of_sale_outlined,
  ),
  OutletDetailsTabConfig(
    id: 'information',
    permissionsAny: [
      TenantAdminPermissionCodes.tenantOutletsDetailsView,
      TenantAdminPermissionCodes.tenantOutletsView,
      TenantAdminPermissionCodes.outletView,
      TenantAdminPermissionCodes.outletDetailView,
    ],
    label: 'Outlet Information',
    icon: Icons.info_outline,
  ),
];

List<OutletDetailsTabConfig> visibleOutletDetailsTabs(
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny,
) {
  return filterOutletConfigs(outletDetailsTabConfigs, can, canAny);
}
