import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/entities/pos_payment_method_type.dart';
import '../../../providers/pos_checkout_summary_provider.dart';
import '../payment_method_style.dart';
import 'payment_selection/payment_info_card.dart';
import 'payment_selection/payment_method_header.dart';
import 'payment_selection/payment_methods_section.dart';
import 'payment_selection/payment_total_due_card.dart';
import 'totals/continue_payment_button.dart';

class RightPaymentColumn extends StatelessWidget {
  const RightPaymentColumn({
    super.key,
    required this.summary,
    required this.allowedMethods,
    required this.selectedMethod,
    required this.isNavigating,
    required this.onSelectMethod,
    required this.onContinue,
    this.onBackToSale,
  });

  final PosCheckoutSummaryViewData summary;
  final Set<PosPaymentMethodType> allowedMethods;
  final PosPaymentMethodType? selectedMethod;
  final bool isNavigating;
  final ValueChanged<PosPaymentMethodType> onSelectMethod;
  final VoidCallback? onContinue;
  final VoidCallback? onBackToSale;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: PaymentMethodStyle.border),
        borderRadius: BorderRadius.circular(PaymentMethodStyle.panelRadius),
      ),
      padding: const EdgeInsets.all(PaymentMethodStyle.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PaymentMethodHeader(
            onBackToSale: onBackToSale ??
                () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    GoRouter.of(context).go('/pos/new-sale');
                  }
                },
          ),
          const SizedBox(height: 12),
          PaymentTotalDueCard(summary: summary),
          const SizedBox(height: 12),
          Expanded(
            child: PaymentMethodsSection(
              allowedMethods: allowedMethods,
              authoritative: !summary.usedFallback,
              selectedMethod: selectedMethod,
              onSelectMethod: onSelectMethod,
              showHeader: false,
            ),
          ),
          const SizedBox(height: 10),
          const PaymentInfoCardNotice(),
          const SizedBox(height: 12),
          ContinuePaymentButton(
            onPressed: onContinue,
            isLoading: isNavigating,
          ),
        ],
      ),
    );
  }
}
