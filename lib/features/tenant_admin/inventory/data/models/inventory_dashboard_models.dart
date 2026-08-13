class InventoryDashboardMetricsDto {
  const InventoryDashboardMetricsDto({
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.nearExpiryCount,
    required this.activeStockCounts,
  });

  factory InventoryDashboardMetricsDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const InventoryDashboardMetricsDto(
        lowStockCount: 0,
        outOfStockCount: 0,
        nearExpiryCount: 0,
        activeStockCounts: 0,
      );
    }

    return InventoryDashboardMetricsDto(
      lowStockCount: json['lowStockCount'] as int? ?? 0,
      outOfStockCount: json['outOfStockCount'] as int? ?? 0,
      nearExpiryCount: json['nearExpiryCount'] as int? ?? 0,
      activeStockCounts: json['activeStockCounts'] as int? ?? 0,
    );
  }

  final int lowStockCount;
  final int outOfStockCount;
  final int nearExpiryCount;
  final int activeStockCounts;
}

class InventoryDashboardAlertItemDto {
  const InventoryDashboardAlertItemDto({
    required this.productId,
    this.variantId,
    required this.productName,
    this.variantName,
    this.sku,
    required this.outletId,
    required this.outletName,
    required this.alertType,
    required this.severity,
    required this.detectedOn,
  });

  factory InventoryDashboardAlertItemDto.fromJson(Map<String, dynamic> json) {
    return InventoryDashboardAlertItemDto(
      productId: json['productId'] as String,
      variantId: json['variantId'] as String?,
      productName: json['productName'] as String? ?? '',
      variantName: json['variantName'] as String?,
      sku: json['sku'] as String?,
      outletId: json['outletId'] as String,
      outletName: json['outletName'] as String? ?? '',
      alertType: json['alertType'] as String? ?? '',
      severity: json['severity'] as String? ?? '',
      detectedOn: DateTime.tryParse(json['detectedOn']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  final String productId;
  final String? variantId;
  final String productName;
  final String? variantName;
  final String? sku;
  final String outletId;
  final String outletName;
  final String alertType;
  final String severity;
  final DateTime detectedOn;
}

class InventoryDashboardAlertsResponseDto {
  const InventoryDashboardAlertsResponseDto({
    required this.items,
  });

  factory InventoryDashboardAlertsResponseDto.fromJson(
      Map<String, dynamic>? json) {
    if (json == null || json['items'] == null) {
      return const InventoryDashboardAlertsResponseDto(items: []);
    }

    final itemsList = json['items'] as List<dynamic>;
    return InventoryDashboardAlertsResponseDto(
      items: itemsList
          .map((e) => InventoryDashboardAlertItemDto.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<InventoryDashboardAlertItemDto> items;
}

class InventoryDashboardActivityItemDto {
  const InventoryDashboardActivityItemDto({
    required this.stockMovementId,
    required this.activityType,
    this.referenceNumber,
    required this.outletId,
    required this.outletName,
    required this.timestamp,
    required this.changeQuantity,
  });

  factory InventoryDashboardActivityItemDto.fromJson(
      Map<String, dynamic> json) {
    return InventoryDashboardActivityItemDto(
      stockMovementId: json['stockMovementId'] as String,
      activityType: json['activityType'] as String? ?? '',
      referenceNumber: json['referenceNumber'] as String?,
      outletId: json['outletId'] as String,
      outletName: json['outletName'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      changeQuantity: (json['changeQuantity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String stockMovementId;
  final String activityType;
  final String? referenceNumber;
  final String outletId;
  final String outletName;
  final DateTime timestamp;
  final double changeQuantity;
}

class InventoryDashboardActivitiesResponseDto {
  const InventoryDashboardActivitiesResponseDto({
    required this.items,
  });

  factory InventoryDashboardActivitiesResponseDto.fromJson(
      Map<String, dynamic>? json) {
    if (json == null || json['items'] == null) {
      return const InventoryDashboardActivitiesResponseDto(items: []);
    }

    final itemsList = json['items'] as List<dynamic>;
    return InventoryDashboardActivitiesResponseDto(
      items: itemsList
          .map((e) => InventoryDashboardActivityItemDto.fromJson(
              e as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<InventoryDashboardActivityItemDto> items;
}
