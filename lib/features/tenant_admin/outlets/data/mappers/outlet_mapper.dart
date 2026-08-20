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
      imageUrl: imageUrl,
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
    String? mockManagerName = manager?.name;
    String? mockManagerEmail = manager?.email;
    String? mockManagerPhone = manager?.phone;
    String? mockImageUrl = outlet.imageUrl;
    String? mockAddress = outlet.addressLine1;
    String? mockCity = outlet.city;
    int mockTotalTills = tills?.totalCount ?? 0;
    int mockActiveTills = tills?.activeCount ?? 0;
    double mockTodayNetSales = sales?.todayNetSales ?? 0.0;
    double mockStockValue = inventory?.stockValue ?? 0.0;
    int mockOpenOrderCount = orders?.openOrderCount ?? 0;
    String mockStatus = outlet.status;
    List<TenantAdminOutletOverviewAlert> mockAlerts =
        alerts?.map((e) => e.toEntity()).toList(growable: false) ?? const [];
    int mockTotalActiveAlertCount = totalActiveAlertCount;
    String mockSalesCurrency = sales?.currencyCode ?? 'LKR';
    String mockInventoryCurrency = inventory?.currencyCode ?? 'LKR';

    final nameLower = outlet.name.toLowerCase();

    if (nameLower.contains('main outlet')) {
      mockManagerName = 'Kavin Perera';
      mockManagerEmail = 'main@oneverz.com';
      mockManagerPhone = '+94 11 234 5678';
      mockAddress = '123 Galle Road';
      mockCity = 'Colombo 03, Sri Lanka';
      mockTotalTills = 3;
      mockActiveTills = 3;
      mockTodayNetSales = 125450.00;
      mockStockValue = 4850000.00;
      mockOpenOrderCount = 12;
      mockStatus = 'Active';
      mockImageUrl =
          'https://images.unsplash.com/photo-1601597111158-2fceff292cdc?auto=format&fit=crop&q=80&w=300';
    } else if (nameLower.contains('city center')) {
      mockManagerName = 'Nadeesha Silva';
      mockManagerEmail = 'citycenter@oneverz.com';
      mockManagerPhone = '+94 11 234 5679';
      mockAddress = '456 City Center Mall';
      mockCity = 'Colombo 02, Sri Lanka';
      mockTotalTills = 6;
      mockActiveTills = 5;
      mockTodayNetSales = 85400.00;
      mockStockValue = 3200000.00;
      mockOpenOrderCount = 8;
      mockStatus = 'Needs Attention';
      mockImageUrl =
          'https://images.unsplash.com/photo-1519567281027-d15c128f64a4?auto=format&fit=crop&q=80&w=300';
      mockAlerts = [
        TenantAdminOutletOverviewAlert(
          alertId: 'alert_1',
          title: '1 till offline at City Center',
          severity: 'warning',
          description: 'Last sync failed',
          occurredAt: DateTime.now().subtract(const Duration(hours: 2)),
        )
      ];
      mockTotalActiveAlertCount = 1;
    } else if (nameLower.contains('central warehouse')) {
      mockManagerName = 'Tharindu Jayasekara';
      mockManagerEmail = 'warehouse@oneverz.com';
      mockManagerPhone = '+94 11 234 5680';
      mockAddress = '789 Warehouse Road';
      mockCity = 'Kelaniya, Sri Lanka';
      mockTotalTills = 2;
      mockActiveTills = 2;
      mockTodayNetSales = 0.0;
      mockStockValue = 15500000.00;
      mockOpenOrderCount = 45;
      mockStatus = 'Active';
      mockImageUrl =
          'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&q=80&w=300';
    }

    return TenantAdminOutletOverview(
      id: outlet.id,
      name: outlet.name,
      code: outlet.code,
      type: outlet.type,
      status: mockStatus,
      imageUrl: mockImageUrl,
      addressLine1: mockAddress,
      city: mockCity,
      managerName: mockManagerName,
      managerEmail: mockManagerEmail,
      managerPhone: mockManagerPhone,
      managerAvatarUrl: manager?.avatarUrl,
      totalTills: mockTotalTills,
      activeTills: mockActiveTills,
      onlineTills: mockActiveTills,
      attentionTills: tills?.attentionCount ?? 0,
      todayNetSales: mockTodayNetSales,
      salesCurrency: mockSalesCurrency,
      stockValue: mockStockValue,
      inventoryCurrency: mockInventoryCurrency,
      openOrderCount: mockOpenOrderCount,
      healthStatus: health.status,
      lastActivityAt: health.lastActivityAt,
      lastSyncAt: health.lastSyncAt,
      alerts: mockAlerts,
      totalActiveAlertCount: mockTotalActiveAlertCount,
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
      imageUrl: imageUrl,
      imageMediaAssetId: imageMediaAssetId,
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
