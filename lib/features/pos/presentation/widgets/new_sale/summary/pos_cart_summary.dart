import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/sale/presentation/widgets/new_sale/pos_discount_dialog.dart';

import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosCartSummary extends ConsumerWidget {
  const PosCartSummary({
    required this.cart,
    super.key,
  });

  final PosNewSaleCartState cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _CartTotalLine(
          label: 'Subtotal',
          value: formatLkr(cart.subtotal),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        _CartTotalLine(
          labelWidget: _DiscountSummaryLabel(cart: cart),
          value: cart.hasDiscount
              ? '- ${formatLkr(cart.discount)}'
              : formatLkr(cart.discount),
        ),
        const SizedBox(height: TenantAdminSpacing.sm),
        _CartTotalLine(
          label: 'Tax',
          value: formatLkr(cart.tax),
        ),
      ],
    );
  }
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
    final actionLabel = isApplied
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
                color: TenantAdminColors.bodyText,
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
                  color: isApplied
                      ? TenantAdminColors.success
                      : const Color(0xFFFF2D1A),
                ),
                const SizedBox(width: TenantAdminSpacing.xs),
                Text(
                  actionLabel,
                  style: TextStyle(
                    color: isApplied
                        ? TenantAdminColors.success
                        : const Color(0xFFFF2D1A),
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
  }) : assert(label != null || labelWidget != null);

  final String? label;
  final Widget? labelWidget;
  final String value;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: TenantAdminColors.bodyText,
          fontWeight: FontWeight.w800,
        );

    final valueStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: TenantAdminColors.bodyText,
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
