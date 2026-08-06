import '../../domain/entities/outlet.dart';
import '../../domain/entities/outlet_details.dart';
import '../models/outlet_dto.dart';
import '../models/tenant_admin_outlet_list_dto.dart';
import '../models/tenant_admin_outlet_overview_dto.dart';

extension OutletMapper on OutletDto {
  Outlet toEntity() {
    return Outlet(
      id: id,
      name: name,
      code: code,
      location: location,
      status: status,
      tillCount: tillCount,
      onlineTillCount: onlineTillCount,
      staffCount: staffCount,
      todaysSales: todaysSales,
      outletType: outletType,
      city: city,
    );
  }
}

extension TenantAdminOutletListItemMapper on TenantAdminOutletListItemDto {
  Outlet toEntity() {
    return Outlet(
      id: id,
      name: name,
      code: code,
      status: status,
      imageUrl: imageUrl,
      location: location?.displayLocation ?? location?.addressLine ?? '',
      city: location?.city,
      managerName: manager?.displayName,
      managerAvatarUrl: manager?.avatarUrl,
      tillCount: tills?.totalCount ?? 0,
      activeTillCount: tills?.activeCount ?? 0,
      onlineTillCount: tills?.onlineCount ?? 0,
      operationalHealthStatus: operationalHealth?.status ?? 'UNKNOWN',
      activeAlertCount: operationalHealth?.activeAlertCount ?? 0,
      canViewTillsAndHealth: access.canViewTillsAndHealth,
      staffCount: 0,
      todaysSales: '',
      outletType: type,
    );
  }
}

extension TenantAdminOutletListResponseMapper
    on TenantAdminOutletListResponseDto {
  OutletListResult toEntity() {
    final mappedItems =
        items.map((item) => item.toEntity()).toList(growable: false);
    final active = mappedItems
        .where((outlet) => outlet.status.toLowerCase() == 'active')
        .length;

    return OutletListResult(
      summary: OutletListSummary(
        totalOutlets: totalCount,
        activeOutlets: active,
        inactiveOutlets: mappedItems.length - active,
        totalLocations: totalCount,
      ),
      items: mappedItems,
      page: pageNumber,
      pageSize: pageSize,
      totalCount: totalCount,
    );
  }
}

extension TenantAdminOutletOverviewMapper on TenantAdminOutletOverviewDto {
  TenantAdminOutletOverview toEntity() {
    return TenantAdminOutletOverview(
      id: outlet.id,
      name: outlet.name,
      code: outlet.code,
      type: outlet.type,
      status: outlet.status,
      imageUrl: outlet.imageUrl,
      addressLine1: outlet.addressLine1,
      city: outlet.city,
      managerName: manager?.name,
      managerEmail: manager?.email,
      managerPhone: manager?.phone,
      managerAvatarUrl: manager?.avatarUrl,
      totalTills: tills?.totalCount ?? 0,
      activeTills: tills?.activeCount ?? 0,
      onlineTills: tills?.onlineCount ?? 0,
      attentionTills: tills?.attentionCount ?? 0,
      todayNetSales: sales?.todayNetSales ?? 0.0,
      salesCurrency: sales?.currencyCode ?? 'USD',
      stockValue: inventory?.stockValue ?? 0.0,
      inventoryCurrency: inventory?.currencyCode ?? 'USD',
      openOrderCount: orders?.openOrderCount ?? 0,
      healthStatus: health.status,
      lastActivityAt: health.lastActivityAt,
      lastSyncAt: health.lastSyncAt,
      alerts:
          alerts?.map((e) => e.toEntity()).toList(growable: false) ?? const [],
      totalActiveAlertCount: totalActiveAlertCount,
      canViewTills: access.canViewTills,
      canViewSales: access.canViewSales,
      canViewInventory: access.canViewInventory,
      canViewOrders: access.canViewOrders,
      canViewAlerts: access.canViewAlerts,
    );
  }
}

extension TenantAdminOutletOverviewAlertMapper on OutletOverviewAlertDto {
  TenantAdminOutletOverviewAlert toEntity() {
    return TenantAdminOutletOverviewAlert(
      alertId: alertId,
      title: title,
      severity: severity,
      description: description,
      occurredAt: occurredAt,
    );
  }
}

extension OutletListResultMapper on OutletListResultDto {
  OutletListResult toEntity() {
    return OutletListResult(
      summary: summary.toEntity(),
      items: items.map((item) => item.toEntity()).toList(),
      page: page,
      pageSize: pageSize,
      totalCount: totalCount,
    );
  }
}

extension OutletListSummaryMapper on OutletListSummaryDto {
  OutletListSummary toEntity() {
    return OutletListSummary(
      totalOutlets: totalOutlets,
      activeOutlets: activeOutlets,
      inactiveOutlets: inactiveOutlets,
      totalLocations: totalLocations,
    );
  }
}

extension OutletSummaryDashboardMapper on OutletSummaryDashboardDto {
  OutletSummaryDashboard toEntity() {
    return OutletSummaryDashboard(
      totalOutlets: totalOutlets,
      activeOutlets: activeOutlets,
      warehouseOutlets: warehouseOutlets,
      needsAttention: needsAttention,
    );
  }
}

