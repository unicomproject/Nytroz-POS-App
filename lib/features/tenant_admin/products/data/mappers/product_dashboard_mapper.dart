import '../../domain/entities/product_dashboard.dart';
import '../models/product_dashboard_dto.dart';

class ProductDashboardMapper {
  const ProductDashboardMapper._();

  static ProductDashboard toEntity(ProductDashboardDto dto) {
    return ProductDashboard(
      lastUpdatedAt: _parseDateTime(dto.lastUpdatedAt),
      currencyCode: dto.currencyCode,
      summary: dto.summary == null ? null : _toSummary(dto.summary!),
      stockValue:
          dto.stockValue == null ? null : _toStockValue(dto.stockValue!),
      stockMovement: dto.stockMovement == null
          ? null
          : _toStockMovement(dto.stockMovement!),
    );
  }

  static ProductDashboardSummary _toSummary(ProductDashboardSummaryDto dto) {
    return ProductDashboardSummary(
      totalProducts: _toMetric(dto.totalProducts),
      lowStock: _toMetric(dto.lowStock),
      outOfStock: _toMetric(dto.outOfStock),
      expiryAlerts: _toMetric(dto.expiryAlerts),
      stockAdded: _toMetric(dto.stockAdded),
      fastMovingProducts: _toMetric(dto.fastMovingProducts),
    );
  }

  static ProductDashboardMetric? _toMetric(ProductDashboardMetricDto? dto) {
    if (dto == null) {
      return null;
    }

    return ProductDashboardMetric(
      value: dto.value,
      changePercent: dto.changePercent,
    );
  }

  static ProductDashboardStockValue _toStockValue(
    ProductDashboardStockValueDto dto,
  ) {
    return ProductDashboardStockValue(
      currentValue: dto.currentValue.toDouble(),
      changePercent: dto.changePercent,
      trend: [
        for (final point in dto.trend)
          ProductDashboardTrendPoint(
            date: point.date,
            label: _trendLabel(point.date),
            value: point.value.toDouble(),
          ),
      ],
    );
  }

  static ProductDashboardStockMovement _toStockMovement(
    ProductDashboardStockMovementDto dto,
  ) {
    return ProductDashboardStockMovement(
      totalCount: dto.totalCount,
      items: [
        for (final item in dto.items)
          ProductDashboardMovementItem(
            type: item.type,
            label: _movementLabel(item.type),
            count: item.count,
            percentage: item.percentage.toDouble(),
          ),
      ],
    );
  }

  static DateTime? _parseDateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  static String _trendLabel(String rawDate) {
    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) {
      return rawDate;
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[parsed.month - 1]} ${parsed.day}';
  }

  static String _movementLabel(String type) {
    switch (type.trim().toLowerCase()) {
      case 'in':
      case 'stock_in':
        return 'Stock In';
      case 'out':
      case 'stock_out':
        return 'Stock Out';
      case 'adjustment':
      case 'adjustments':
        return 'Adjustments';
      case 'transfer':
      case 'transfers':
        return 'Transfers';
      default:
        if (type.trim().isEmpty) {
          return 'Other';
        }

        return type
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (part) => part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' ');
    }
  }
}
