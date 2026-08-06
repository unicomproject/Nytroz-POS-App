import 'package:flutter/material.dart';

import '../../domain/entities/till_monitoring.dart';

import '../../../../../core/access/tenant_admin_access_codes.dart';
import '../../../presentation/widgets/tenant_admin_status_badge.dart';
import 'till_permission_config.dart';

enum TillRowActionId {
  viewDetails,
  edit,
  delete,
  generateActivationCode,
}

class TillRowActionConfig extends TillWidgetPermissionConfig {
  const TillRowActionConfig({
    required super.id,
    required this.actionId,
    required this.label,
    required this.icon,
    super.permission,
    super.permissionsAny = const [],
    super.showInMoreMenu = false,
  });

  final TillRowActionId actionId;
  final String label;
  final IconData icon;
}

const tillRowActionConfigs = <TillRowActionConfig>[
  TillRowActionConfig(
    id: 'view_details',
    actionId: TillRowActionId.viewDetails,
    label: 'View details',
    icon: Icons.visibility_outlined,
    permission: TenantAdminPermissionCodes.tillView,
  ),
  TillRowActionConfig(
    id: 'edit',
    actionId: TillRowActionId.edit,
    label: 'Edit',
    icon: Icons.edit_outlined,
    permission: TenantAdminPermissionCodes.tillUpdate,
  ),
  TillRowActionConfig(
    id: 'delete',
    actionId: TillRowActionId.delete,
    label: 'Deactivate till',
    icon: Icons.delete_outline,
    permission: TenantAdminPermissionCodes.tillDelete,
    showInMoreMenu: true,
  ),
  TillRowActionConfig(
    id: 'activation_code',
    actionId: TillRowActionId.generateActivationCode,
    label: 'Generate activation code',
    icon: Icons.qr_code_2_outlined,
    permission: TenantAdminPermissionCodes.tillActivationCodeGenerate,
    showInMoreMenu: true,
  ),
];

List<TillRowActionConfig> visibleTillRowActions(
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny,
) {
  return filterTillConfigs(
    tillRowActionConfigs.where((config) => !config.showInMoreMenu).toList(),
    can,
    canAny,
  );
}

List<TillRowActionConfig> visibleTillMoreMenuActions(
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny,
) {
  return filterTillConfigs(
    tillRowActionConfigs.where((config) => config.showInMoreMenu).toList(),
    can,
    canAny,
  );
}

class TillSummaryCardConfig extends TillWidgetPermissionConfig {
  const TillSummaryCardConfig({
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
  final String Function(TillMonitoringSummary summary) valueBuilder;
  final String Function(TillMonitoringSummary summary) subtitleBuilder;
}

const tillSummaryCardConfigs = <TillSummaryCardConfig>[
  TillSummaryCardConfig(
    id: 'total_tills',
    permission: TenantAdminPermissionCodes.tillView,
    title: 'Total tills',
    icon: Icons.point_of_sale_outlined,
    valueBuilder: _totalTillsValue,
    subtitleBuilder: _totalTillsSubtitle,
  ),
  TillSummaryCardConfig(
    id: 'online',
    permission: TenantAdminPermissionCodes.tillView,
    title: 'Online',
    icon: Icons.wifi,
    status: TenantAdminStatusType.online,
    valueBuilder: _onlineValue,
    subtitleBuilder: _onlineSubtitle,
  ),
  TillSummaryCardConfig(
    id: 'offline',
    permission: TenantAdminPermissionCodes.tillView,
    title: 'Offline',
    icon: Icons.wifi_off,
    status: TenantAdminStatusType.offline,
    valueBuilder: _offlineValue,
    subtitleBuilder: _offlineSubtitle,
  ),
  TillSummaryCardConfig(
    id: 'needs_attention',
    permission: TenantAdminPermissionCodes.tillView,
    title: 'Need attention',
    icon: Icons.warning_amber_rounded,
    status: TenantAdminStatusType.warning,
    valueBuilder: _needsAttentionValue,
    subtitleBuilder: _needsAttentionSubtitle,
  ),
];

String _totalTillsValue(TillMonitoringSummary summary) =>
    '${summary.totalTills}';

String _totalTillsSubtitle(TillMonitoringSummary summary) =>
    'Across all outlets';

String _onlineValue(TillMonitoringSummary summary) => '${summary.onlineCount}';

String _onlineSubtitle(TillMonitoringSummary summary) {
  return '${_percent(summary.onlineCount, summary.totalTills)}% of total';
}

String _offlineValue(TillMonitoringSummary summary) =>
    '${summary.offlineCount}';

String _offlineSubtitle(TillMonitoringSummary summary) {
  return '${_percent(summary.offlineCount, summary.totalTills)}% of total';
}

String _needsAttentionValue(TillMonitoringSummary summary) =>
    '${summary.needsAttentionCount}';

String _needsAttentionSubtitle(TillMonitoringSummary summary) {
  return '${_percent(summary.needsAttentionCount, summary.totalTills)}% of total';
}

int _percent(int value, int total) {
  if (total <= 0) {
    return 0;
  }

  return ((value / total) * 100).round();
}

List<TillSummaryCardConfig> visibleTillSummaryCards(
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny,
) {
  return filterTillConfigs(tillSummaryCardConfigs, can, canAny);
}
