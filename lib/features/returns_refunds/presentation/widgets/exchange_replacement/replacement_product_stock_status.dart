import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class ReplacementProductStockStatus extends StatelessWidget {
  const ReplacementProductStockStatus({
    super.key,
    required this.stockStatus,
    required this.stockLabel,
    this.availableQty,
  });

  final String stockStatus;
  final String stockLabel;
  final double? availableQty;

  @override
  Widget build(BuildContext context) {
    final color = switch (stockStatus) {
      'OutOfStock' => TenantAdminColors.danger,
      'LowStock' => TenantAdminColors.warning,
      _ => TenantAdminColors.success,
    };

    final label = availableQty != null
        ? '${availableQty!.toStringAsFixed(availableQty! % 1 == 0 ? 0 : 1)} in stock'
        : stockLabel;

    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
