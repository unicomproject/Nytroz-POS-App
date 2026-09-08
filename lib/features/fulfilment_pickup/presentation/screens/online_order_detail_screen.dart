import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_access_codes.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../../shared/widgets/pos_action_buttons.dart';
import '../../domain/entities/pos_online_order.dart';
import '../providers/pos_online_orders_provider.dart';
import '../widgets/online_order_detail_widgets.dart';
import '../widgets/online_order_ui.dart';
import '../widgets/start_fulfilment_dialog.dart';

class OnlineOrderDetailScreen extends ConsumerWidget {
  const OnlineOrderDetailScreen(
      {required this.state, this.showBackButton = false, super.key});
  final PosOnlineOrdersState state;
  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final canStart = ref.watch(authSessionProvider)?.hasPermission(
              PosPermissionCodes.startOnlineOrderFulfillment,
            ) ==
        true;
    final lifecycle =
        (detail.fulfillmentStatus ?? detail.order.status).trim().toUpperCase();
    final startEligible =
        const {'PENDING', 'ALLOCATED', 'ACCEPTED'}.contains(lifecycle);
    final alreadyPicking = lifecycle == 'PICKING';

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
            action: _action(context, ref, detail,
                canStart: canStart,
                startEligible: startEligible,
                alreadyPicking: alreadyPicking,
                dense: fixedLandscape),
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

  Widget? _action(
      BuildContext context, WidgetRef ref, PosOnlineOrderDetail detail,
      {required bool canStart,
      required bool startEligible,
      required bool alreadyPicking,
      required bool dense}) {
    if (alreadyPicking) {
      final canContinuePicking = ref.watch(authSessionProvider)?.hasPermission(
                PosPermissionCodes.viewOnlineOrderPicking,
              ) ==
          true;
      if (!canContinuePicking) return null;
      return FilledButton.icon(
        onPressed: () =>
            context.go('/pos/online-orders/${detail.order.id}/picking'),
        icon: const Icon(Icons.inventory_2_outlined),
        label: const Text('Continue Picking'),
      );
    }
    if (!canStart || !startEligible) return null;
    return Semantics(
      button: true,
      label: 'Start Fulfilment',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PosPrimaryActionButton(
            key: const Key('oo02-start-fulfilment'),
            label: 'START\nFULFILMENT',
            semanticLabel: 'Start Fulfilment',
            onPressed: () => _start(context, ref, detail),
            isLoading: state.isStartingFulfillment,
            fullWidth: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            minimumHeight: dense ? 64 : 92,
            horizontalPadding: dense ? 22 : 26,
            verticalPadding: dense ? 10 : 18,
            borderRadius: 14,
            leadingIcon: Icons.inventory_2_outlined,
            iconSize: dense ? 26 : 34,
            maxLabelLines: 2,
            labelTextAlign: TextAlign.left,
            textStyle: TextStyle(
              fontSize: dense ? 15 : 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: dense ? 5 : 10),
          Text(
            'Accept and start picking this order',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
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