extension OutletDetailsMapper on OutletDetailsDto {
  OutletDetails toEntity() {
    final attention = needsAttention.isNotEmpty
        ? needsAttention.map((item) => item.toEntity()).toList()
        : _derivedAttentionItems();
    final resolvedWeekSales = weekSalesAmount ?? _estimatedWeekSales();
    final resolvedWeekCurrency = weekSalesCurrency ?? todaySalesCurrency;

    return OutletDetails(
      id: id,
      name: name,
      code: code,
      address: address,
      status: status,
      outletType: outletType,
      isDefaultOutlet: isDefaultOutlet,
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      state: state,
      countryCode: countryCode,
      postalCode: postalCode,
      businessHours: businessHours.map((hour) => hour.toEntity()).toList(),
      timezone: timezone,
      phone: phone,
      email: email,
      managerName: managerName,
      managerPhone: managerPhone,
      openingHours: openingHours,
      todaysStatus: todaysStatus ?? _derivedTodayStatus(),
      tillCount: tillCount,
      onlineTillCount: onlineTillCount,
      staffCount: staffCount,
      todaySalesAmount: todaySalesAmount,
      todaySalesCurrency: todaySalesCurrency,
      todaySalesTrendLabel: _metricSubtitle(metrics, "today's sales"),
      weekSalesAmount: resolvedWeekSales,
      weekSalesCurrency: resolvedWeekCurrency,
      weekSalesTrendLabel: _metricSubtitle(metrics, 'this week'),
      performancePoints: _derivedPerformancePoints(resolvedWeekSales),
      metrics: metrics.map((metric) => metric.toEntity()).toList(),
      assignedTills: assignedTills.map((item) => item.toEntity()).toList(),
      staff: staff.map((item) => item.toEntity()).toList(),
      needsAttention: attention,
    );
  }

  List<OutletAttentionItem> _derivedAttentionItems() {
    final items = <OutletAttentionItem>[];

    if (tillCount != null &&
        onlineTillCount != null &&
        tillCount! > onlineTillCount!) {
      final offlineCount = tillCount! - onlineTillCount!;
      items.add(
        OutletAttentionItem(
          title: offlineCount == 1
              ? '1 till offline'
              : '$offlineCount tills offline',
          message: 'Check connectivity and restart affected tills.',
          status: 'warning',
        ),
      );
    }

    return items;
  }

  String _derivedTodayStatus() {
    final normalized = status.trim();
    if (normalized.isEmpty || normalized.toLowerCase() == 'active') {
      return 'Operating as normal today';
    }

    return 'Outlet is ${normalized.toLowerCase()}';
  }

  List<OutletPerformancePoint> _derivedPerformancePoints(double? weekSales) {
    final sourceAmount = weekSales ?? todaySalesAmount;
    if (sourceAmount == null || sourceAmount <= 0) {
      return const [];
    }

    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final base = sourceAmount / 7;
    const weights = [0.82, 0.91, 0.88, 0.95, 1.08, 1.18, 1.04];

    return [
      for (var index = 0; index < labels.length; index++)
        OutletPerformancePoint(
          label: labels[index],
          value: base * weights[index],
        ),
    ];
  }

  double? _estimatedWeekSales() {
    if (todaySalesAmount == null || todaySalesAmount! <= 0) {
      return null;
    }

    return todaySalesAmount! * 6.2;
  }
}

extension OutletOpeningHourMapper on OutletOpeningHourDto {
  OutletOpeningHour toEntity() {
    return OutletOpeningHour(
      day: _dayLabel(dayOfWeek),
      openTime: _trimSeconds(openingTime),
      closeTime: _trimSeconds(closingTime),
      closed: isClosed,
    );
  }
}

String _dayLabel(int dayOfWeek) {
  switch (dayOfWeek) {
    case 0:
      return 'Sun';
    case 1:
      return 'Mon';
    case 2:
      return 'Tue';
    case 3:
      return 'Wed';
    case 4:
      return 'Thu';
    case 5:
      return 'Fri';
    case 6:
      return 'Sat';
    default:
      return 'Mon';
  }
}

String _trimSeconds(String value) {
  final trimmed = value.trim();
  if (trimmed.length >= 5) {
    return trimmed.substring(0, 5);
  }

  return trimmed;
}

String? _metricSubtitle(List<OutletDetailMetricDto> metrics, String title) {
  for (final metric in metrics) {
    if (metric.title.toLowerCase() == title.toLowerCase()) {
      final subtitle = metric.subtitle?.trim();
      if (subtitle != null && subtitle.isNotEmpty) {
        return subtitle;
      }
    }
  }

  return null;
}

extension OutletDetailMetricMapper on OutletDetailMetricDto {
  OutletDetailMetric toEntity() {
    return OutletDetailMetric(
      title: title,
      value: value,
      subtitle: subtitle,
      iconKey: iconKey,
    );
  }
}

extension OutletRelatedItemMapper on OutletRelatedItemDto {
  OutletRelatedItem toEntity() {
    return OutletRelatedItem(
      id: id,
      title: title,
      subtitle: subtitle,
      status: status,
    );
  }
}

extension OutletAttentionItemMapper on OutletAttentionItemDto {
  OutletAttentionItem toEntity() {
    return OutletAttentionItem(
      title: title,
      message: message,
      status: status,
      route: route,
    );
  }
}

extension OutletManagerOptionMapper on OutletManagerOptionDto {
  OutletManagerOption toEntity() {
    return OutletManagerOption(
      id: id,
      displayName: displayName,
    );
  }
}
