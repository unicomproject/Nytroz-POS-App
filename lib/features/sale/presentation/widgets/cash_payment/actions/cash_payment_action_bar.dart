import 'package:flutter/material.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'cash_payment_action_button.dart';

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
        borderRadius: BorderRadius.circular(TenantAdminRadius.lg),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(TenantAdminSpacing.md),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: CashPaymentActionButton(
                label: 'EXACT CASH',
                icon: Icons.payments_outlined,
                onPressed: isSubmitting ? null : onExactCashPressed,
              ),
            ),
            const SizedBox(width: TenantAdminSpacing.md),
            Expanded(
              flex: 2,
              child: CashPaymentActionButton(
                label: 'COMPLETE SALE',
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
