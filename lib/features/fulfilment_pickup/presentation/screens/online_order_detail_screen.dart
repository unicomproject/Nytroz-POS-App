import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/access/pos_access_codes.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../domain/entities/pos_online_order.dart';
import '../providers/pos_online_orders_provider.dart';
import '../widgets/online_order_detail_widgets.dart';
import '../widgets/online_order_ui.dart';
import '../widgets/start_fulfilment_dialog.dart';

class OnlineOrderDetailScreen extends ConsumerWidget {
  const OnlineOrderDetailScreen({
    required this.state,
    this.showBackButton = false,
    super.key,
  });

  final PosOnlineOrdersState state;
  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoadingDetail) {
      return const Card(child: Center(child: CircularProgressIndicator()));
    }
    if (state.detailErrorMessage != null) {
      return Card(
        child: OnlineOrderScreenState(
          message: state.detailErrorMessage!,
          icon: Icons.error_outline,
        ),
      );
    }
    final detail = state.selected;
    if (detail == null) {
      return const Card(
        child: OnlineOrderScreenState(
          message: 'Select an order to view details.',
          icon: Icons.touch_app_outlined,
        ),
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < OnlineOrderUi.phoneBreakpoint;
          final header = <Widget>[
            if (showBackButton)
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton.outlined(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
            OnlineOrderHero(detail: detail),
            const SizedBox(height: 4),
            Text('${detail.order.customerName} • '
                '${detail.customerPhone ?? 'No phone'}'),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = [
                  OrderCollectionSummaryCard(detail: detail),
                  OrderPaymentSummaryCard(detail: detail),
                  OrderItemsSummaryCard(detail: detail),
                ];
                if (constraints.maxWidth >= 720) {
                  return Row(
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        Expanded(child: cards[i]),
                        if (i < cards.length - 1) const SizedBox(width: 8),
                      ],
                    ],
                  );
                }
                return Column(
                  children: cards
                      .map((card) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: card,
                          ))
                      .toList(growable: false),
                );
              },
            ),
            const SizedBox(height: 12),
          ];
          final footer = <Widget>[
            const Divider(),
            OrderTotals(detail: detail),
            if (_isStartEligible(detail)) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: OnlineOrderUi.accent,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: state.isStartingFulfillment ||
                        ref.watch(authSessionProvider)?.hasPermission(
                                PosPermissionCodes
                                    .startOnlineOrderFulfillment) !=
                            true
                    ? null
                    : () => _start(context, ref, detail),
                icon: state.isStartingFulfillment
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: const Text('Start Fulfilment'),
              ),
              if (ref.watch(authSessionProvider)?.hasPermission(
                      PosPermissionCodes.startOnlineOrderFulfillment) !=
                  true)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Start fulfilment permission is required.',
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ];

          if (compact) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...header,
                  const Text('Order Items',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  OnlineOrderItemList(detail: detail, shrinkWrap: true),
                  ...footer,
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...header,
                const Text('Order Items',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Expanded(child: OnlineOrderItemList(detail: detail)),
                ...footer,
              ],
            ),
          );
        },
      ),
    );
  }

  bool _isStartEligible(PosOnlineOrderDetail detail) =>
      detail.order.status == 'PENDING_CONFIRMATION' ||
      detail.order.status == 'ACCEPTED';

  Future<void> _start(
    BuildContext context,
    WidgetRef ref,
    PosOnlineOrderDetail detail,
  ) async {
    final confirmed = await StartFulfilmentDialog.show(context, detail);
    if (!confirmed || !context.mounted) return;
    final result = await ref
        .read(posOnlineOrdersProvider.notifier)
        .startFulfillment(detail.order.id);
    if (result != null && context.mounted) {
      context.go('/pos/online-orders/${detail.order.id}/picking');
    }
  }
}
