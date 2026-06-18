import 'package:flutter/material.dart';

import '../../../../../core/access/tenant_admin_access_codes.dart';
import 'outlet_permission_config.dart';

class OutletDetailsQuickActionConfig extends OutletWidgetPermissionConfig {
  const OutletDetailsQuickActionConfig({
    required super.id,
    super.permission,
    super.permissionsAny = const [],
    required this.title,
    required this.icon,
    required this.routeBuilder,
  });

  final String title;
  final IconData icon;
  final String Function(String outletId) routeBuilder;
}

const outletDetailsQuickActionConfigs = <OutletDetailsQuickActionConfig>[
  OutletDetailsQuickActionConfig(
    id: 'edit_outlet',
    permission: TenantAdminPermissionCodes.outletUpdate,
    title: 'Edit outlet',
    icon: Icons.edit_outlined,
    routeBuilder: _editRoute,
  ),
  OutletDetailsQuickActionConfig(
    id: 'add_till',
    permission: TenantAdminPermissionCodes.tillCreate,
    title: 'Add till',
    icon: Icons.add_circle_outline,
    routeBuilder: _addTillRoute,
  ),
  OutletDetailsQuickActionConfig(
    id: 'add_staff',
    permission: TenantAdminPermissionCodes.userCreate,
    title: 'Add staff',
    icon: Icons.person_add_outlined,
    routeBuilder: _addStaffRoute,
  ),
  OutletDetailsQuickActionConfig(
    id: 'view_sales_report',
    permission: TenantAdminPermissionCodes.reportSalesView,
    title: 'View sales report',
    icon: Icons.insert_chart_outlined,
    routeBuilder: _salesReportRoute,
  ),
];

String _editRoute(String outletId) => '/tenant-admin/outlets/$outletId/edit';

String _addTillRoute(String outletId) => '/tenant-admin/tills/add';

String _addStaffRoute(String outletId) => '/tenant-admin/staff/add';

String _salesReportRoute(String outletId) => '/tenant-admin/reports/sales';

List<OutletDetailsQuickActionConfig> visibleOutletDetailsQuickActions(
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny,
) {
  return filterOutletConfigs(outletDetailsQuickActionConfigs, can, canAny);
}
