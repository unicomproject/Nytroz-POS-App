import 'package:flutter/material.dart';

import '../../../../../core/access/tenant_admin_access_codes.dart';
import '../../domain/entities/outlet_details.dart';
import 'outlet_permission_config.dart';

class OutletDetailsMetricConfig extends OutletWidgetPermissionConfig {
  const OutletDetailsMetricConfig({
    required super.id,
    super.permission,
    super.permissionsAny = const [],
    required this.title,
    required this.icon,
    required this.valueBuilder,
    required this.subtitleBuilder,
    this.trendBuilder,
  });

  final String title;
  final IconData icon;
  final String? Function(OutletDetails outlet) valueBuilder;
  final String? Function(OutletDetails outlet) subtitleBuilder;
  final String? Function(OutletDetails outlet)? trendBuilder;
}

const outletDetailsMetricConfigs = <OutletDetailsMetricConfig>[
  OutletDetailsMetricConfig(
    id: 'tills',
    permissionsAny: [
      TenantAdminPermissionCodes.tillView,
      TenantAdminPermissionCodes.outletTillSummaryView,
    ],
    title: 'Tills',
    icon: Icons.point_of_sale,
    valueBuilder: _tillsValue,
    subtitleBuilder: _tillsSubtitle,
  ),
  OutletDetailsMetricConfig(
    id: 'staff',
    permissionsAny: [
      TenantAdminPermissionCodes.userView,
      TenantAdminPermissionCodes.outletStaffSummaryView,
    ],
    title: 'Staff',
    icon: Icons.people,
    valueBuilder: _staffValue,
    subtitleBuilder: _staffSubtitle,
  ),
  OutletDetailsMetricConfig(
    id: 'today_sales',
    permission: TenantAdminPermissionCodes.outletSalesSummaryView,
    title: "Today's sales",
    icon: Icons.payments,
    valueBuilder: _todaySalesValue,
    subtitleBuilder: _todaySalesSubtitle,
    trendBuilder: _todaySalesTrend,
  ),
  OutletDetailsMetricConfig(
    id: 'week_sales',
    permission: TenantAdminPermissionCodes.outletSalesSummaryView,
    title: 'This week',
    icon: Icons.calendar_today,
    valueBuilder: _weekSalesValue,
    subtitleBuilder: _weekSalesSubtitle,
    trendBuilder: _weekSalesTrend,
  ),
];

String? _tillsValue(OutletDetails outlet) {
  if (outlet.tillCount == null) {
    return null;
  }

  return '${outlet.tillCount}';
}

String? _tillsSubtitle(OutletDetails outlet) {
  if (outlet.tillCount == null) {
    return null;
  }

  final online = outlet.onlineTillCount ?? 0;
  final offline = outlet.tillCount! - online;
  return '$online Online • $offline Offline';
}

String? _staffValue(OutletDetails outlet) {
  if (outlet.staffCount == null) {
    return null;
  }

  return '${outlet.staffCount}';
}

String? _staffSubtitle(OutletDetails outlet) {
  if (outlet.staffCount == null) {
    return null;
  }

  return 'Assigned to this outlet';
}

String? _todaySalesValue(OutletDetails outlet) {
  return outlet.todaySalesDisplay;
}

String? _todaySalesSubtitle(OutletDetails outlet) {
  return outlet.todaySalesTrendLabel == null ? 'Today' : 'vs yesterday';
}

String? _todaySalesTrend(OutletDetails outlet) {
  return outlet.todaySalesTrendLabel;
}

String? _weekSalesValue(OutletDetails outlet) {
  return outlet.weekSalesDisplay;
}

String? _weekSalesSubtitle(OutletDetails outlet) {
  return outlet.weekSalesTrendLabel == null ? 'This week' : 'vs last week';
}

String? _weekSalesTrend(OutletDetails outlet) {
  return outlet.weekSalesTrendLabel;
}

List<OutletDetailsMetricConfig> visibleOutletDetailsMetrics(
  bool Function(String permissionCode) can,
  bool Function(Iterable<String> permissionCodes) canAny,
) {
  return filterOutletConfigs(outletDetailsMetricConfigs, can, canAny);
}
