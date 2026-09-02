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

class PosOnlineOrderPickingScreen extends ConsumerStatefulWidget {
  const PosOnlineOrderPickingScreen({required this.orderId, super.key});

  final String orderId;

  @override
  ConsumerState<PosOnlineOrderPickingScreen> createState() =>
      _PosOnlineOrderPickingScreenState();
}

class _PosOnlineOrderPickingScreenState
    extends ConsumerState<PosOnlineOrderPickingScreen> {
  bool showReviewPack = false;

  @override
  Widget build(BuildContext context) {
    final granted = ref.watch(authSessionProvider)?.permissionCodes.toSet() ??
        const <String>{};
    if (!PosPermissionAccess.canViewOnlineOrderPicking(granted)) {
      return const ColoredBox(
        color: OnlineOrderUi.canvas,
        child: OnlineOrderScreenState(
          message: 'You do not have permission to access order picking.',
          icon: Icons.lock_outline,
        ),
      );
    }
    final order = ref.watch(posPickingOrderProvider(widget.orderId));
    return ColoredBox(
      color: OnlineOrderUi.canvas,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 14),
        child: order.when(
          loading: () => const OnlineOrderScreenState(
            message: 'Loading fulfilment workspace…',
            icon: Icons.hourglass_top,
          ),
          error: (_, __) => OnlineOrderScreenState(
            message: 'Unable to load the picking order.',
            icon: Icons.error_outline,
            onRetry: () =>
                ref.invalidate(posPickingOrderProvider(widget.orderId)),
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

            if (showReviewPack) {
              return ReviewPackScreen(order: value);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PickingHeader(
                  order: value,
                  onBack: () =>
                      context.go('/pos/online-orders/${widget.orderId}'),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: status == 'PICKED' || status == 'PACKED'
                      ? ReviewPackScreen(order: value)
                      : PickingWorkspace(
                          orderId: widget.orderId,
                          order: value,
                          onReviewPack: () =>
                              setState(() => showReviewPack = true),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class PickingWorkspace extends StatelessWidget {
  const PickingWorkspace({
    required this.orderId,
    required this.order,
    required this.onReviewPack,
    super.key,
  });

  final String orderId;
  final PosPickingOrder order;
  final VoidCallback onReviewPack;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final items = PickingItemsList(orderId: orderId, order: order);
          final side = PickingOrderSidebar(
            order: order,
            orderId: orderId,
            onReviewPack: onReviewPack,
          );
          if (constraints.maxWidth >= OnlineOrderUi.tabletLandscapeBreakpoint) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 64, child: items),
                const SizedBox(width: 14),
                Expanded(flex: 36, child: side),
              ],
            );
          }
          return SingleChildScrollView(
            child: Column(children: [
              SizedBox(height: 620, child: items),
              const SizedBox(height: 12),
              side,
            ]),
          );
        },
      );
}
