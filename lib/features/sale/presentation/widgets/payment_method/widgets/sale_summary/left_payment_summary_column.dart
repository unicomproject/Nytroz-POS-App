import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_payment_permission_visibility.dart';
import '../../../../providers/pos_checkout_summary_provider.dart';
import '../../payment_method_style.dart';
import 'applied_discount_card.dart';
import 'customer_card.dart';
import 'payment_financial_summary.dart';
import 'sale_summary_card.dart';

class LeftPaymentSummaryColumn extends ConsumerWidget {
  const LeftPaymentSummaryColumn({
    super.key,
    required this.cart,
    this.summary,
    this.onCustomerTap,
    this.surface = PaymentSummaryPermissionSurface.checkout,
  });

  final PosNewSaleCartState cart;
  final PosCheckoutSummaryViewData? summary;
  final VoidCallback? onCustomerTap;
  final PaymentSummaryPermissionSurface surface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(effectivePermissionSetProvider);
    final currency = summary?.currency ?? '';
    final showCustomer = surface == PaymentSummaryPermissionSurface.checkout &&
        PosPaymentPermissionVisibility.canShowCheckoutCustomerSummary(
          permissions,
        );
    final showOrder = surface == PaymentSummaryPermissionSurface.cash
        ? PosPaymentPermissionVisibility.canShowCashSummaryOrder(permissions)
        : PosPaymentPermissionVisibility.canShowCheckoutSummaryItems(
              permissions,
            ) ||
            PosPaymentPermissionVisibility.canShowCheckoutSummaryQuantity(
              permissions,
            ) ||
            PosPaymentPermissionVisibility.canShowCheckoutSummaryPrice(
              permissions,
            ) ||
            PosPaymentPermissionVisibility.canShowCheckoutSummaryLineTotal(
              permissions,
            );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: PaymentMethodStyle.border),
        borderRadius: BorderRadius.circular(PaymentMethodStyle.panelRadius),
      ),
      padding: const EdgeInsets.all(PaymentMethodStyle.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showOrder)
            Expanded(
              child: SaleSummaryCard(
                cart: cart,
                currency: currency,
                surface: surface,
              ),
            )
          else
            const Spacer(),
          if (showOrder) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: PaymentMethodStyle.border),
          ],
          if (summary != null) ...[
            PaymentFinancialSummary(summary: summary!, surface: surface),
            const SizedBox(height: 8),
          ],
          if (showCustomer) CustomerCard(cart: cart, onTap: onCustomerTap),
          if (cart.hasDiscount &&
              (surface == PaymentSummaryPermissionSurface.checkout
                  ? PosPaymentPermissionVisibility.canShowCheckoutSummaryDiscount(
                      permissions,
                    )
                  : PosPaymentPermissionVisibility.canShowCashSummaryDiscount(
                      permissions,
                    ))) ...[
            const SizedBox(height: 8),
            AppliedDiscountCard(cart: cart),
          ],
        ],
      ),
    );
  }
}
