import 'package:flutter/material.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../domain/entities/pos_cash_payment_observability.dart';
import '../../../providers/pos_cash_payment_provider.dart';
import '../actions/cash_payment_action_button.dart';
import 'cash_payment_amount_received_section.dart';
import 'cash_payment_due_change_section.dart';
import 'cash_payment_numeric_keypad.dart';
import 'cash_payment_quick_amounts_section.dart';

class CashPaymentTenderPanel extends StatelessWidget {
  const CashPaymentTenderPanel({
    super.key,
    required this.totalDue,
    required this.cashReceived,
    required this.inputBuffer,
    required this.quickAmounts,
    required this.selectedQuickAmount,
    required this.onQuickAmountSelected,
    required this.onDigitPressed,
    required this.onDoubleZeroPressed,
    required this.onBackspacePressed,
    required this.onClearPressed,
    required this.isSubmitting,
    required this.canCompleteSale,
    required this.onCompleteSalePressed,
    this.failure,
    this.onDismissFailure,
  });

  final int totalDue;
  final int cashReceived;
  final String inputBuffer;
  final List<int> quickAmounts;
  final int? selectedQuickAmount;
  final ValueChanged<int> onQuickAmountSelected;
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onDoubleZeroPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onClearPressed;
  final bool isSubmitting;
  final bool canCompleteSale;
  final VoidCallback onCompleteSalePressed;
  final CashPaymentFailure? failure;
  final VoidCallback? onDismissFailure;

  @override
  Widget build(BuildContext context) {
    final changeDue = cashPaymentChangeDue(cashReceived, totalDue);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: TenantAdminColors.surface,
        borderRadius: BorderRadius.circular(TenantAdminRadius.md),
        border: Border.all(color: TenantAdminColors.border),
        boxShadow: TenantAdminShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'CASH PAYMENT',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: TenantAdminColors.bodyText,
                    fontSize: 14,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: CashPaymentAmountReceivedSection(
                    cashReceived: cashReceived,
                    inputBuffer: inputBuffer,
                    totalDue: totalDue,
                    failure: failure,
                    onDismissFailure: onDismissFailure,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: CashPaymentQuickAmountsSection(
                    amounts: quickAmounts,
                    selectedAmount: selectedQuickAmount,
                    onAmountSelected: onQuickAmountSelected,
                    exactAmount: totalDue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: CashPaymentNumericKeypad(
                onDigitPressed: onDigitPressed,
                onDoubleZeroPressed: onDoubleZeroPressed,
                onBackspacePressed: onBackspacePressed,
                onClearPressed: onClearPressed,
              ),
            ),
            const SizedBox(height: 8),
            CashPaymentDueChangeSection(changeDue: changeDue),
            const SizedBox(height: 8),
            CashPaymentActionButton(
              label: 'COMPLETE SALE',
              subtitle: 'Complete the transaction',
              icon: Icons.check_circle_outline,
              isPrimary: true,
              isLoading: isSubmitting,
              onPressed: canCompleteSale && !isSubmitting
                  ? onCompleteSalePressed
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
