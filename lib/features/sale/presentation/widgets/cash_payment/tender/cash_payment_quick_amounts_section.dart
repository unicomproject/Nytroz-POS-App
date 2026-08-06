import 'package:flutter/material.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'cash_payment_due_change_section.dart';

class CashPaymentQuickAmountsSection extends StatelessWidget {
  const CashPaymentQuickAmountsSection({
    super.key,
    required this.amounts,
    required this.selectedAmount,
    required this.onAmountSelected,
    required this.onOtherAmountPressed,
    required this.totalDue,
    required this.changeDue,
  });

  final List<int> amounts;
  final int? selectedAmount;
  final ValueChanged<int> onAmountSelected;
  final VoidCallback onOtherAmountPressed;
  final int totalDue;
  final int changeDue;

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
        padding: const EdgeInsets.all(TenantAdminSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'QUICK AMOUNTS',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: TenantAdminColors.bodyText,
                  ),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (amounts.isNotEmpty) ...[
                      Wrap(
                        spacing: TenantAdminSpacing.sm,
                        runSpacing: TenantAdminSpacing.sm,
                        children: amounts.map((amount) {
                          final isSelected = amount == selectedAmount;
                          return InkWell(
                            onTap: () => onAmountSelected(amount),
                            borderRadius:
                                BorderRadius.circular(TenantAdminRadius.sm),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: TenantAdminSpacing.md,
                                vertical: TenantAdminSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? TenantAdminColors.primary
                                        .withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius:
                                    BorderRadius.circular(TenantAdminRadius.sm),
                                border: Border.all(
                                  color: isSelected
                                      ? TenantAdminColors.primary
                                      : TenantAdminColors.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Text(
                                formatLkr(amount),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: isSelected
                                          ? TenantAdminColors.primary
                                          : TenantAdminColors.bodyText,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: TenantAdminSpacing.md),
                    ],
                    OutlinedButton(
                      onPressed: onOtherAmountPressed,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: TenantAdminSpacing.md),
                        side: const BorderSide(color: TenantAdminColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(TenantAdminRadius.sm),
                        ),
                      ),
                      child: const Text('OTHER AMOUNT'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: TenantAdminSpacing.md),
            CashPaymentDueChangeSection(
              totalDue: totalDue,
              changeDue: changeDue,
            ),
          ],
        ),
      ),
    );
  }
}
