import '../models/tenant_dashboard_dto.dart';

class TenantDashboardSummaryDto {
  const TenantDashboardSummaryDto({
    this.todaySales,
    this.orders,
    this.activeOutlets,
    this.stockAlerts,
    this.tills,
    this.needsAttention,
  });

  factory TenantDashboardSummaryDto.fromJson(Map<String, dynamic> json) {
    final payload = json['data'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    return TenantDashboardSummaryDto(
      todaySales: _readMap(payload['todaySales'], DashboardTodaySalesDto.fromJson),
      orders: _readMap(payload['orders'], DashboardOrdersDto.fromJson),
      activeOutlets:
          _readMap(payload['activeOutlets'], DashboardActiveOutletsDto.fromJson),
      stockAlerts:
          _readMap(payload['stockAlerts'], DashboardStockAlertsDto.fromJson),
      tills: _readMap(payload['tills'], DashboardTillsDto.fromJson),
      needsAttention: _readMap(
        payload['needsAttention'],
        DashboardNeedsAttentionSummaryDto.fromJson,
      ),
    );
  }

  final DashboardTodaySalesDto? todaySales;
  final DashboardOrdersDto? orders;
  final DashboardActiveOutletsDto? activeOutlets;
  final DashboardStockAlertsDto? stockAlerts;
  final DashboardTillsDto? tills;
  final DashboardNeedsAttentionSummaryDto? needsAttention;

  TenantDashboardDto toDashboardDto() {
    final metrics = <TenantDashboardMetricDto>[];

    if (todaySales != null) {
      metrics.add(
        TenantDashboardMetricDto(
          key: 'sales',
          title: "Today's Sales",
          value: _formatMoney(todaySales!.amount, todaySales!.currency),
          trend: _formatPercent(todaySales!.growthPercent),
          status: 'success',
        ),
      );
    }

    if (orders != null) {
      metrics.add(
        TenantDashboardMetricDto(
          key: 'orders',
          title: 'Orders',
          value: '${orders!.count}',
          trend: _formatPercent(orders!.growthPercent),
          status: 'success',
        ),
      );
    }

    if (activeOutlets != null) {
      metrics.add(
        TenantDashboardMetricDto(
          key: 'outlets',
          title: 'Active Outlets',
          value: '${activeOutlets!.count}',
          subtitle: '${activeOutlets!.onlineCount} online',
          status: 'success',
        ),
      );
    }

    if (stockAlerts != null) {
      metrics.add(
        TenantDashboardMetricDto(
          key: 'stock',
          title: 'Stock Alerts',
          value: '${stockAlerts!.count}',
          status: 'warning',
        ),
      );
    }

    if (tills != null) {
      metrics.add(
        TenantDashboardMetricDto(
          key: 'tills',
          title: 'Online Tills',
          value: '${tills!.onlineCount}',
          subtitle: '${tills!.offlineCount} offline',
          status: tills!.offlineCount > 0 ? 'warning' : 'success',
        ),
      );
    }

    return TenantDashboardDto(
      metrics: metrics,
      salesThisWeek: null,
      needsAttention: needsAttention?.toAttentionItems() ?? const [],
      quickActions: const [],
      recentActivity: const [],
    );
  }
}

class DashboardTodaySalesDto {
  const DashboardTodaySalesDto({
    required this.amount,
    required this.currency,
    this.growthPercent,
  });

  factory DashboardTodaySalesDto.fromJson(Map<String, dynamic> json) {
    return DashboardTodaySalesDto(
      amount: _doubleValue(json['amount']),
      currency: json['currency']?.toString() ?? 'LKR',
      growthPercent: _nullableDouble(json['growthPercent']),
    );
  }

  final double amount;
  final String currency;
  final double? growthPercent;
}

class DashboardOrdersDto {
  const DashboardOrdersDto({
    required this.count,
    this.growthPercent,
  });

  factory DashboardOrdersDto.fromJson(Map<String, dynamic> json) {
    return DashboardOrdersDto(
      count: _intValue(json['count']),
      growthPercent: _nullableDouble(json['growthPercent']),
    );
  }

  final int count;
  final double? growthPercent;
}

class DashboardActiveOutletsDto {
  const DashboardActiveOutletsDto({
    required this.count,
    required this.onlineCount,
  });

  factory DashboardActiveOutletsDto.fromJson(Map<String, dynamic> json) {
    return DashboardActiveOutletsDto(
      count: _intValue(json['count']),
      onlineCount: _intValue(json['onlineCount']),
    );
  }

