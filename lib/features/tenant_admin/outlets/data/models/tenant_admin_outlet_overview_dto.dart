class TenantAdminOutletOverviewDto {
  const TenantAdminOutletOverviewDto({
    required this.outlet,
    this.manager,
    this.tills,
    this.sales,
    this.inventory,
    this.orders,
    required this.health,
    this.alerts,
    required this.totalActiveAlertCount,
    required this.access,
  });

  factory TenantAdminOutletOverviewDto.fromJson(Map<String, dynamic> json) {
    return TenantAdminOutletOverviewDto(
      outlet: OutletOverviewInfoDto.fromJson(
          json['outlet'] as Map<String, dynamic>? ?? {}),
      manager: json['manager'] != null
          ? OutletOverviewManagerDto.fromJson(
              json['manager'] as Map<String, dynamic>)
          : null,
      tills: json['tills'] != null
          ? OutletOverviewTillSummaryDto.fromJson(
              json['tills'] as Map<String, dynamic>)
          : null,
      sales: json['sales'] != null
          ? OutletOverviewSalesSummaryDto.fromJson(
              json['sales'] as Map<String, dynamic>)
          : null,
      inventory: json['inventory'] != null
          ? OutletOverviewInventorySummaryDto.fromJson(
              json['inventory'] as Map<String, dynamic>)
          : null,
      orders: json['orders'] != null
          ? OutletOverviewOrderSummaryDto.fromJson(
              json['orders'] as Map<String, dynamic>)
          : null,
      health: OutletOverviewHealthDto.fromJson(
          json['health'] as Map<String, dynamic>? ?? {}),
      alerts: (json['alerts'] as List<dynamic>?)
          ?.map(
              (e) => OutletOverviewAlertDto.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      totalActiveAlertCount: json['totalActiveAlertCount'] as int? ?? 0,
      access: OutletOverviewSectionAccessDto.fromJson(
          json['access'] as Map<String, dynamic>? ?? {}),
    );
  }

  final OutletOverviewInfoDto outlet;
  final OutletOverviewManagerDto? manager;
  final OutletOverviewTillSummaryDto? tills;
  final OutletOverviewSalesSummaryDto? sales;
  final OutletOverviewInventorySummaryDto? inventory;
  final OutletOverviewOrderSummaryDto? orders;
  final OutletOverviewHealthDto health;
  final List<OutletOverviewAlertDto>? alerts;
  final int totalActiveAlertCount;
  final OutletOverviewSectionAccessDto access;
}

class OutletOverviewInfoDto {
  const OutletOverviewInfoDto({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    required this.status,
    this.imageUrl,
    this.addressLine1,
    this.city,
    this.mediaAssetId,
  });

  factory OutletOverviewInfoDto.fromJson(Map<String, dynamic> json) {
    return OutletOverviewInfoDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      type: json['type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      addressLine1: json['addressLine1'] as String?,
      city: json['city'] as String?,
      mediaAssetId: json['mediaAssetId'] as String?,
    );
  }

  final String id;
  final String name;
  final String code;
  final String type;
  final String status;
  final String? imageUrl;
  final String? addressLine1;
  final String? city;
  final String? mediaAssetId;
}

class OutletOverviewManagerDto {
  const OutletOverviewManagerDto({
    this.tenantUserId,
    this.name,
    this.email,
    this.phone,
    this.avatarUrl,
  });

  factory OutletOverviewManagerDto.fromJson(Map<String, dynamic> json) {
    return OutletOverviewManagerDto(
      tenantUserId: json['tenantUserId'] as String?,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  final String? tenantUserId;
  final String? name;
  final String? email;
  final String? phone;
  final String? avatarUrl;
}

class OutletOverviewTillSummaryDto {
  const OutletOverviewTillSummaryDto({
    required this.totalCount,
    required this.activeCount,
    required this.onlineCount,
    required this.attentionCount,
  });

  factory OutletOverviewTillSummaryDto.fromJson(Map<String, dynamic> json) {
    return OutletOverviewTillSummaryDto(
      totalCount: json['totalCount'] as int? ?? 0,
      activeCount: json['activeCount'] as int? ?? 0,
      onlineCount: json['onlineCount'] as int? ?? 0,
      attentionCount: json['attentionCount'] as int? ?? 0,
    );
  }

  final int totalCount;
  final int activeCount;
  final int onlineCount;
  final int attentionCount;
}

class OutletOverviewSalesSummaryDto {
  const OutletOverviewSalesSummaryDto({
    required this.todayNetSales,
    this.yesterdayComparisonPercentage,
    required this.currencyCode,
  });

  factory OutletOverviewSalesSummaryDto.fromJson(Map<String, dynamic> json) {
    return OutletOverviewSalesSummaryDto(
      todayNetSales: (json['todayNetSales'] as num?)?.toDouble() ?? 0.0,
      yesterdayComparisonPercentage:
          (json['yesterdayComparisonPercentage'] as num?)?.toDouble(),
      currencyCode: json['currencyCode'] as String? ?? 'USD',
    );
  }

  final double todayNetSales;
  final double? yesterdayComparisonPercentage;
  final String currencyCode;
}

class OutletOverviewInventorySummaryDto {
  const OutletOverviewInventorySummaryDto({
    required this.stockValue,
    required this.currencyCode,
  });

  factory OutletOverviewInventorySummaryDto.fromJson(
      Map<String, dynamic> json) {
    return OutletOverviewInventorySummaryDto(
      stockValue: (json['stockValue'] as num?)?.toDouble() ?? 0.0,
      currencyCode: json['currencyCode'] as String? ?? 'USD',
    );
  }

  final double stockValue;
  final String currencyCode;
}

class OutletOverviewOrderSummaryDto {
  const OutletOverviewOrderSummaryDto({
    required this.openOrderCount,
  });

  factory OutletOverviewOrderSummaryDto.fromJson(Map<String, dynamic> json) {
    return OutletOverviewOrderSummaryDto(
      openOrderCount: json['openOrderCount'] as int? ?? 0,
    );
  }

  final int openOrderCount;
}

class OutletOverviewHealthDto {
  const OutletOverviewHealthDto({
    required this.status,
    this.lastActivityAt,
    this.lastSyncAt,
  });

  factory OutletOverviewHealthDto.fromJson(Map<String, dynamic> json) {
    return OutletOverviewHealthDto(
      status: json['status'] as String? ?? '',
      lastActivityAt: json['lastActivityAt'] != null
          ? DateTime.tryParse(json['lastActivityAt'] as String)
          : null,
      lastSyncAt: json['lastSyncAt'] != null
          ? DateTime.tryParse(json['lastSyncAt'] as String)
          : null,
    );
  }

  final String status;
  final DateTime? lastActivityAt;
  final DateTime? lastSyncAt;
}

class OutletOverviewAlertDto {
  const OutletOverviewAlertDto({
    required this.alertId,
    required this.title,
    required this.severity,
    required this.description,
    required this.occurredAt,
  });

  factory OutletOverviewAlertDto.fromJson(Map<String, dynamic> json) {
    return OutletOverviewAlertDto(
      alertId: json['alertId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      severity: json['severity'] as String? ?? '',
      description: json['description'] as String? ?? '',
      occurredAt: json['occurredAt'] != null
          ? DateTime.tryParse(json['occurredAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  final String alertId;
  final String title;
  final String severity;
  final String description;
  final DateTime occurredAt;
}

class OutletOverviewSectionAccessDto {
  const OutletOverviewSectionAccessDto({
    required this.canViewTills,
    required this.canViewSales,
    required this.canViewInventory,
    required this.canViewOrders,
    required this.canViewAlerts,
  });

  factory OutletOverviewSectionAccessDto.fromJson(Map<String, dynamic> json) {
    return OutletOverviewSectionAccessDto(
      canViewTills: json['canViewTills'] as bool? ?? false,
      canViewSales: json['canViewSales'] as bool? ?? false,
      canViewInventory: json['canViewInventory'] as bool? ?? false,
      canViewOrders: json['canViewOrders'] as bool? ?? false,
      canViewAlerts: json['canViewAlerts'] as bool? ?? false,
    );
  }

  final bool canViewTills;
  final bool canViewSales;
  final bool canViewInventory;
  final bool canViewOrders;
  final bool canViewAlerts;
}
