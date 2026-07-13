class ProductDashboardMetricDto {
  const ProductDashboardMetricDto({
    required this.value,
    this.changePercent,
  });

  factory ProductDashboardMetricDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ProductDashboardMetricDto(value: 0);
    }

    return ProductDashboardMetricDto(
      value: _numValue(json['value']),
      changePercent: _nullableDouble(json['changePercent']),
    );
  }

  final num value;
  final double? changePercent;
}

class ProductDashboardSummaryDto {
  const ProductDashboardSummaryDto({
    this.totalProducts,
    this.lowStock,
    this.outOfStock,
    this.expiryAlerts,
    this.stockAdded,
    this.fastMovingProducts,
  });

  factory ProductDashboardSummaryDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ProductDashboardSummaryDto();
    }

    return ProductDashboardSummaryDto(
      totalProducts: _metric(json['totalProducts']),
      lowStock: _metric(json['lowStock']),
      outOfStock: _metric(json['outOfStock']),
      expiryAlerts: _metric(json['expiryAlerts']),
      stockAdded: _metric(json['stockAdded']),
      fastMovingProducts: _metric(json['fastMovingProducts']),
    );
  }

  final ProductDashboardMetricDto? totalProducts;
  final ProductDashboardMetricDto? lowStock;
  final ProductDashboardMetricDto? outOfStock;
  final ProductDashboardMetricDto? expiryAlerts;
  final ProductDashboardMetricDto? stockAdded;
  final ProductDashboardMetricDto? fastMovingProducts;
}

class ProductDashboardTrendPointDto {
  const ProductDashboardTrendPointDto({
    required this.date,
    required this.value,
  });

  factory ProductDashboardTrendPointDto.fromJson(Map<String, dynamic> json) {
    return ProductDashboardTrendPointDto(
      date: json['date']?.toString() ?? '',
      value: _numValue(json['value']),
    );
  }

  final String date;
  final num value;
}

class ProductDashboardStockValueDto {
  const ProductDashboardStockValueDto({
    required this.currentValue,
    this.changePercent,
    this.trend = const [],
  });

  factory ProductDashboardStockValueDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ProductDashboardStockValueDto(currentValue: 0);
    }

    return ProductDashboardStockValueDto(
      currentValue: _numValue(json['currentValue']),
      changePercent: _nullableDouble(json['changePercent']),
      trend: _mapList(json['trend'], ProductDashboardTrendPointDto.fromJson),
    );
  }

  final num currentValue;
  final double? changePercent;
  final List<ProductDashboardTrendPointDto> trend;
}

class ProductDashboardMovementItemDto {
  const ProductDashboardMovementItemDto({
    required this.type,
    required this.count,
    required this.percentage,
  });

  factory ProductDashboardMovementItemDto.fromJson(Map<String, dynamic> json) {
    return ProductDashboardMovementItemDto(
      type: json['type']?.toString() ?? '',
      count: _intValue(json['count']),
      percentage: _numValue(json['percentage']),
    );
  }

  final String type;
  final int count;
  final num percentage;
}

class ProductDashboardStockMovementDto {
  const ProductDashboardStockMovementDto({
    required this.totalCount,
    this.items = const [],
  });

  factory ProductDashboardStockMovementDto.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ProductDashboardStockMovementDto(totalCount: 0);
    }

    return ProductDashboardStockMovementDto(
      totalCount: _intValue(json['totalCount']),
      items: _mapList(json['items'], ProductDashboardMovementItemDto.fromJson),
    );
  }

  final int totalCount;
  final List<ProductDashboardMovementItemDto> items;
}

class ProductDashboardDto {
  const ProductDashboardDto({
    this.lastUpdatedAt,
    this.currencyCode,
    this.summary,
    this.stockValue,
    this.stockMovement,
  });

  factory ProductDashboardDto.fromJson(Map<String, dynamic> json) {
    return ProductDashboardDto(
      lastUpdatedAt: _nullableString(json['lastUpdatedAt']),
      currencyCode: _nullableString(json['currencyCode']),
      summary: json['summary'] is Map<String, dynamic>
          ? ProductDashboardSummaryDto.fromJson(
              Map<String, dynamic>.from(json['summary'] as Map),
            )
          : null,
      stockValue: json['stockValue'] is Map<String, dynamic>
          ? ProductDashboardStockValueDto.fromJson(
              Map<String, dynamic>.from(json['stockValue'] as Map),
            )
          : null,
      stockMovement: json['stockMovement'] is Map<String, dynamic>
          ? ProductDashboardStockMovementDto.fromJson(
              Map<String, dynamic>.from(json['stockMovement'] as Map),
            )
          : null,
    );
  }

  final String? lastUpdatedAt;
  final String? currencyCode;
  final ProductDashboardSummaryDto? summary;
  final ProductDashboardStockValueDto? stockValue;
  final ProductDashboardStockMovementDto? stockMovement;
}

ProductDashboardMetricDto? _metric(dynamic value) {
  if (value is! Map) {
    return null;
  }

  return ProductDashboardMetricDto.fromJson(Map<String, dynamic>.from(value));
}

List<T> _mapList<T>(
  dynamic value,
  T Function(Map<String, dynamic> json) mapper,
) {
  if (value is! List) {
    return const [];
  }

  return [
    for (final item in value)
      if (item is Map) mapper(Map<String, dynamic>.from(item)),
  ];
}

num _numValue(dynamic value, {num fallback = 0}) {
  if (value is num) {
    return value;
  }

  if (value is String) {
    return num.tryParse(value) ?? fallback;
  }

  return fallback;
}

int _intValue(dynamic value, {int fallback = 0}) {
  return _numValue(value, fallback: fallback).round();
}

double? _nullableDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(value);
  }

  return null;
}

String? _nullableString(dynamic value) {
  if (value == null) {
    return null;
  }

  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}
