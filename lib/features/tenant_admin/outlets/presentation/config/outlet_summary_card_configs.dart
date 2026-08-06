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
  final String Function(OutletSummaryDashboard summary) valueBuilder;
  final String Function(OutletSummaryDashboard summary) subtitleBuilder;
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
    id: 'warehouse_outlets',
    permission: TenantAdminPermissionCodes.outletSummaryView,
    title: 'Warehouses',
    icon: Icons.warehouse,
    valueBuilder: _warehouseOutletsValue,
    subtitleBuilder: _warehouseOutletsSubtitle,
  ),
  OutletSummaryCardConfig(
    id: 'needs_attention',
    permission: TenantAdminPermissionCodes.outletSummaryView,
    title: 'Needs Attention',
    icon: Icons.warning_amber,
    status: TenantAdminStatusType.warning,
    valueBuilder: _needsAttentionValue,
    subtitleBuilder: _needsAttentionSubtitle,
  ),
];

String _totalOutletsValue(OutletSummaryDashboard summary) =>
    '${summary.totalOutlets}';

String _totalOutletsSubtitle(OutletSummaryDashboard summary) {
  return '${summary.activeOutlets} Active';
}

String _activeOutletsValue(OutletSummaryDashboard summary) =>
    '${summary.activeOutlets}';

String _activeOutletsSubtitle(OutletSummaryDashboard summary) {
  return '${_percent(summary.activeOutlets, summary.totalOutlets)}% of total';
}

String _warehouseOutletsValue(OutletSummaryDashboard summary) =>
    '${summary.warehouseOutlets}';

String _warehouseOutletsSubtitle(OutletSummaryDashboard summary) {
  return '${_percent(summary.warehouseOutlets, summary.totalOutlets)}% of total';
}

String _needsAttentionValue(OutletSummaryDashboard summary) =>
    summary.needsAttention != null ? '${summary.needsAttention}' : '—';

String _needsAttentionSubtitle(OutletSummaryDashboard summary) {
  return summary.needsAttention != null
      ? 'Requires review'
      : 'Not supported by backend';
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
