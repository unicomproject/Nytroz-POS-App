import 'package:flutter/material.dart';

import '../../../presentation/theme/tenant_admin_theme.dart';
import '../../../presentation/widgets/tenant_admin_metric_card.dart';

class OutletDetailKpiRow extends StatelessWidget {
  const OutletDetailKpiRow({
    super.key,
    required this.cards,
  });

  final List<OutletDetailKpiCardData> cards;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 1200
        ? 4
        : width >= TenantAdminBreakpoints.tablet
            ? 2
            : 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = TenantAdminSpacing.md;
        final itemWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards)
              SizedBox(
                width: itemWidth,
                height: 132,
                child: TenantAdminMetricCard(
                  title: card.title,
                  value: card.value,
                  subtitle: card.subtitle,
                  trend: card.trend,
                  icon: card.icon,
                  dense: true,
                ),
              ),
          ],
        );
      },
    );
  }
}

class OutletDetailKpiCardData {
  const OutletDetailKpiCardData({
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.trend,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final String? trend;
}

String formatCurrency(num amount) {
  final value = amount is int ? amount.toDouble() : amount as double;
  final formatted =
      value.toStringAsFixed(value == value.roundToDouble() ? 0 : 2);
  return 'Rs $formatted';
}

String formatPercentChange(double? value) {
  if (value == null) {
    return '';
  }

  final sign = value >= 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(1)}% vs last month';
}
