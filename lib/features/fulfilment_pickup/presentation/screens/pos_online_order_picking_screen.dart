import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../domain/entities/pos_online_order.dart';
import '../providers/pos_online_orders_provider.dart';
import '../widgets/online_order_ui.dart';
import '../widgets/picking_widgets.dart';
import 'ready_for_collection_screen.dart';
import 'review_pack_screen.dart';

class PosOnlineOrderPickingScreen extends ConsumerWidget {
  const PosOnlineOrderPickingScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(posPickingOrderProvider(orderId));
    final granted = ref.watch(authSessionProvider)?.permissionCodes.toSet() ??
        const <String>{};
    return ColoredBox(
      color: OnlineOrderUi.canvas,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: order.when(
          loading: () => const OnlineOrderScreenState(
            message: 'Loading fulfilment workspace…',
            icon: Icons.hourglass_top,
          ),
          error: (_, __) => OnlineOrderScreenState(
            message: 'Unable to load the picking order.',
            icon: Icons.error_outline,
            onRetry: () => ref.invalidate(posPickingOrderProvider(orderId)),
          ),
          data: (value) {
            final status = value.status.toUpperCase();
            if (status == 'READY' || status == 'READY_FOR_COLLECTION') {
              return ReadyForCollectionScreen(
                order: value,
                onBack: () => context.go('/pos/online-orders'),
              );
            }

            if ((status == 'PICKED' || status == 'PACKED') &&
                !PosPermissionAccess.canViewOnlineOrderPacking(granted)) {
              return const OnlineOrderScreenState(
                message: 'Packing workspace permission is required.',
                icon: Icons.lock_outline,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PickingHeader(
                  order: value,
                  onBack: () => context.go('/pos/online-orders'),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: status == 'PICKED' || status == 'PACKED'
                      ? ReviewPackScreen(order: value)
                      : _PickingWorkspace(orderId: orderId, order: value),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PickingWorkspace extends StatelessWidget {
  const _PickingWorkspace({required this.orderId, required this.order});

  final String orderId;
  final PosPickingOrder order;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final items = PickingItemsList(orderId: orderId, lines: order.lines);
          final side = PickingOrderSidebar(order: order);
          if (constraints.maxWidth >= OnlineOrderUi.tabletLandscapeBreakpoint) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 7, child: items),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: side),
              ],
            );
          }
          return Column(
            children: [
              side,
              const SizedBox(height: 12),
              Expanded(child: items),
            ],
          );
        },
      );
}
