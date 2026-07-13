import 'package:flutter/material.dart' show IconData, Icons;

import '../../domain/entities/product_dashboard.dart';

String formatProductDashboardCurrency(
  num amount, {
  String? currencyCode,
}) {
  final value = amount is int ? amount.toDouble() : amount as double;
  final symbol = _currencySymbol(currencyCode);
  final formatted = value.toStringAsFixed(
    value == value.roundToDouble() ? 0 : 2,
  );

  return '$symbol$formatted';
}

String _currencySymbol(String? currency) {
  switch (currency?.toUpperCase()) {
    case 'GBP':
      return '£';
    case 'EUR':
      return '€';
    case 'USD':
      return '\$';
    case 'LKR':
      return 'Rs ';
    default:
      return currency == null || currency.isEmpty ? '' : '$currency ';
  }
}

String formatProductDashboardMetricValue(
  ProductDashboardMetric metric, {
  bool asCurrency = false,
  String? currencyCode,
}) {
  if (asCurrency) {
    return formatProductDashboardCurrency(
      metric.value,
      currencyCode: currencyCode,
    );
  }

  if (metric.value is int || metric.value == metric.value.roundToDouble()) {
    return metric.value.round().toString();
  }

  return metric.value.toStringAsFixed(1);
}

ProductDashboardTrendDisplay formatProductDashboardTrend(double? value) {
  if (value == null) {
    return const ProductDashboardTrendDisplay(
      label: '',
      icon: null,
    );
  }

  if (value == 0) {
    return const ProductDashboardTrendDisplay(
      label: 'No change from previous period',
      icon: Icons.trending_flat,
    );
  }

  if (value > 0) {
    return ProductDashboardTrendDisplay(
      label:
          '${value.abs().toStringAsFixed(1)}% higher than previous period',
      icon: Icons.trending_up,
    );
  }

  return ProductDashboardTrendDisplay(
    label: '${value.abs().toStringAsFixed(1)}% lower than previous period',
    icon: Icons.trending_down,
  );
}

class ProductDashboardTrendDisplay {
  const ProductDashboardTrendDisplay({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData? icon;
}
