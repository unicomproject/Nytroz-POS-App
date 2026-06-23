import 'package:flutter/material.dart';

import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'cash_payment_summary_card.dart';
import 'numeric_keypad.dart';

class CashPaymentRightPanel extends StatelessWidget {
  const CashPaymentRightPanel({
    super.key,
    required this.total,
    required this.cashReceived,
    required this.onKeyTap,
  });

  final int total;
  final int cashReceived;
  final ValueChanged<String> onKeyTap;

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
            CashPaymentSummaryCard(
              total: total,
              cashReceived: cashReceived,
              embedded: true,
            ),
            const SizedBox(height: TenantAdminSpacing.lg),
            Expanded(
              child: NumericKeypad(onKeyTap: onKeyTap),
            ),
          ],
        ),
      ),
    );
  }
}
