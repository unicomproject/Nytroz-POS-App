import 'package:flutter/material.dart';
import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../domain/entities/pos_cash_payment_observability.dart';
import 'cash_payment_quick_amounts_section.dart';
import 'cash_payment_amount_received_section.dart';
import '../actions/cash_payment_action_bar.dart';
import '../../../providers/pos_cash_payment_provider.dart';

class CashPaymentTenderPanel extends StatelessWidget {
  const CashPaymentTenderPanel({
    super.key,
    required this.totalDue,
    required this.cashReceived,
    required this.inputBuffer,
    required this.quickAmounts,
    required this.selectedQuickAmount,
    required this.onQuickAmountSelected,
    required this.onOtherAmountPressed,
    required this.onDigitPressed,
    required this.onDoubleZeroPressed,
    required this.onBackspacePressed,
    required this.onClearPressed,
    required this.isSubmitting,
    required this.canCompleteSale,
    required this.onExactCashPressed,
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
  final VoidCallback onOtherAmountPressed;
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onDoubleZeroPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onClearPressed;
  final bool isSubmitting;
  final bool canCompleteSale;
  final VoidCallback onExactCashPressed;
  final VoidCallback onCompleteSalePressed;
  final CashPaymentFailure? failure;
  final VoidCallback? onDismissFailure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 4,
                child: CashPaymentQuickAmountsSection(
                  amounts: quickAmounts,
                  selectedAmount: selectedQuickAmount,
                  onAmountSelected: onQuickAmountSelected,
                  onOtherAmountPressed: onOtherAmountPressed,
                  totalDue: totalDue,
                  changeDue: cashPaymentChangeDue(cashReceived, totalDue),
                ),
              ),
              const SizedBox(width: TenantAdminSpacing.lg),
              Expanded(
                flex: 6,
                child: CashPaymentAmountReceivedSection(
                  cashReceived: cashReceived,
                  inputBuffer: inputBuffer,
                  onDigitPressed: onDigitPressed,
                  onDoubleZeroPressed: onDoubleZeroPressed,
                  onBackspacePressed: onBackspacePressed,
                  onClearPressed: onClearPressed,
                  failure: failure,
                  onDismissFailure: onDismissFailure,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: TenantAdminSpacing.lg),
        CashPaymentActionBar(
          isSubmitting: isSubmitting,
          canCompleteSale: canCompleteSale,
          onExactCashPressed: onExactCashPressed,
          onCompleteSalePressed: onCompleteSalePressed,
        ),
      ],
    );
  }
}
