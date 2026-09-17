import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/pos_action_buttons.dart';
import '../../../sale/presentation/providers/pos_cash_payment_success_provider.dart';
import '../../../sale/presentation/providers/pos_checkout_summary_provider.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/pos_online_order_collection_provider.dart';
import '../widgets/online_order_ui.dart';

/// Confirms settlement before the cashier performs the separate handover step.
class CollectionPaymentSuccessScreen extends ConsumerWidget {
  const CollectionPaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collection = ref.watch(posOnlineOrderCollectionProvider);
    final payment = ref.watch(posCashPaymentSuccessProvider);
    final validation = collection.validation;

    if (validation == null || payment == null) {
      return ColoredBox(
        color: OnlineOrderUi.canvas,
        child: Center(
          child: OutlinedButton(
            onPressed: () => context.go(
              '/pos/online-orders/collection/verification',
            ),
            child: const Text('Back to Verification'),
          ),
        ),
      );
    }

    final method = payment.authoritativePayment?.paymentMethod.trim();
    final methodLabel = method == null || method.isEmpty
        ? 'Cash'
        : method
            .split('_')
            .map((part) => part.isEmpty
                ? part
                : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
            .join(' ');

    return PopScope(
      canPop: false,
      child: ColoredBox(
        color: OnlineOrderUi.canvas,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                color: Colors.white,
                surfaceTintColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        key: Key('collection-payment-success-icon'),
                        size: 68,
                        color: TenantAdminColors.success,
                      ),
                      const SizedBox(height: 12),
                      const Text('Payment successful',
                          style: OnlineOrderUi.title),
                      const SizedBox(height: 6),
                      Text(
                        'Payment is complete. Continue when the order is ready to hand over.',
                        textAlign: TextAlign.center,
                        style: OnlineOrderUi.subtitle,
                      ),
                      const SizedBox(height: 22),
                      _PaymentDetail(
                        label: 'Order',
                        value: validation.orderNumber,
                      ),
                      _PaymentDetail(
                        label: 'Amount paid',
                        value: formatCheckoutMoney(
                          payment.authoritativePayment?.currency ??
                              validation.currency,
                          payment.total,
                        ),
                      ),
                      _PaymentDetail(label: 'Method', value: methodLabel),
                      _PaymentDetail(
                        label: 'Cash received',
                        value: formatCheckoutMoney(
                          payment.authoritativePayment?.currency ??
                              validation.currency,
                          payment.cashReceived,
                        ),
                      ),
                      _PaymentDetail(
                        label: 'Change',
                        value: formatCheckoutMoney(
                          payment.authoritativePayment?.currency ??
                              validation.currency,
                          payment.changeDue,
                        ),
                      ),
                      const SizedBox(height: 22),
                      PosPrimaryActionButton(
                        key: const Key('collection-continue-handover'),
                        label: 'Continue to Handover',
                        leadingIcon: Icons.handshake_outlined,
                        fullWidth: true,
                        onPressed: () {
                          ref
                              .read(posOnlineOrderCollectionProvider.notifier)
                              .prepareHandover();
                          context.go(
                            '/pos/online-orders/collection/handover',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentDetail extends StatelessWidget {
  const _PaymentDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(child: Text(label, style: OnlineOrderUi.subtitle)),
            const SizedBox(width: 16),
            Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: OnlineOrderUi.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}
