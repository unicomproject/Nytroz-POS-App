import 'package:flutter/material.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'cash_payment_numeric_keypad.dart';

class CashPaymentQuickAmountsSection extends StatelessWidget {
  const CashPaymentQuickAmountsSection({
    super.key,
    required this.amounts,
    required this.selectedAmount,
    required this.onAmountSelected,
    required this.exactAmount,
  });

  final List<int> amounts;
  final int? selectedAmount;
  final ValueChanged<int> onAmountSelected;
  final int exactAmount;

  @override
  Widget build(BuildContext context) {
    if (amounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      alignment: WrapAlignment.end,
      children: amounts.map((amount) {
        final isSelected = amount == selectedAmount;
        final isExact = amount == exactAmount;
        final label = isExact
            ? 'EXACT ${formatLkrCompact(amount)}'
            : formatLkrCompact(amount);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onAmountSelected(amount),
            borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? TenantAdminColors.posHomeAccentOrange
                        .withValues(alpha: 0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
                border: Border.all(
                  color: isSelected
                      ? TenantAdminColors.posHomeAccentOrange
                      : TenantAdminColors.border,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? TenantAdminColors.posHomeAccentOrange
                          : CashPaymentKeypadStyle.digitColor,
                    ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

String formatLkrCompact(int amount) {
  return formatLkr(amount).replaceAll('.00', '');
}
