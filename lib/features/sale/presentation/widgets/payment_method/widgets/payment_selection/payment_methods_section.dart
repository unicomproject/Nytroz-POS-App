import 'package:flutter/material.dart';

import '../../../../../domain/entities/pos_payment_method_type.dart';
import '../../../payment/payment_method_capability.dart';
import '../../../payment/payment_method_card.dart';
import '../../../payment/payment_method_equal_grid.dart';
import '../../payment_method_style.dart';

class PaymentMethodsSection extends StatelessWidget {
  const PaymentMethodsSection({
    super.key,
    required this.allowedMethods,
    required this.authoritative,
    required this.selectedMethod,
    required this.onSelectMethod,
  });
  final Set<PosPaymentMethodType> allowedMethods;
  final bool authoritative;
  final PosPaymentMethodType? selectedMethod;
  final ValueChanged<PosPaymentMethodType> onSelectMethod;

  @override
  Widget build(BuildContext context) => Container(
        key: const ValueKey('payment-methods-section'),
        child: Column(children: [
          const Row(children: [
            Icon(Icons.credit_card_rounded,
                color: PaymentMethodStyle.orange, size: 27),
            SizedBox(width: 11),
            Expanded(
              child: Text('SELECT PAYMENT METHOD',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            ),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              const gap = 12.0;
              const minimumCardHeight = 116.0;
              final fittedHeight = (constraints.maxHeight - gap) / 2;
              final cardHeight = fittedHeight.clamp(minimumCardHeight, 150.0);
              final grid = PaymentMethodEqualGrid(
                gap: gap,
                cardHeight: cardHeight,
                children: PosPaymentMethodType.values.map((method) {
                  final capability = paymentMethodCapability(
                    method,
                    backendAllowed: allowedMethods.contains(method),
                    authoritativeSummary: authoritative,
                  );
                  return PaymentMethodCard(
                    key: ValueKey('payment-method-${method.name}'),
                    method: method,
                    enabled: capability.executable,
                    selected: selectedMethod == method,
                    unavailableReason: capability.unavailableReason,
                    onTap: () => onSelectMethod(method),
                    onUnavailableTap: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(
                          content:
                              Text('${method.title} is currently unavailable.'),
                        ));
                    },
                  );
                }).toList(growable: false),
              );
              final requiredHeight = cardHeight * 2 + gap;
              if (requiredHeight <= constraints.maxHeight) return grid;
              return SingleChildScrollView(
                child: SizedBox(height: requiredHeight, child: grid),
              );
            }),
          ),
        ]),
      );
}
