import 'package:flutter/material.dart';

import '../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../domain/entities/pos_cash_payment_observability.dart';
import '../../providers/pos_checkout_summary_provider.dart';
import '../payment_method/payment_method_style.dart';
import '../payment_method/widgets/payment_method_workspace_card.dart';
import '../payment_method/widgets/sale_summary/left_payment_summary_column.dart';
import 'package:nytroz_pos/core/access/pos_payment_permission_visibility.dart';
import 'tender/cash_payment_tender_panel.dart';

class CashPaymentScreenBody extends StatelessWidget {
  const CashPaymentScreenBody({
    super.key,
    required this.cart,
    required this.summary,
    required this.cashReceived,
    required this.inputBuffer,
    required this.quickAmounts,
    required this.selectedQuickAmount,
    required this.onCustomerTap,
    required this.onBackToPaymentMethods,
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

  final PosNewSaleCartState cart;
  final PosCheckoutSummaryViewData summary;
  final int cashReceived;
  final String inputBuffer;
  final List<int> quickAmounts;
  final int? selectedQuickAmount;
  final VoidCallback onCustomerTap;
  final VoidCallback onBackToPaymentMethods;
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
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 920;
          final tender = CashPaymentTenderPanel(
            totalDue: summary.totalPayable,
            currency: summary.currency,
            cashReceived: cashReceived,
            inputBuffer: inputBuffer,
            quickAmounts: quickAmounts,
            selectedQuickAmount: selectedQuickAmount,
            onBack: onBackToPaymentMethods,
            onQuickAmountSelected: onQuickAmountSelected,
            onDigitPressed: onDigitPressed,
            onDoubleZeroPressed: onDoubleZeroPressed,
            onBackspacePressed: onBackspacePressed,
            onClearPressed: onClearPressed,
            isSubmitting: isSubmitting,
            canCompleteSale: canCompleteSale,
            onCompleteSalePressed: onCompleteSalePressed,
            failure: failure,
            onDismissFailure: onDismissFailure,
          );
          final summaryPanel = LeftPaymentSummaryColumn(
            key: const ValueKey('cash-payment-shared-sale-summary'),
            cart: cart,
            summary: summary,
            onCustomerTap: onCustomerTap,
            surface: PaymentSummaryPermissionSurface.cash,
          );

          if (wide) {
            final leftFlex = constraints.maxWidth >= 1150 ? 36 : 44;
            return PaymentMethodWorkspaceCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: leftFlex, child: summaryPanel),
                  const SizedBox(width: PaymentMethodStyle.gap),
                  Expanded(flex: 100 - leftFlex, child: tender),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: PaymentMethodWorkspaceCard(
              child: Column(
                children: [
                  SizedBox(height: 600, child: summaryPanel),
                  const SizedBox(height: PaymentMethodStyle.gap),
                  SizedBox(height: 680, child: tender),
                ],
              ),
            ),
          );
        },
      );
}
