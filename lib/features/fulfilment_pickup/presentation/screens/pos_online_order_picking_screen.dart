import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../domain/entities/pos_online_order.dart';
import '../providers/pos_online_orders_provider.dart';
import '../widgets/online_order_ui.dart';
import '../widgets/picking/picking_header.dart';
import '../widgets/picking/picking_items_list.dart';
import '../widgets/picking/picking_order_sidebar.dart';
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
  bool _leftReviewPack = false;
  bool _showReviewFromReady = false;

  @override
  void didUpdateWidget(covariant PosOnlineOrderPickingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId) {
      showReviewPack = false;
      _leftReviewPack = false;
      _showReviewFromReady = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final granted = ref.watch(authSessionProvider)?.permissionCodes.toSet() ??
        const <String>{};
    if (!PosPermissionAccess.canViewOnlineOrderPicking(granted) &&
        !PosPermissionAccess.canViewOnlineOrderReady(granted)) {
      return const ColoredBox(
        color: OnlineOrderUi.canvas,
        child: OnlineOrderScreenState(
          message: 'You do not have permission to access order fulfilment.',
          icon: Icons.lock_outline,
        ),
      );
    }
    final order = ref.watch(posPickingOrderProvider(widget.orderId));
    return ColoredBox(
      color: OnlineOrderUi.canvas,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
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
            if (value.isReadyForCollection && !_showReviewFromReady) {
              if (!PosPermissionAccess.canViewOnlineOrderReady(granted)) {
                return const OnlineOrderScreenState(
                  message: 'Ready-for-collection permission is required.',
                  icon: Icons.lock_outline,
                );
              }
              return ReadyForCollectionScreen(
                key: ValueKey('ready-${value.orderId}'),
                order: value,
                onBack: () => context.go('/pos/online-orders'),
                onBackToReviewPack: () {
                  setState(() => _showReviewFromReady = true);
                },
              );
            }

            if (_showReviewFromReady && value.isReadyForCollection) {
              return ReviewPackScreen(
                key: ValueKey('review-from-ready-${value.orderId}'),
                order: value,
                onBackToPickItems: () {
                  setState(() => _showReviewFromReady = false);
                },
              );
            }

            if (!PosPermissionAccess.canViewOnlineOrderPicking(granted)) {
              return const OnlineOrderScreenState(
                message: 'You do not have permission to access order picking.',
                icon: Icons.lock_outline,
              );
            }

            final inReview = value.isPacked ||
                showReviewPack ||
                (value.canPack && !_leftReviewPack);

            if (inReview &&
                !PosPermissionAccess.canViewOnlineOrderPacking(granted)) {
              return const OnlineOrderScreenState(
                message: 'Packing workspace permission is required.',
                icon: Icons.lock_outline,
              );
            }

            if (inReview) {
              return ReviewPackScreen(
                key: ValueKey('review-pack-${value.orderId}'),
                order: value,
                onBackToPickItems: () {
                  if (value.isPacked) {
                    context.go('/pos/online-orders/${widget.orderId}');
                    return;
                  }
                  setState(() {
                    showReviewPack = false;
                    _leftReviewPack = true;
                  });
                },
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PickingHeader(
                  order: value,
                  onBack: () =>
                      context.go('/pos/online-orders/${widget.orderId}'),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: PickingWorkspace(
                    orderId: widget.orderId,
                    order: value,
                    onReviewPack: () {
                      if (!PosPermissionAccess.canViewOnlineOrderPacking(
                          granted)) {
                        return;
                      }
                      setState(() {
                        showReviewPack = true;
                        _leftReviewPack = false;
                      });
                    },
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
                const SizedBox(width: 12),
                Expanded(flex: 36, child: side),
              ],
            );
          }
          // Narrow / phone: existing stacked path may scroll. Landscape tablet+
          // above remains fixed (no page scroll).
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 560, child: items),
                const SizedBox(height: 10),
                side,
              ],
            ),
          );
        },
      );
}
