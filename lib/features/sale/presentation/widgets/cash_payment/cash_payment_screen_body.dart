import 'package:flutter/material.dart';
import '../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../../../domain/entities/pos_cash_payment_observability.dart';
import 'order_summary/cash_payment_order_summary_card.dart';
import 'tender/cash_payment_tender_panel.dart';

class CashPaymentScreenBody extends StatelessWidget {
  const CashPaymentScreenBody({
    super.key,
    required this.itemCount,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.totalDue,
    required this.items,
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

  final int itemCount;
  final int subtotal;
  final int discount;
  final int tax;
  final int totalDue;
  final List<PosNewSaleCartItem> items;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final useWideLayout =
            constraints.maxWidth >= TenantAdminBreakpoints.tablet;

        return useWideLayout ? _buildWideLayout() : _buildNarrowLayout();
      },
    );
  }

  Widget _buildTenderPanel() {
    return CashPaymentTenderPanel(
      totalDue: totalDue,
      cashReceived: cashReceived,
      inputBuffer: inputBuffer,
      quickAmounts: quickAmounts,
      selectedQuickAmount: selectedQuickAmount,
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
  }

  Widget _buildWideLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 2,
          child: CashPaymentOrderSummaryCard(
            itemCount: itemCount,
            subtotal: subtotal,
            discount: discount,
            tax: tax,
            total: totalDue,
            items: items,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: _buildTenderPanel(),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout() {
    // Fixed split — no page scroll. Item list scrolls inside its card only.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 2,
          child: CashPaymentOrderSummaryCard(
            itemCount: itemCount,
            subtotal: subtotal,
            discount: discount,
            tax: tax,
            total: totalDue,
            items: items,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          flex: 3,
          child: _buildTenderPanel(),
        ),
      ],
    );
  }
}
