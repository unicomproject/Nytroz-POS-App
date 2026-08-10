import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/current_stock_entities.dart';

/// Full product info card: image, name, SKU copy, variant/status chips,
/// and action buttons.
class ProductInfoCard extends StatelessWidget {
  const ProductInfoCard({super.key, required this.detail});

  final ProductStockDetail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(TenantAdminSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(TenantAdminSpacing.lg),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxWidth < 600;

          final productImage = Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2), // Light red background
              borderRadius: BorderRadius.circular(TenantAdminSpacing.md),
              image: (detail.imageUrl != null && detail.imageUrl!.isNotEmpty)
                  ? DecorationImage(
                      image: NetworkImage(detail.imageUrl!),
                      fit: BoxFit.cover)
                  : null,
            ),
            child: (detail.imageUrl == null || detail.imageUrl!.isEmpty)
                ? const Icon(Icons.inventory_2_outlined,
                    color: TenantAdminColors.mutedText, size: 32)
                : null,
          );

          final productDetails = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                detail.productName ?? 'Unknown Product',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: TenantAdminColors.bodyText,
                ),
              ),
              const SizedBox(height: 6),
              // SKU row
              Row(
                children: [
                  Text(
                    'SKU: ${detail.sku ?? 'N/A'}',
                    style: const TextStyle(
                        fontSize: 14,
                        color: TenantAdminColors.mutedText),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      if (detail.sku != null) {
                        Clipboard.setData(
                            ClipboardData(text: detail.sku!));
                      }
                    },
                    child: const Icon(Icons.content_copy_outlined,
                        size: 15,
                        color: TenantAdminColors.mutedText),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Chips row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ProductInfoChip(
                      icon: Icons.sell_outlined,
                      label: 'Variant',
                      iconColor: const Color(0xFF3B82F6),
                      value: (detail.variantName != null && detail.variantName!.isNotEmpty) ? detail.variantName! : 'Default'),
                  if (!isSmall) const _VerticalDivider(),
                  ProductInfoChip(
                      icon: Icons.grid_view_outlined,
                      label: 'Category',
                      iconColor: const Color(0xFF8B5CF6),
                      value: (detail.categoryName != null && detail.categoryName!.isNotEmpty) ? detail.categoryName! : 'N/A'),
                  if (!isSmall) const _VerticalDivider(),
                  _StatusChip(
                    label: 'Status',
                    value: detail.stockStatus ?? 'Unknown',
                    isActive: (detail.stockStatus?.toLowerCase() == 'in stock' ||
                        detail.stockStatus?.toLowerCase() == 'instock'),
                  ),
                ],
              ),
            ],
          );

          final actionButtons = Wrap(
            spacing: TenantAdminSpacing.md,
            runSpacing: TenantAdminSpacing.md,
            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.inventory_2_outlined, size: 16),
                label: const Text('View Batches'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF97316), // Orange
                  side: const BorderSide(color: Color(0xFFF97316)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Adjust Stock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF97316), // Orange
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );

          if (isSmall) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                productImage,
                const SizedBox(height: TenantAdminSpacing.xl),
                productDetails,
                const SizedBox(height: TenantAdminSpacing.xl),
                actionButtons,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              productImage,
              const SizedBox(width: TenantAdminSpacing.xl),
              Expanded(child: productDetails),
              const SizedBox(width: TenantAdminSpacing.lg),
              actionButtons,
            ],
          );
        },
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      width: 1,
      color: TenantAdminColors.border,
      margin: const EdgeInsets.symmetric(horizontal: TenantAdminSpacing.xl),
    );
  }
}

/// A small chip showing an icon + label + value without background.
class ProductInfoChip extends StatelessWidget {
  const ProductInfoChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: iconColor ?? const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: TenantAdminColors.mutedText)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: TenantAdminColors.bodyText)),
          ],
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    required this.isActive,
  });

  final String label;
  final String value;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? TenantAdminColors.success : TenantAdminColors.danger;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
          child: Icon(isActive ? Icons.check : Icons.close, size: 14, color: color),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: TenantAdminColors.mutedText)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(value,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: color)),
            ),
          ],
        ),
      ],
    );
  }
}
