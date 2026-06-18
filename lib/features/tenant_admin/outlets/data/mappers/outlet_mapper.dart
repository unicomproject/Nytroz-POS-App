import '../../domain/entities/outlet.dart';
import '../../domain/entities/outlet_details.dart';
import '../models/outlet_dto.dart';

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
          title: offlineCount == 1 ? '1 till offline' : '$offlineCount tills offline',
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
