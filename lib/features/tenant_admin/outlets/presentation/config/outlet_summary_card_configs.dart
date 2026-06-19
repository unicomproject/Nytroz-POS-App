import 'package:flutter/material.dart';

import '../../../../../core/access/tenant_admin_access_codes.dart';
import '../../domain/entities/outlet.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import 'outlet_permission_config.dart';

class OutletSummaryCardConfig extends OutletWidgetPermissionConfig {
  const OutletSummaryCardConfig({
    required super.id,
    super.permission,
    super.permissionsAny = const [],
    required this.title,
    required this.icon,
    this.status,
    required this.valueBuilder,
    required this.subtitleBuilder,
  });

  final String title;
  final IconData icon;
  final TenantAdminStatusType? status;
  final String Function(OutletListSummary summary) valueBuilder;
  final String Function(OutletListSummary summary) subtitleBuilder;
}

const outletSummaryCardConfigs = <OutletSummaryCardConfig>[
  OutletSummaryCardConfig(
    id: 'total_outlets',
    permission: TenantAdminPermissionCodes.outletSummaryView,
    title: 'Total Outlets',
    icon: Icons.store,
    valueBuilder: _totalOutletsValue,
    subtitleBuilder: _totalOutletsSubtitle,
  ),
  OutletSummaryCardConfig(
    id: 'active_outlets',
    permission: TenantAdminPermissionCodes.outletSummaryView,
    title: 'Active Outlets',
    icon: Icons.check_circle,
    status: TenantAdminStatusType.active,
    valueBuilder: _activeOutletsValue,
    subtitleBuilder: _activeOutletsSubtitle,
  ),
  OutletSummaryCardConfig(
    id: 'inactive_outlets',
    permission: TenantAdminPermissionCodes.outletSummaryView,
    title: 'Inactive Outlets',
    icon: Icons.pause_circle_filled,
    status: TenantAdminStatusType.inactive,
    valueBuilder: _inactiveOutletsValue,
    subtitleBuilder: _inactiveOutletsSubtitle,
  ),
  OutletSummaryCardConfig(
    id: 'total_locations',
    permissionsAny: [
      TenantAdminPermissionCodes.outletLocationSummaryView,
      TenantAdminPermissionCodes.outletSummaryView,
    ],
    title: 'Total Locations',
    icon: Icons.location_on,
    valueBuilder: _totalLocationsValue,
    subtitleBuilder: _totalLocationsSubtitle,
  ),
];

String _totalOutletsValue(OutletListSummary summary) =>
    '${summary.totalOutlets}';

String _totalOutletsSubtitle(OutletListSummary summary) {
  return '${summary.activeOutlets} Active • ${summary.inactiveOutlets} Inactive';
}

String _activeOutletsValue(OutletListSummary summary) =>
    '${summary.activeOutlets}';

String _activeOutletsSubtitle(OutletListSummary summary) {
  return '${_percent(summary.activeOutlets, summary.totalOutlets)}% of total';
}

String _inactiveOutletsValue(OutletListSummary summary) =>
    '${summary.inactiveOutlets}';

String _inactiveOutletsSubtitle(OutletListSummary summary) {
  return '${_percent(summary.inactiveOutlets, summary.totalOutlets)}% of total';
}

String _totalLocationsValue(OutletListSummary summary) =>
    '${summary.totalLocations}';

String _totalLocationsSubtitle(OutletListSummary summary) {
  return 'Across all outlets';
}

int _percent(int value, int total) {
  if (total <= 0) {
    return 0;
  }

  return ((value / total) * 100).round();
}

List<OutletSummaryCardConfig> visibleOutletSummaryCards(
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny,
) {
  return filterOutletConfigs(outletSummaryCardConfigs, can, canAny);
}
