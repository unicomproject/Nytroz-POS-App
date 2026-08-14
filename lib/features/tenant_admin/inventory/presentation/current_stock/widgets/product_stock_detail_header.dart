import 'package:flutter/material.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/current_stock_entities.dart';

class ProductStockDetailHeader extends StatelessWidget {
  const ProductStockDetailHeader({
    super.key,
    required this.detail,
  });

  final ProductStockDetail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.lg),
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminSpacing.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detail.imageUrl != null)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(TenantAdminSpacing.sm),
                image: DecorationImage(
                  image: NetworkImage(detail.imageUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: TenantAdminColors.background,
                borderRadius: BorderRadius.circular(TenantAdminSpacing.sm),
              ),
              child: const Icon(Icons.image_not_supported,
                  color: TenantAdminColors.mutedText),
            ),
          const SizedBox(width: TenantAdminSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.productName ?? 'Unknown Product',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (detail.variantName != null)
                  Text(detail.variantName!,
                      style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: TenantAdminSpacing.sm),
                Text('SKU: ${detail.sku ?? "N/A"}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: TenantAdminColors.mutedText)),
                if (detail.categoryName != null)
                  Text('Category: ${detail.categoryName}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: TenantAdminColors.mutedText)),
                const SizedBox(height: TenantAdminSpacing.md),
                Row(
                  children: [
                    _buildStatCard(
                        context, 'On Hand', detail.totalOnHand.toString()),
                    const SizedBox(width: TenantAdminSpacing.md),
                    _buildStatCard(
                        context, 'Available', detail.totalAvailable.toString(),
                        color: TenantAdminColors.success),
                    const SizedBox(width: TenantAdminSpacing.md),
                    _buildStatCard(
                        context, 'Reserved', detail.totalReserved.toString(),
                        color: TenantAdminColors.warning),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value,
      {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: TenantAdminSpacing.md, vertical: TenantAdminSpacing.sm),
      decoration: BoxDecoration(
        color: (color ?? TenantAdminColors.primary).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(TenantAdminSpacing.sm),
        border: Border.all(
            color: (color ?? TenantAdminColors.primary).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: TenantAdminColors.mutedText)),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color ?? TenantAdminColors.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