  final int count;
  final int onlineCount;
}

class DashboardStockAlertsDto {
  const DashboardStockAlertsDto({required this.count});

  factory DashboardStockAlertsDto.fromJson(Map<String, dynamic> json) {
    return DashboardStockAlertsDto(count: _intValue(json['count']));
  }

  final int count;
}

class DashboardTillsDto {
  const DashboardTillsDto({
    required this.onlineCount,
    required this.offlineCount,
  });

  factory DashboardTillsDto.fromJson(Map<String, dynamic> json) {
    return DashboardTillsDto(
      onlineCount: _intValue(json['onlineCount']),
      offlineCount: _intValue(json['offlineCount']),
    );
  }

  final int onlineCount;
  final int offlineCount;
}

class DashboardNeedsAttentionSummaryDto {
  const DashboardNeedsAttentionSummaryDto({
    this.offlineTills,
    this.lowStockItems,
    this.pendingStaffInvites,
    this.paymentDue,
  });

  factory DashboardNeedsAttentionSummaryDto.fromJson(Map<String, dynamic> json) {
    return DashboardNeedsAttentionSummaryDto(
      offlineTills: _nullableInt(json['offlineTills']),
      lowStockItems: _nullableInt(json['lowStockItems']),
      pendingStaffInvites: _nullableInt(json['pendingStaffInvites']),
      paymentDue: _readMap(json['paymentDue'], DashboardPaymentDueDto.fromJson),
    );
  }

  final int? offlineTills;
  final int? lowStockItems;
  final int? pendingStaffInvites;
  final DashboardPaymentDueDto? paymentDue;

  List<TenantDashboardAttentionItemDto> toAttentionItems() {
    final items = <TenantDashboardAttentionItemDto>[];

    if (offlineTills != null && offlineTills! > 0) {
      items.add(
        TenantDashboardAttentionItemDto(
          key: 'offline_tills',
          title: '$offlineTills tills are offline',
          message: 'Bring them back online',
          status: 'danger',
          route: '/tenant-admin/tills',
        ),
      );
    }

    if (lowStockItems != null && lowStockItems! > 0) {
      items.add(
        TenantDashboardAttentionItemDto(
          key: 'low_stock',
          title: '$lowStockItems low stock items',
          message: 'Restock to avoid running out',
          status: 'warning',
          route: '/tenant-admin/stock',
        ),
      );
    }

    if (pendingStaffInvites != null && pendingStaffInvites! > 0) {
      items.add(
        TenantDashboardAttentionItemDto(
          key: 'pending_invites',
          title: '$pendingStaffInvites pending staff invites',
          message: 'Review and send invites',
          status: 'pending',
          route: '/tenant-admin/staff',
        ),
      );
    }

    if (paymentDue != null) {
      items.add(
        TenantDashboardAttentionItemDto(
          key: 'payment_due',
          title: 'Payment due',
          message:
              '${_formatMoney(paymentDue!.amount, paymentDue!.currency)} due on ${paymentDue!.dueDate}',
          status: 'warning',
          route: '/tenant-admin/billing',
        ),
      );
    }

    return items;
  }
}

class DashboardPaymentDueDto {
  const DashboardPaymentDueDto({
    required this.amount,
    required this.currency,
    required this.dueDate,
  });

  factory DashboardPaymentDueDto.fromJson(Map<String, dynamic> json) {
    return DashboardPaymentDueDto(
      amount: _doubleValue(json['amount']),
      currency: json['currency']?.toString() ?? 'LKR',
      dueDate: json['dueDate']?.toString() ?? '',
    );
  }

  final double amount;
  final String currency;
  final String dueDate;
}

T? _readMap<T>(
  Object? value,
  T Function(Map<String, dynamic> json) mapper,
) {
  if (value is! Map) {
    return null;
  }

  return mapper(Map<String, dynamic>.from(value));
}

double _doubleValue(Object? value) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _nullableDouble(Object? value) {
  if (value == null) {
    return null;
  }

  return _doubleValue(value);
}

int _intValue(Object? value) {
  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableInt(Object? value) {
  if (value == null) {
    return null;
  }

  return _intValue(value);
}

String? _formatPercent(double? value) {
  if (value == null) {
    return null;
  }

  final prefix = value >= 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(1)}%';
}

String _formatMoney(double amount, String currency) {
  if (currency == 'LKR') {
    return 'LKR ${amount.toStringAsFixed(2)}';
  }

  if (currency == 'GBP') {
    return '£${amount.toStringAsFixed(2)}';
  }

  return '$currency ${amount.toStringAsFixed(2)}';
}
