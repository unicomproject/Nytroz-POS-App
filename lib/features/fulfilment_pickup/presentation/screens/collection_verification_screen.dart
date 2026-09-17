import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../../shared/widgets/pos_action_buttons.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../tenant_admin/presentation/screens/tenant_admin_forbidden_screen.dart';
import '../providers/pos_online_order_collection_provider.dart';
import '../providers/pos_online_orders_provider.dart';
import '../widgets/collection/collection_verification_widgets.dart';
import '../widgets/online_order_ui.dart';

class CollectionVerificationScreen extends ConsumerWidget {
  const CollectionVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final permissions =
        ref.watch(authSessionProvider)?.permissionCodes.toSet() ?? const {};
    if (!PosPermissionAccess.canValidateCollectionQr(permissions)) {
      return const TenantAdminForbiddenScreen();
    }

    final state = ref.watch(posOnlineOrderCollectionProvider);
    final validation = state.validation;
    if (validation == null) {
      return ColoredBox(
        color: OnlineOrderUi.canvas,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No validated collection order.',
                  style: OnlineOrderUi.title),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () =>
                    context.go('/pos/online-orders/collection/scan'),
                child: const Text('Scan again'),
              ),
            ],
          ),
        ),
      );
    }

    final takePayment = validation.canTakePayment;
    return ColoredBox(
      color: OnlineOrderUi.canvas,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.go('/pos/online-orders/collection/scan'),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Scan'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text('Verify Collection', style: OnlineOrderUi.title),
              ),
              Chip(
                label: const Text('Step 2 of 4'),
                backgroundColor: scheme.primaryContainer,
                labelStyle: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Confirm customer and packed items before handover.',
            style: OnlineOrderUi.subtitle,
          ),
          const SizedBox(height: 16),
          CollectionVerificationSummary(result: validation),
          const SizedBox(height: 20),
          if (takePayment)
            PosPrimaryActionButton(
              key: const Key('collection-take-payment'),
              label: 'Take Payment',
              leadingIcon: Icons.payments_outlined,
              fullWidth: true,
              onPressed: () {
                final outletId = ref.read(posOnlineOrdersOutletIdProvider) ??
                    validation.outletId;
                ref.read(collectionPaymentContextProvider.notifier).state =
                    CollectionPaymentContext(
                  salesOrderId: validation.orderId,
                  orderNumber: validation.orderNumber,
                  amountDue: validation.balanceDueCheckoutAmount,
                  currency: validation.currency,
                  expectedVersion: validation.expectedVersion,
                  outletId: outletId,
                );
                context.push('/pos/online-orders/collection/payment');
              },
            )
          else
            PosPrimaryActionButton(
              key: const Key('collection-confirm-handover'),
              label: 'Confirm Handover',
              leadingIcon: Icons.handshake_outlined,
              fullWidth: true,
              onPressed: PosPermissionAccess.canHandoverCollection(permissions)
                  ? () {
                      ref
                          .read(posOnlineOrderCollectionProvider.notifier)
                          .prepareHandover();
                      context.go('/pos/online-orders/collection/handover');
                    }
                  : null,
            ),
        ],
      ),
    );
  }
}
