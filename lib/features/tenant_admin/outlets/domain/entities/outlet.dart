class Outlet {
  const Outlet({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
    this.outletType,
    this.imageUrl,
    this.location = '',
    this.city,
    this.managerName,
    this.managerAvatarUrl,
    this.tillCount = 0,
    this.onlineTillCount = 0,
    this.activeTillCount = 0,
    this.operationalHealthStatus = 'UNKNOWN',
    this.activeAlertCount = 0,
    this.canViewTillsAndHealth = false,
    this.staffCount = 0,
    this.todaysSales = '',
  });

  final String id;
  final String name;
  final String code;
  final String status;
  final String? outletType;
  final String? imageUrl;
  final String location;
  final String? city;
  final String? managerName;
  final String? managerAvatarUrl;
  final int tillCount;
  final int onlineTillCount;
  final int activeTillCount;
  final String operationalHealthStatus;
  final int activeAlertCount;
  final bool canViewTillsAndHealth;

  // Legacy fields
  final int staffCount;
  final String todaysSales;

  Outlet copyWith({
    String? id,
    String? name,
    String? code,
    String? status,
    String? outletType,
    String? imageUrl,
    String? location,
    String? city,
    String? managerName,
    String? managerAvatarUrl,
    int? tillCount,
    int? onlineTillCount,
    int? activeTillCount,
    String? operationalHealthStatus,
    int? activeAlertCount,
    bool? canViewTillsAndHealth,
    int? staffCount,
    String? todaysSales,
  }) {
    return Outlet(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      status: status ?? this.status,
      outletType: outletType ?? this.outletType,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      city: city ?? this.city,
      managerName: managerName ?? this.managerName,
      managerAvatarUrl: managerAvatarUrl ?? this.managerAvatarUrl,
      tillCount: tillCount ?? this.tillCount,
      onlineTillCount: onlineTillCount ?? this.onlineTillCount,
      activeTillCount: activeTillCount ?? this.activeTillCount,
      operationalHealthStatus: operationalHealthStatus ?? this.operationalHealthStatus,
      activeAlertCount: activeAlertCount ?? this.activeAlertCount,
      canViewTillsAndHealth: canViewTillsAndHealth ?? this.canViewTillsAndHealth,
      staffCount: staffCount ?? this.staffCount,
      todaysSales: todaysSales ?? this.todaysSales,
    );
  }
}

class OutletSummaryDashboard {
  const OutletSummaryDashboard({
    required this.totalOutlets,
    required this.activeOutlets,
    required this.warehouseOutlets,
    this.needsAttention,
  });

  final int totalOutlets;
  final int activeOutlets;
  final int warehouseOutlets;
  final int? needsAttention;
}

class OutletListSummary {
  const OutletListSummary({
    required this.totalOutlets,
    required this.activeOutlets,
    required this.inactiveOutlets,
    required this.totalLocations,
  });

  final int totalOutlets;
  final int activeOutlets;
  final int inactiveOutlets;
  final int totalLocations;
}

class OutletListResult {
  const OutletListResult({
    required this.summary,
    required this.items,
    this.page = 1,
    this.pageSize = 10,
    this.totalCount = 0,
  });

  final OutletListSummary summary;
  final List<Outlet> items;
  final int page;
  final int pageSize;
  final int totalCount;

  int get totalPages {
    if (pageSize <= 0 || totalCount <= 0) {
      return totalCount > 0 ? 1 : 0;
    }

    return (totalCount / pageSize).ceil();
  }

  int get rangeStart {
    if (totalCount == 0) {
      return 0;
    }

    return ((page - 1) * pageSize) + 1;
  }

  int get rangeEnd {
    if (totalCount == 0) {
      return 0;
    }

    return (page * pageSize).clamp(0, totalCount);
  }
}

class OutletManagerOption {
  const OutletManagerOption({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;
}

class TenantAdminOutletOverview {
  const TenantAdminOutletOverview({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    required this.status,
    this.imageUrl,
    this.addressLine1,
    this.city,
    this.managerName,
    this.managerEmail,
    this.managerPhone,
    this.managerAvatarUrl,
    required this.totalTills,
    required this.activeTills,
    required this.onlineTills,
    required this.attentionTills,
    required this.todayNetSales,
    required this.salesCurrency,
    required this.stockValue,
    required this.inventoryCurrency,
    required this.openOrderCount,
    required this.healthStatus,
    this.lastActivityAt,
    this.lastSyncAt,
    this.alerts = const [],
    required this.totalActiveAlertCount,
    required this.canViewTills,
    required this.canViewSales,
    required this.canViewInventory,
    required this.canViewOrders,
    required this.canViewAlerts,
  });

  final String id;
  final String name;
  final String code;
  final String type;
  final String status;
  final String? imageUrl;
  final String? addressLine1;
  final String? city;

  final String? managerName;
  final String? managerEmail;
  final String? managerPhone;
  final String? managerAvatarUrl;

  final int totalTills;
  final int activeTills;
  final int onlineTills;
  final int attentionTills;

  final double todayNetSales;
  final String salesCurrency;

  final double stockValue;
  final String inventoryCurrency;

  final int openOrderCount;

  final String healthStatus;
  final DateTime? lastActivityAt;
  final DateTime? lastSyncAt;

  final List<TenantAdminOutletOverviewAlert> alerts;
  final int totalActiveAlertCount;

  final bool canViewTills;
  final bool canViewSales;
  final bool canViewInventory;
  final bool canViewOrders;
  final bool canViewAlerts;
}

class TenantAdminOutletOverviewAlert {
  const TenantAdminOutletOverviewAlert({
    required this.alertId,
    required this.title,
    required this.severity,
    required this.description,
    required this.occurredAt,
  });

  final String alertId;
  final String title;
  final String severity;
  final String description;
  final DateTime occurredAt;
}
