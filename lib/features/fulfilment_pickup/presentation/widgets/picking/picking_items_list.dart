import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/access/pos_access_codes.dart';
import '../../../../../shared/presentation/app_modal.dart';
import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../domain/entities/pos_online_order.dart';
import '../../providers/pos_online_orders_provider.dart';
import '../../utils/picking_visual_metrics.dart';
import '../online_order_ui.dart';
import 'fulfilment_stepper.dart';
import 'pick_item_scanner_panel.dart';
import 'picking_item_card.dart';
import 'report_picking_issue_dialog.dart';

class PickingItemsList extends ConsumerWidget {
  const PickingItemsList(
      {required this.orderId, required this.order, super.key});
  final String orderId;
  final PosPickingOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final canPick =
        session?.hasPermission(PosPermissionCodes.pickOnlineOrderItem) == true;
    final canScan = canPick &&
        session?.hasPermission(PosPermissionCodes.scanOnlineOrderItem) == true;
    final canManual = canPick &&
        session?.hasPermission(
                PosPermissionCodes.manuallyEnterOnlineOrderItem) ==
            true;
    final canReport = session
            ?.hasPermission(PosPermissionCodes.reportOnlineOrderPickingIssue) ==
        true;
    PosPickingLine? active;
    for (final line in order.lines) {
      if (!line.isPicked) {
        active = line;
        break;
      }
    }
    return Container(
      decoration: pickingCardDecoration(context),
      padding: const EdgeInsets.all(6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const FulfilmentStepper(status: 'PICKING'),
        const SizedBox(height: 6),
        Expanded(
            child: order.lines.isEmpty
                ? const OnlineOrderScreenState(
                    message: 'No picking items are available.')
                : order.lines.length <= 3
                    ? LayoutBuilder(builder: (context, constraints) {
                        final metrics = PickingVisualMetrics.forHeight(
                            constraints.maxHeight);
                        final availablePerLine = (constraints.maxHeight -
                                (order.lines.length - 1) * metrics.gap) /
                            3;
                        final cardHeight = availablePerLine
                            .clamp(84.0, metrics.lineHeight)
                            .toDouble();
                        return Column(
                          children: [
                            for (var index = 0;
                                index < order.lines.length;
                                index++) ...[
                              SizedBox(
                                height: cardHeight,
                                child: PickingItemCard(
                                  line: order.lines[index],
                                  selected:
                                      order.lines[index].status.toUpperCase() ==
                                          'PICKING',
                                  onPick: canScan || canManual
                                      ? () => _showPick(
                                          context, ref, order.lines[index])
                                      : null,
                                  onIssue:
                                      canReport && !order.lines[index].isPicked
                                          ? () => _showIssue(
                                              context, ref, order.lines[index])
                                          : null,
                                ),
                              ),
                              if (index < order.lines.length - 1)
                                SizedBox(height: metrics.gap),
                            ],
                          ],
                        );
                      })
                    : ListView.separated(
                        key: const Key('picking-lines-list'),
                        itemCount: order.lines.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (_, index) => PickingItemCard(
                          line: order.lines[index],
                          selected: order.lines[index].status.toUpperCase() ==
                              'PICKING',
                          onPick: canScan || canManual
                              ? () =>
                                  _showPick(context, ref, order.lines[index])
                              : null,
                          onIssue: canReport && !order.lines[index].isPicked
                              ? () =>
                                  _showIssue(context, ref, order.lines[index])
                              : null,
                        ),
                      )),
        if (canScan && active != null) ...[
          const SizedBox(height: 6),
          Semantics(
              button: true,
              label: 'Scan Item Barcode',
              child: OutlinedButton.icon(
                key: const Key('scan-item-barcode'),
                onPressed: () =>
                    _showPick(context, ref, active!, preferScan: true),
                icon: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(7)),
                    child: const Icon(Icons.qr_code_scanner, size: 18)),
                label: const Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scan Item Barcode',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w800)),
                          Text('Scan to pick item quickly',
                              style: TextStyle(fontSize: 11)),
                        ])),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    padding: const EdgeInsets.symmetric(horizontal: 12)),
              )),
        ],
      ]),
    );
  }

  Future<void> _showPick(
      BuildContext context, WidgetRef ref, PosPickingLine line,
      {bool preferScan = false}) async {
    final result = await showAppDialog<PickItemResult>(
        context: context,
        builder: (_) =>
            PickItemScannerPanel(line: line, preferScan: preferScan));
    if (result == null || !context.mounted) return;
    try {
      await ref
          .read(posPickingActionsProvider(orderId))
          .pick(order, line, scanned: result.scanned, barcode: result.barcode);
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _showIssue(
      BuildContext context, WidgetRef ref, PosPickingLine line) async {
    final note = await ReportPickingIssueDialog.show(context, line);
    if (note == null || !context.mounted) return;
    try {
      await ref
          .read(posPickingActionsProvider(orderId))
          .issue(order, line, 'ITEM_NOT_FOUND', note);
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  static void _showError(BuildContext context, Object error) {
    final message = error is DioException
        ? onlineOrderErrorMessage(error)
        : 'Unable to complete the picking action. Try again.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
