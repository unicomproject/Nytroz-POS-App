import 'package:flutter/material.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import 'cash_payment_numeric_keypad.dart';

class CashPaymentDueChangeSection extends StatelessWidget {
  const CashPaymentDueChangeSection({
    super.key,
    required this.changeDue,
  });

  final int changeDue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: TenantAdminColors.successSurface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.sm),
        border: Border.all(color: TenantAdminColors.successBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.payments_outlined,
            color: TenantAdminColors.success,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'CHANGE DUE',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: CashPaymentKeypadStyle.digitColor,
                ),
          ),
          const Spacer(),
          Text(
            formatLkr(changeDue > 0 ? changeDue : 0),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: TenantAdminColors.success,
                ),
          ),
        ],
      ),
    );
  }
}
