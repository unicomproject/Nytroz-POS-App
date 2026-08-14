import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/discount/presentation/providers/pos_discount_provider.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_payment_method_type.dart';
import 'package:nytroz_pos/features/sale/presentation/providers/pos_checkout_summary_provider.dart';
import 'package:nytroz_pos/features/till/presentation/providers/till_provider.dart';

import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosPaymentBar extends ConsumerWidget {
  const PosPaymentBar({
    required this.cart,
    required this.pricingAsync,
    super.key,
  });

  final PosNewSaleCartState cart;
  final AsyncValue<PosCheckoutSummaryViewData> pricingAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final deviceState = ref.watch(deviceActivationProvider);
    final tillState = ref.watch(tillProvider);
    final canCheckout = PosPermissionAccess.canCheckoutSession(session);
    final hasPaymentMethod =
        allowedPosPaymentMethods(session?.permissionCodes.toSet() ?? const {})
            .isNotEmpty;
    final deviceContext = deviceState.deviceContext;
    final hasTrustedDevice = deviceContext != null &&
        deviceContext.isTrusted &&
        deviceContext.deviceId.trim().isNotEmpty &&
        deviceContext.outletId.trim().isNotEmpty &&
        deviceContext.tillId.trim().isNotEmpty;
    final hasOpenTillSession = tillState.hasOpenSession;
    final pricingState = resolvePaymentBarPricingState(
      cart: cart,
      pricingAsync: pricingAsync,
    );
    final canProceed = cart.hasItems &&
        canCheckout &&
        hasPaymentMethod &&
        hasTrustedDevice &&
        hasOpenTillSession &&
        pricingState.canUseForPayment;

    const accentColor = TenantAdminColors.posHomeAccentOrange;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;
        final totalTextSize = isNarrow ? 16.0 : 20.0;
        final amountTextSize = isNarrow ? 18.0 : 24.0;

        return Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: EdgeInsets.symmetric(
            horizontal:
                isNarrow ? TenantAdminSpacing.sm : TenantAdminSpacing.md,
            vertical: TenantAdminSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(TenantAdminRadius.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: totalTextSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: TenantAdminSpacing.sm),
                    Text(
                      '|',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: amountTextSize,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(width: TenantAdminSpacing.sm),
                    Expanded(
                      child: Text(
                        pricingState.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: amountTextSize,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.sm),
              FilledButton.icon(
                onPressed: canProceed
                    ? () async {
                        final pending = cart.cartDiscount?.isPendingSync ==
                                true ||
                            cart.items.values.any(
                                (item) => item.discount?.isPendingSync == true);
                        if (pending) {
                          await syncPendingPosDiscounts(ref: ref);
                          final refreshed = ref.read(posNewSaleCartProvider);
                          final stillPending =
                              refreshed.cartDiscount?.isPendingSync == true ||
                                  refreshed.items.values.any((item) =>
                                      item.discount?.isPendingSync == true);
                          if (stillPending) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                  'Discount is saved offline and must sync before payment.',
                                )),
                              );
                            }
                            return;
                          }
                        }
                        if (context.mounted) {
                          context.push('/pos/new-sale/payment');
                        }
                      }
                    : null,
                icon: isNarrow
                    ? const SizedBox.shrink()
                    : const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(isNarrow ? 'Pay' : 'Proceed to Payment'),
                style: FilledButton.styleFrom(
                  minimumSize: Size(isNarrow ? 80 : 150, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: Colors.white,
                  foregroundColor: accentColor,
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.68),
                  disabledForegroundColor: TenantAdminColors.offline,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PaymentBarPricingState {
  const PaymentBarPricingState({
    required this.label,
    required this.canUseForPayment,
    this.authoritativeTotal,
  });

  final String label;
  final bool canUseForPayment;
  final int? authoritativeTotal;
}

PaymentBarPricingState resolvePaymentBarPricingState({
  required PosNewSaleCartState cart,
  required AsyncValue<PosCheckoutSummaryViewData> pricingAsync,
}) {
  if (!cart.hasItems) {
    return const PaymentBarPricingState(
      label: 'LKR 0.00',
      canUseForPayment: false,
    );
  }
  if (pricingAsync.isLoading) {
    return const PaymentBarPricingState(
      label: 'Calculating…',
      canUseForPayment: false,
    );
  }
  if (pricingAsync.hasError) {
    return const PaymentBarPricingState(
      label: 'Total unavailable',
      canUseForPayment: false,
    );
  }
  final pricing = pricingAsync.valueOrNull;
  if (pricing == null ||
      !isCurrentAuthoritativePricing(cart: cart, pricing: pricing)) {
    return const PaymentBarPricingState(
      label: 'Total unavailable',
      canUseForPayment: false,
    );
  }
  return PaymentBarPricingState(
    label: formatLkr(pricing.totalPayable),
    authoritativeTotal: pricing.totalPayable,
    canUseForPayment: true,
  );
}
