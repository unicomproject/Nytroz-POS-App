import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/auth/presentation/providers/session_provider.dart';
import 'package:nytroz_pos/features/cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'package:nytroz_pos/features/device_activation/presentation/providers/device_activation_provider.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_payment_method_type.dart';
import 'package:nytroz_pos/features/till/presentation/providers/till_provider.dart';

import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';

class PosPaymentBar extends ConsumerWidget {
  const PosPaymentBar({
    required this.cart,
    super.key,
  });

  final PosNewSaleCartState cart;

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
    final canProceed = cart.hasItems &&
        canCheckout &&
        hasPaymentMethod &&
        hasTrustedDevice &&
        hasOpenTillSession;

    const redOrangeColor = Color(0xFFFF2D1A);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
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
            color: redOrangeColor,
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
                        formatLkr(cart.total),
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
                    ? () => context.push('/pos/new-sale/payment')
                    : null,
                icon: isNarrow
                    ? const SizedBox.shrink()
                    : const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(isNarrow ? 'Pay' : 'Proceed to Payment'),
                style: FilledButton.styleFrom(
                  minimumSize: Size(isNarrow ? 80 : 150, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: Colors.white,
                  foregroundColor: redOrangeColor,
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
