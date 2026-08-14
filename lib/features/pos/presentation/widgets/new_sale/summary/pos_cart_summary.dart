import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/discount/domain/entities/pos_cart_discount.dart';
import 'package:nytroz_pos/features/discount/presentation/providers/pos_discount_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/discount/presentation/widgets/discount_sync_conflict_panel.dart';
import 'package:nytroz_pos/features/discount/presentation/widgets/pos_discount_dialog.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_checkout_summary_provider.dart';

import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosCartSummary extends ConsumerWidget {
  const PosCartSummary({
    required this.cart,
    required this.pricingAsync,
    super.key,
  });

  final PosNewSaleCartState cart;
  final AsyncValue<PosCheckoutSummaryViewData> pricingAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conflictDiscount = _conflictDiscount(cart);
    final candidate = pricingAsync.valueOrNull;
    final pricing = !pricingAsync.isLoading &&
            !pricingAsync.hasError &&
            candidate != null &&
            isCurrentAuthoritativePricing(cart: cart, pricing: candidate)
        ? candidate
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (conflictDiscount != null) ...[
          DiscountSyncConflictPanel(
            errorCode: null,
            onRemoveDiscount: () async {
              await cancelPosDiscount(ref: ref, discount: conflictDiscount);
              ref.read(posNewSaleCartProvider.notifier).clearDiscounts();
            },
            onReviewSale: () {},
            isRetryable: conflictDiscount.isSyncFailed,
            onRetry: conflictDiscount.isSyncFailed
                ? () => syncPendingPosDiscounts(ref: ref)
                : null,
          ),
          const SizedBox(height: TenantAdminSpacing.sm),
        ],
        _CartTotalLine(
          label: 'Subtotal',
          value: pricing == null ? '—' : formatLkr(pricing.subtotal),
          labelColor: Colors.black,
          valueColor: Colors.black,
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        _CartTotalLine(
          labelWidget: _DiscountSummaryLabel(cart: cart),
          value: pricing == null
              ? '—'
              : pricing.discount > 0
                  ? '- ${formatLkr(pricing.discount)}'
                  : formatLkr(pricing.discount),
          valueColor: TenantAdminColors.danger,
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        _CartTotalLine(
          label: 'Tax',
          value: pricing == null ? '—' : formatLkr(pricing.tax),
          labelColor: Colors.black,
          valueColor: TenantAdminColors.info,
        ),
      ],
    );
  }
}

PosCartDiscount? _conflictDiscount(PosNewSaleCartState cart) {
  if (cart.cartDiscount?.isSyncConflict == true ||
      cart.cartDiscount?.isSyncFailed == true) {
    return cart.cartDiscount;
  }
  for (final item in cart.items.values) {
    final discount = item.discount;
    if (discount?.isSyncConflict == true || discount?.isSyncFailed == true) {
      return discount;
    }
  }
  return null;
}

class _DiscountSummaryLabel extends ConsumerWidget {
  const _DiscountSummaryLabel({required this.cart});

  final PosNewSaleCartState cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final canApplyDiscount =
        session?.hasPermission(PosPermissionCodes.applySaleDiscount) == true;
    final isApplied = cart.hasDiscount;
    final isPending = cart.pendingDiscount != null;
    final isPendingSync = cart.cartDiscount?.isPendingSync == true ||
        cart.items.values.any((item) => item.discount?.isPendingSync == true);
    final isConflict = cart.cartDiscount?.isSyncConflict == true ||
        cart.items.values.any((item) => item.discount?.isSyncConflict == true);
    final actionLabel = isConflict
        ? 'Conflict'
        : isPendingSync
            ? 'Pending Sync'
            : isApplied
                ? 'Discount Applied'
                : isPending
                    ? 'Approval Pending'
                    : 'Add Discount';

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: TenantAdminSpacing.sm,
      runSpacing: TenantAdminSpacing.xs,
      children: [
        Text(
          'Discount',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
        ),
        InkWell(
          onTap: canApplyDiscount && cart.hasItems
              ? () => showPosDiscountDialog(context: context, ref: ref)
              : null,
          borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TenantAdminSpacing.xs,
              vertical: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isApplied
                      ? Icons.check_circle_rounded
                      : Icons.local_offer_outlined,
                  size: 16,
                  color: isConflict
                      ? TenantAdminColors.warning
                      : isPendingSync
                          ? TenantAdminColors.warning
                          : isApplied
                              ? TenantAdminColors.success
                              : TenantAdminColors.posHomeAccentOrange,
                ),
                const SizedBox(width: TenantAdminSpacing.xs),
                Text(
                  actionLabel,
                  style: TextStyle(
                    color: isConflict
                        ? TenantAdminColors.warning
                        : isPendingSync
                            ? TenantAdminColors.warning
                            : isApplied
                                ? TenantAdminColors.success
                                : TenantAdminColors.posHomeAccentOrange,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CartTotalLine extends StatelessWidget {
  const _CartTotalLine({
    this.label,
    this.labelWidget,
    required this.value,
    this.labelColor = TenantAdminColors.bodyText,
    this.valueColor = TenantAdminColors.bodyText,
  }) : assert(label != null || labelWidget != null);

  final String? label;
  final Widget? labelWidget;
  final String value;
  final Color labelColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: labelColor,
          fontWeight: FontWeight.w800,
        );

    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: valueColor,
          fontWeight: FontWeight.w900,
        );

    return Row(
      children: [
        Expanded(child: labelWidget ?? Text(label!, style: style)),
        Text(value, style: valueStyle),
      ],
    );
  }
}
