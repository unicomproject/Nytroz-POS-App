import 'package:flutter/material.dart';

import '../../../../domain/entities/pos_payment_method_type.dart';
import '../../../providers/pos_checkout_summary_provider.dart';
import '../payment_method_style.dart';
import 'payment_selection/payment_methods_section.dart';
import 'totals/continue_payment_button.dart';
import 'totals/payment_totals_card.dart';

class RightPaymentColumn extends StatelessWidget {
  const RightPaymentColumn(
      {super.key,
      required this.summary,
      required this.allowedMethods,
      required this.selectedMethod,
      required this.isNavigating,
      required this.onSelectMethod,
      required this.onContinue});
  final PosCheckoutSummaryViewData summary;
  final Set<PosPaymentMethodType> allowedMethods;
  final PosPaymentMethodType? selectedMethod;
  final bool isNavigating;
  final ValueChanged<PosPaymentMethodType> onSelectMethod;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: PaymentMethodStyle.border),
          borderRadius: BorderRadius.circular(PaymentMethodStyle.panelRadius),
        ),
        padding: const EdgeInsets.all(PaymentMethodStyle.padding),
        child: Column(children: [
          Expanded(
            child: PaymentMethodsSection(
              allowedMethods: allowedMethods,
              authoritative: !summary.usedFallback,
              selectedMethod: selectedMethod,
              onSelectMethod: onSelectMethod,
            ),
          ),
          const SizedBox(height: 12),
          PaymentTotalsCard(summary: summary),
          const SizedBox(height: 14),
          ContinuePaymentButton(onPressed: onContinue, isLoading: isNavigating),
        ]),
      );
}
