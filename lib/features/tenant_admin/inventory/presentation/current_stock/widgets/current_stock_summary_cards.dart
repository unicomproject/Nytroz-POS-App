import 'package:flutter/material.dart';
import '../../../domain/entities/current_stock_entities.dart';
import '../../../../presentation/theme/tenant_admin_theme.dart';

class CurrentStockSummaryCards extends StatelessWidget {
  const CurrentStockSummaryCards({
    super.key,
    required this.summary,
  });

  final CurrentStockSummary summary;

  Widget _buildCard(BuildContext context, String value, String title, Widget icon, Color color) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminSpacing.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      padding: const EdgeInsets.only(left: TenantAdminSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(TenantAdminSpacing.sm),
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(TenantAdminSpacing.sm),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: icon,
          ),
          const SizedBox(width: TenantAdminSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: TenantAdminColors.bodyText),
              ),
              Text(
                title,
                style: (Theme.of(context).textTheme.labelSmall ?? const TextStyle()).copyWith(color: TenantAdminColors.mutedText, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _buildCard(
        context,
        summary.totalProducts.toString(),
        'Products',
        const Icon(Icons.view_in_ar_outlined, color: Colors.blue, size: 28),
        Colors.blue,
      ),
      _buildCard(
        context,
        summary.totalItemsInStock.toString(),
        'In Stock',
        const Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
        Colors.green,
      ),
      _buildCard(
        context,
        summary.totalItemsLowStock.toString(),
        'Low Stock',
        const Icon(Icons.error_outline, color: Colors.orange, size: 28),
        Colors.orange,
      ),
      _buildCard(
        context,
        summary.totalItemsOutOfStock.toString(),
        'Out of Stock',
        const Icon(Icons.error_outline, color: Colors.red, size: 28),
        Colors.red,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        if (width < 600) {
          return Column(
            children: cards
                .map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: TenantAdminSpacing.md),
                      child: c,
                    ))
                .toList(),
          );
        }

        if (width < 1100) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: TenantAdminSpacing.md),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: TenantAdminSpacing.md),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(child: cards[1]),
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(child: cards[2]),
            const SizedBox(width: TenantAdminSpacing.lg),
            Expanded(child: cards[3]),
          ],
        );
      },
    );
  }
}

