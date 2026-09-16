import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../utils/order_detail_next_action.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../../shared/widgets/pos_action_buttons.dart';
import '../../domain/entities/pos_online_order.dart';
import '../providers/pos_online_orders_provider.dart';
import '../widgets/online_order_detail_widgets.dart';
import '../widgets/online_order_ui.dart';
import '../widgets/start_fulfilment_dialog.dart';

class OnlineOrderDetailScreen extends ConsumerStatefulWidget {
  const OnlineOrderDetailScreen(
      {required this.state, this.showBackButton = false, super.key});
  final PosOnlineOrdersState state;
  final bool showBackButton;

  @override
  ConsumerState<OnlineOrderDetailScreen> createState() =>
      _OnlineOrderDetailScreenState();
}

class _OnlineOrderDetailScreenState
    extends ConsumerState<OnlineOrderDetailScreen> {
  bool _navigating = false;
  PosOnlineOrdersState get state => widget.state;
  bool get showBackButton => widget.showBackButton;

  @override
  Widget build(BuildContext context) {
    if (state.isLoadingDetail && state.selected == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final detail = state.selected;
    if (detail == null) {
      return OnlineOrderScreenState(
        message:
            state.detailErrorMessage ?? 'This online order is unavailable.',
        icon: Icons.error_outline,
        onRetry: () {
          final id = GoRouterState.of(context).pathParameters['orderId'];
          if (id != null) ref.read(posOnlineOrdersProvider.notifier).select(id);
        },
      );
    }
    final permissions =
        ref.watch(authSessionProvider)?.permissionCodes.toSet() ??
            const <String>{};
    final next = orderDetailNextAction(detail, permissions);
    final action = _action(context, ref, detail, next);
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < OnlineOrderUi.phoneBreakpoint;
      final stackedHeader = constraints.maxWidth < 1100;
      // The POS shell consumes a material portion of the physical tablet
      // height. Available width, rather than the reduced body height, is the
      // reliable authority for the fixed landscape composition.
      final fixedLandscape = !stackedHeader;
      final content = Padding(
        padding: EdgeInsets.fromLTRB(
          compact
              ? 16
              : fixedLandscape
                  ? 24
                  : 30,
          compact
              ? 16
              : fixedLandscape
                  ? 6
                  : 18,
          compact
              ? 16
              : fixedLandscape
                  ? 24
                  : 30,
          compact
              ? 20
              : fixedLandscape
                  ? 8
                  : 30,
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (showBackButton)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const Key('oo02-back-to-orders'),
                onPressed: () => context.go('/pos/online-orders'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Orders'),
                style: fixedLandscape
                    ? TextButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )
                    : null,
              ),
            ),
          SizedBox(height: fixedLandscape ? 2 : 6),
          OrderDetailHeader(
            detail: detail,
            compact: stackedHeader,
            dense: fixedLandscape,
          ),
          if (state.detailErrorMessage != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              label: state.detailErrorMessage,
              child: MaterialBanner(
                content: Text(state.detailErrorMessage!),
                actions: [
                  TextButton(
                    onPressed: () => ref
                        .read(posOnlineOrdersProvider.notifier)
                        .select(detail.order.id),
                    child: const Text('Refresh'),
                  )
                ],
              ),
            ),
          ],
          SizedBox(height: fixedLandscape ? 8 : 22),
          OrderSummaryCards(detail: detail, dense: fixedLandscape),
          SizedBox(height: fixedLandscape ? 8 : 20),
          if (fixedLandscape)
            Expanded(
              child: OrderItemsSection(detail: detail, dense: true),
            )
          else
            OrderItemsSection(detail: detail),
          if (action != null) ...[
            const SizedBox(height: 8),
            action,
          ],
        ]),
      );
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        child: fixedLandscape
            ? KeyedSubtree(
                key: const Key('oo02-fixed-landscape-body'),
                child: content,
              )
            : SingleChildScrollView(child: content),
      );
    });
  }

  Widget? _action(BuildContext context, WidgetRef ref,
      PosOnlineOrderDetail detail, OrderDetailNextAction next) {
    if (next == OrderDetailNextAction.hidden ||
        next == OrderDetailNextAction.readOnly) {
      return null;
    }
    if (next == OrderDetailNextAction.unavailable) {
      return Semantics(
        liveRegion: true,
        child: Row(key: const Key('oo02-unavailable'), children: [
          const Icon(Icons.info_outline),
          const SizedBox(width: 8),
          const Expanded(
              child: Text(
                  'Fulfilment details are incomplete or inconsistent. Refresh to check again. If this continues, contact your administrator.')),
          TextButton(
              onPressed: state.isLoadingDetail
                  ? null
                  : () => ref
                      .read(posOnlineOrdersProvider.notifier)
                      .select(detail.order.id),
              child: const Text('Refresh')),
        ]),
      );
    }
    final label = switch (next) {
      OrderDetailNextAction.start => 'Start Fulfilment',
      OrderDetailNextAction.pick => 'Continue Picking',
      OrderDetailNextAction.pack => 'Review & Pack',
      OrderDetailNextAction.ready => 'View Ready for Collection',
      _ => throw StateError('Unsupported detail action'),
    };
    return PosPrimaryActionButton(
      key: Key(next == OrderDetailNextAction.start
          ? 'oo02-start-fulfilment'
          : 'oo02-next-action'),
      label: label,
      semanticLabel: label,
      fullWidth: true,
      isLoading:
          state.isLoadingDetail || state.isStartingFulfillment || _navigating,
      onPressed: state.isLoadingDetail ||
              state.detailErrorMessage != null ||
              _navigating
          ? null
          : () async {
              if (_navigating) return;
              setState(() => _navigating = true);
              try {
                if (next == OrderDetailNextAction.start) {
                  await _start(context, ref, detail);
                } else {
                  ref.invalidate(posPickingOrderProvider(detail.order.id));
                  await context
                      .push('/pos/online-orders/${detail.order.id}/picking');
                  if (context.mounted) {
                    await ref
                        .read(posOnlineOrdersProvider.notifier)
                        .select(detail.order.id);
                  }
                }
              } finally {
                if (mounted) setState(() => _navigating = false);
              }
            },
    );
  }

  Future<void> _start(
      BuildContext context, WidgetRef ref, PosOnlineOrderDetail detail) async {
    PosStartFulfillmentResult? result;
    final started = await StartFulfilmentDialog.show(
      context,
      detail,
      onConfirm: () async {
        result = await ref
            .read(posOnlineOrdersProvider.notifier)
            .startFulfillment(detail.order.id);
        return result != null;
      },
    );
    if (!started || !context.mounted) return;
    if (result != null && context.mounted) {
      context.go('/pos/online-orders/${result!.orderId}/picking');
    }
  }
}
