import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_payment_permission_visibility.dart';

import '../../../../../domain/entities/pos_payment_method_type.dart';
import '../../../payment/payment_method_capability.dart';
import '../../../payment/payment_method_card.dart';
import '../../../payment/payment_method_equal_grid.dart';
import '../../payment_method_style.dart';

class PaymentMethodsSection extends ConsumerWidget {
  const PaymentMethodsSection({
    super.key,
    required this.allowedMethods,
    required this.authoritative,
    required this.selectedMethod,
    required this.onSelectMethod,
    this.showHeader = false,
  });

  final Set<PosPaymentMethodType> allowedMethods;
  final bool authoritative;
  final PosPaymentMethodType? selectedMethod;
  final ValueChanged<PosPaymentMethodType> onSelectMethod;
  final bool showHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(effectivePermissionSetProvider);
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (!PosPaymentPermissionVisibility.canShowMethodsContainer(permissions)) {
      return const SizedBox.shrink(key: ValueKey('payment-methods-container-denied'));
    }

    return Container(
      key: const ValueKey('payment-methods-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showHeader) ...[
            Row(
              children: [
                Icon(
                  Icons.credit_card_rounded,
                  color: primaryColor,
                  size: 26,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'SELECT PAYMENT METHOD',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: PaymentMethodStyle.navy,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final methods = PosPaymentMethodType.values
                    .where(allowedMethods.contains)
                    .where(
                      (m) => PosPaymentPermissionVisibility.canShowMethod(
                        permissions,
                        m,
                      ),
                    )
                    .toList(growable: false);

                if (!authoritative || methods.isEmpty) {
                  return const Center(
                    child: Text(
                      'No available payment methods',
                      key: ValueKey('payment-methods-empty'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  );
                }

                const gap = 12.0;
                const minimumCardHeight = 110.0;
                final rowCount = (methods.length / 2).ceil().clamp(1, 2);
                final fittedHeight =
                    (constraints.maxHeight - gap * (rowCount - 1)) / rowCount;
                final cardHeight = fittedHeight.clamp(minimumCardHeight, 140.0);

                final grid = PaymentMethodEqualGrid(
                  gap: gap,
                  cardHeight: cardHeight,
                  children: methods.map((method) {
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
                            content: Text(
                              '${method.title} is currently unavailable.',
                            ),
                          ));
                      },
                    );
                  }).toList(growable: false),
                );

                final requiredHeight =
                    cardHeight * rowCount + gap * (rowCount - 1);
                if (requiredHeight <= constraints.maxHeight) return grid;
                return SingleChildScrollView(
                  child: SizedBox(height: requiredHeight, child: grid),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
