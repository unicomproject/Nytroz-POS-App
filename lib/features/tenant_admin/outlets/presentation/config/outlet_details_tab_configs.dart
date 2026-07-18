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
