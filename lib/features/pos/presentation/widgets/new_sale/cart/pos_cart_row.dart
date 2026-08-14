import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_checkout_summary.dart';

import '../../../../../../shared/widgets/app_cached_network_image.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'pos_cart_authoritative_price_display.dart';
import 'pos_quantity_stepper.dart';

class PosCartRow extends ConsumerWidget {
  const PosCartRow({
    required this.item,
    required this.onTap,
    this.linePricing,
    this.isAuthoritative = false,
    this.currency = '',
    super.key,
  });

  final PosNewSaleCartItem item;
  final VoidCallback onTap;
  final PosCalculatedCartLinePayload? linePricing;
  final bool isAuthoritative;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(posNewSaleCartProvider.notifier);
    final session = ref.watch(authSessionProvider);
    final granted = session?.permissionCodes.toSet() ?? const <String>{};
    final canUpdateItems = PosPermissionAccess.canUpdateCartItem(granted);
    final canRemoveItems = PosPermissionAccess.canRemoveCartItem(granted);
    void reportBlockedMutation(bool changed) {
      if (changed) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'Remove the active discount before changing the cart.',
        ),
      ));
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: TenantAdminSpacing.sm),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              SizedBox.shrink(
                child: Text(
                  'Qty ${item.quantity}',
                  style:
                      const TextStyle(fontSize: 0, color: Colors.transparent),
                ),
              ),
              _CartProductThumbnail(product: item.product),
              const SizedBox(width: TenantAdminSpacing.md),
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: TenantAdminColors.bodyText,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (item.product.variantSummary.isNotEmpty)
                      Text(
                        item.product.variantSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: TenantAdminColors.mutedText,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    if (item.product.normalizedLineNote.isNotEmpty)
                      Text(
                        'Note: ${item.product.normalizedLineNote}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: TenantAdminColors.mutedText,
                            ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Center(
                  child: PosQuantityStepper(
                    quantity: item.quantity,
                    onIncrement: canUpdateItems
                        ? () => reportBlockedMutation(
                            notifier.increaseQuantity(item.product.cartLineKey))
                        : null,
                    onDecrement: canUpdateItems
                        ? () => reportBlockedMutation(
                            notifier.decreaseQuantity(item.product.cartLineKey))
                        : null,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: PosCartAuthoritativeUnitPriceDisplay(
                  catalogUnitPrice: item.product.price,
                  currency: currency,
                  isAuthoritative: isAuthoritative,
                  linePricing: linePricing,
                ),
              ),
              Expanded(
                flex: 4,
                child: PosCartAuthoritativeLineTotalDisplay(
                  catalogLineTotal: item.lineTotal,
                  currency: currency,
                  isAuthoritative: isAuthoritative,
                  linePricing: linePricing,
                ),
              ),
              SizedBox(
                width: 36,
                child: canRemoveItems
                    ? IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => reportBlockedMutation(
                            notifier.removeItem(item.product.cartLineKey)),
                        icon: const Icon(Icons.close_rounded, size: 20),
                        color: const Color(0xFF2563EB),
                        tooltip: 'Remove item',
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartProductThumbnail extends StatelessWidget {
  const _CartProductThumbnail({required this.product});

  final PosNewSaleProduct product;

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
      child: SizedBox.square(
        dimension: 52,
        child: ColoredBox(
          color: TenantAdminColors.background,
          child: AppCachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            memCacheWidth: 104,
            errorWidget: const _CartImageFallback(),
          ),
        ),
      ),
    );
  }
}

class _CartImageFallback extends StatelessWidget {
  const _CartImageFallback();

  @override
  Widget build(BuildContext context) => const Icon(
        Icons.inventory_2_outlined,
        color: TenantAdminColors.posHomeAccentOrange,
        size: 24,
      );
}
