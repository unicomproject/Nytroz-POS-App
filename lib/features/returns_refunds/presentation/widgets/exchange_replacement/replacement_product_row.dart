import 'package:flutter/material.dart';

import '../../../../../shared/widgets/app_cached_network_image.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../domain/entities/return_exchange.dart';
import '../../providers/return_create_credit_provider.dart';
import 'replacement_product_stock_status.dart';

class ReplacementProductRow extends StatelessWidget {
  const ReplacementProductRow({
    super.key,
    required this.product,
    required this.currencyCode,
    required this.selected,
    required this.onTap,
  });

  final ReturnExchangeProduct product;
  final String currencyCode;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final variantLabel = product.hasVariants && product.variantId == null
        ? 'Multiple variants'
        : ((product.variantDisplayName?.trim().isNotEmpty ?? false)
            ? product.variantDisplayName!.trim()
            : (product.sku.isEmpty ? '-' : product.sku));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: TenantAdminSpacing.lg,
            vertical: TenantAdminSpacing.md,
          ),
          decoration: BoxDecoration(
            color: selected
                ? TenantAdminColors.primary.withValues(alpha: 0.04)
                : Colors.transparent,
            border: Border.all(
              color: selected ? TenantAdminColors.primary : Colors.transparent,
              width: selected ? 1.5 : 0,
            ),
          ),
          child: Opacity(
            opacity: disabled ? 0.55 : 1,
            child: Row(
              children: [
                _SelectionIndicator(selected: selected),
                const SizedBox(width: TenantAdminSpacing.md),
                _ProductImage(imageUrl: product.imageStorageKey),
                const SizedBox(width: TenantAdminSpacing.md),
                Expanded(
                  flex: 4,
                  child: Text(
                    product.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    variantLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: TenantAdminColors.mutedText,
                        ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: ReplacementProductStockStatus(
                    stockStatus: product.stockStatus,
                    availableQty: product.availableQuantity,
                    stockLabel:
                        product.isOutOfStock ? 'Out of Stock' : 'In Stock',
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    formatReturnCreditAmount(
                      currency: currencyCode.isNotEmpty
                          ? currencyCode
                          : product.currencyCode,
                      amount: product.sellingPrice,
                    ),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? TenantAdminColors.primary : Colors.transparent,
        border: Border.all(
          color:
              selected ? TenantAdminColors.primary : TenantAdminColors.border,
          width: 2,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
          : null,
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      child: Container(
        width: 44,
        height: 44,
        color: TenantAdminColors.secondary,
        child: AppCachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          memCacheWidth: 88,
          errorWidget: const Icon(
            Icons.inventory_2_outlined,
            color: TenantAdminColors.mutedText,
          ),
        ),
      ),
    );
  }
}
