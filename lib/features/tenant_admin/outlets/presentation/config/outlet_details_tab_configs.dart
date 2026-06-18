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
    id: 'overview',
    label: 'Overview',
    icon: Icons.dashboard_outlined,
  ),
  OutletDetailsTabConfig(
    id: 'tills',
    permissionsAny: [
      TenantAdminPermissionCodes.tillView,
      TenantAdminPermissionCodes.outletTillSummaryView,
    ],
    label: 'Tills',
    icon: Icons.point_of_sale_outlined,
  ),
  OutletDetailsTabConfig(
    id: 'staff',
    permissionsAny: [
      TenantAdminPermissionCodes.userView,
      TenantAdminPermissionCodes.outletStaffSummaryView,
    ],
    label: 'Staff',
    icon: Icons.people_outline,
  ),
  OutletDetailsTabConfig(
    id: 'sales',
    permission: TenantAdminPermissionCodes.outletSalesSummaryView,
    label: 'Sales',
    icon: Icons.show_chart_outlined,
  ),
  OutletDetailsTabConfig(
    id: 'settings',
    permission: TenantAdminPermissionCodes.outletUpdate,
    label: 'Settings',
    icon: Icons.settings_outlined,
  ),
];

List<OutletDetailsTabConfig> visibleOutletDetailsTabs(
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny,
) {
  return filterOutletConfigs(outletDetailsTabConfigs, can, canAny);
}
