import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/pos_action_buttons.dart';
import '../../../sale/presentation/widgets/print_receipt/print_receipt_actions.dart';
import '../../../sale/presentation/providers/pos_cash_payment_success_provider.dart';
import '../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../providers/pos_online_order_collection_provider.dart';
import '../widgets/online_order_ui.dart';

class CollectionCompleteScreen extends ConsumerStatefulWidget {
  const CollectionCompleteScreen({super.key});

  @override
  ConsumerState<CollectionCompleteScreen> createState() =>
      _CollectionCompleteScreenState();
}

class _CollectionCompleteScreenState
    extends ConsumerState<CollectionCompleteScreen> {
  bool _printing = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(posOnlineOrderCollectionProvider);
    final complete = state.completeResult;
    final validation = state.validation;
    final orderNumber =
        complete?.orderNumber ?? validation?.orderNumber ?? 'Order';
    final collectedAt = complete?.collectedAt;
    final saleIdForPrint =
        state.lastPaymentSaleId ?? validation?.orderId ?? complete?.orderId;

    return ColoredBox(
      color: OnlineOrderUi.canvas,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            margin: const EdgeInsets.all(24),
            color: Colors.white,
            surfaceTintColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    key: Key('collection-complete-success-icon'),
                    size: 64,
                    color: TenantAdminColors.success,
                  ),
                  const SizedBox(height: 12),
                  const Text('Collection complete', style: OnlineOrderUi.title),
                  const SizedBox(height: 8),
                  Text(
                    complete?.alreadyCollected == true
                        ? '$orderNumber was already collected.'
                        : '$orderNumber has been handed over.',
                    textAlign: TextAlign.center,
                    style: OnlineOrderUi.subtitle,
                  ),
                  if (collectedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Collected at ${OnlineOrderUi.collection(collectedAt)}',
                      style: OnlineOrderUi.subtitle,
                    ),
                  ],
                  const SizedBox(height: 24),
                  PosPrimaryActionButton(
                    key: const Key('collection-print-receipt'),
                    label: 'Print Receipt',
                    leadingIcon: Icons.print_outlined,
                    fullWidth: true,
                    isLoading: _printing,
                    onPressed: saleIdForPrint == null || saleIdForPrint.isEmpty
                        ? null
                        : () async {
                            if (_printing) return;
                            final payment =
                                ref.read(posCashPaymentSuccessProvider);
                            if (payment?.saleId != saleIdForPrint ||
                                payment?.authoritativePayment == null) {
                              context.push(Uri(
                                path: '/pos/orders',
                                queryParameters: {'query': orderNumber},
                              ).toString());
                              return;
                            }
                            setState(() => _printing = true);
                            try {
                              await executeReceiptPrint(
                                  context, ref, saleIdForPrint);
                            } finally {
                              if (mounted) setState(() => _printing = false);
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      ref
                          .read(posOnlineOrderCollectionProvider.notifier)
                          .clear();
                      ref
                          .read(collectionPaymentContextProvider.notifier)
                          .state = null;
                      context.go('/pos/online-orders');
                    },
                    child: const Text('Back to Online Orders'),
                  ),
                  if (validation?.orderId != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context
                          .go('/pos/online-orders/${validation!.orderId}'),
                      child: const Text('View details'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
