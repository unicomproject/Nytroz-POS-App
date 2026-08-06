import 'package:flutter/material.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';

class CashPaymentOrderItemRow extends StatelessWidget {
  const CashPaymentOrderItemRow({super.key, required this.item});

  final PosNewSaleCartItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TenantAdminSpacing.lg,
        vertical: TenantAdminSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                if (item.product.imageUrl != null)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: TenantAdminColors.background,
                      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      item.product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.image_not_supported_outlined,
                        color: TenantAdminColors.mutedText,
                      ),
                    ),
                  )
                else
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: TenantAdminColors.background,
                      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: TenantAdminColors.mutedText,
                    ),
                  ),
                const SizedBox(width: TenantAdminSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: TenantAdminColors.bodyText,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.product.hasVariants)
                        Text(
                          item.product.variantSummary,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: TenantAdminColors.mutedText,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              formatLkr(item.product.price),
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              formatLkr(item.lineTotal),
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
