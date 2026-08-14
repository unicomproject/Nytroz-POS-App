import 'package:flutter/material.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'cash_payment_action_button.dart';

/// Legacy dual-action bar retained for compatibility.
/// Cash Payment screen now uses a single Complete Sale CTA inside the tender panel.
class CashPaymentActionBar extends StatelessWidget {
  const CashPaymentActionBar({
    super.key,
    required this.isSubmitting,
    required this.canCompleteSale,
    required this.onExactCashPressed,
    required this.onCompleteSalePressed,
  });

  final bool isSubmitting;
  final bool canCompleteSale;
  final VoidCallback onExactCashPressed;
  final VoidCallback onCompleteSalePressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: CashPaymentActionButton(
                label: 'EXACT CASH',
                icon: Icons.payments_outlined,
                onPressed: isSubmitting ? null : onExactCashPressed,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.sm),
            Expanded(
              flex: 2,
              child: CashPaymentActionButton(
                label: 'COMPLETE SALE',
                subtitle: 'Complete the transaction',
                icon: Icons.check_circle_outline,
                isPrimary: true,
                isLoading: isSubmitting,
                onPressed: canCompleteSale && !isSubmitting
                    ? onCompleteSalePressed
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
