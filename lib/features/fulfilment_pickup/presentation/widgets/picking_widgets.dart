import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/access/pos_access_codes.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../domain/entities/pos_online_order.dart';
import '../providers/pos_online_orders_provider.dart';
import 'online_order_ui.dart';

class FulfilmentStepper extends StatelessWidget {
  const FulfilmentStepper({required this.status, super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final current = switch (status) {
      'PACKED' => 1,
      'READY' || 'READY_FOR_COLLECTION' => 2,
      _ => 0,
    };
    const labels = ['Pick Items', 'Review & Pack', 'Ready'];
    return Row(
      children: List.generate(labels.length, (index) {
        final active = index <= current;
        return Expanded(
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor:
                    active ? OnlineOrderUi.accent : Colors.blueGrey.shade100,
                child: Text('${index + 1}',
                    style: TextStyle(
                        color: active ? Colors.white : OnlineOrderUi.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(labels[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              if (index < labels.length - 1)
                const Expanded(child: Divider(indent: 8, endIndent: 8)),
            ],
          ),
        );
      }),
    );
  }
}

class PickingProgressMetrics extends StatelessWidget {
  const PickingProgressMetrics({required this.order, super.key});
  final PosPickingOrder order;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Metric('Items', '${order.totalLines}', Icons.inventory_2_outlined),
          _Metric('Picked', '${order.pickedLines}', Icons.check_circle_outline),
          _Metric('Remaining', '${order.totalLines - order.pickedLines}',
              Icons.pending_actions),
        ],
      );
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 118),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE4EAF2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: OnlineOrderUi.accent, size: 20),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: OnlineOrderUi.subtitle),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 17)),
            ]),
          ],
        ),
      );
}

class PickingHeader extends StatelessWidget {
  const PickingHeader({required this.order, required this.onBack, super.key});
  final PosPickingOrder order;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton.outlined(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pick Order • ${order.orderNumber}',
                            style: OnlineOrderUi.title),
                        Text(
                          '${order.customerName} • Assigned to ${order.assignedToName} • '
                          '${order.collectionAt == null ? 'No collection time' : DateFormat('dd MMM, hh:mm a').format(order.collectionAt!.toLocal())}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FulfilmentStepper(status: order.status),
            ],
          ),
        ),
      );
}

class PickingItemsList extends ConsumerWidget {
  const PickingItemsList(
      {required this.orderId, required this.lines, super.key});
  final String orderId;
  final List<PosPickingLine> lines;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final canPick =
        session?.hasPermission(PosPermissionCodes.pickOnlineOrderItem) == true;
    final canReport = session
            ?.hasPermission(PosPermissionCodes.reportOnlineOrderPickingIssue) ==
        true;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Items to Pick',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ),
          const Divider(height: 1),
          Expanded(
            child: lines.isEmpty
                ? const OnlineOrderScreenState(
                    message: 'No picking items are available.')
                : ListView.separated(
                    itemCount: lines.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) => PickingItemCard(
                      line: lines[index],
                      onPick: canPick
                          ? () => _showPick(context, ref, lines[index])
                          : null,
                      onIssue: canReport
                          ? () => _showIssue(context, ref, lines[index])
                          : null,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPick(
      BuildContext context, WidgetRef ref, PosPickingLine line) async {
    final result = await showDialog<PickItemResult>(
      context: context,
      builder: (_) => PickItemScannerPanel(line: line),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref.read(posPickingActionsProvider(orderId)).pick(
            line,
            scanned: result.scanned,
            barcode: result.barcode,
          );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to pick this item. Try again.')),
        );
      }
    }
  }

  Future<void> _showIssue(
      BuildContext context, WidgetRef ref, PosPickingLine line) async {
    final note = await ReportPickingIssueDialog.show(context, line);
    if (note == null || !context.mounted) return;
    try {
      await ref
          .read(posPickingActionsProvider(orderId))
          .issue(line, 'ITEM_NOT_FOUND', note);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to report the item issue.')),
        );
      }
    }
  }
}

class PickingItemCard extends StatelessWidget {
  const PickingItemCard({
    required this.line,
    this.onPick,
    this.onIssue,
    super.key,
  });
  final PosPickingLine line;
  final VoidCallback? onPick;
  final VoidCallback? onIssue;

  @override
  Widget build(BuildContext context) {
    final complete = line.pickedQuantity >= line.requestedQuantity;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final actions = Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${line.pickedQuantity}/${line.requestedQuantity}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              if (!complete)
                FilledButton.icon(
                  onPressed: onPick,
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: const Text('Pick item'),
                ),
              if (!complete)
                TextButton(onPressed: onIssue, child: const Text("Can't find")),
            ],
          );
          final product = PickItemProductPanel(line: line);
          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [product, const SizedBox(height: 10), actions],
            );
          }
          return Row(
            children: [
              Expanded(child: product),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class PickItemProductPanel extends StatelessWidget {
  const PickItemProductPanel({required this.line, super.key});
  final PosPickingLine line;
  @override
  Widget build(BuildContext context) => Row(
        children: [
          CircleAvatar(child: Text('${line.lineNumber}')),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.productName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text([
                  line.variantName,
                  if (line.sku != null) 'SKU ${line.sku}',
                  if (line.barcode != null) 'Barcode ${line.barcode}',
                  if (line.locationName != null)
                    '${line.locationName} (${line.locationCode ?? '-'})',
                ].whereType<String>().join(' • ')),
              ],
            ),
          ),
        ],
      );
}

class PickItemResult {
  const PickItemResult({required this.scanned, required this.barcode});
  final bool scanned;
  final String barcode;
}

class PickItemScannerPanel extends ConsumerStatefulWidget {
  const PickItemScannerPanel({required this.line, super.key});
  final PosPickingLine line;
  @override
  ConsumerState<PickItemScannerPanel> createState() =>
      _PickItemScannerPanelState();
}

class _PickItemScannerPanelState extends ConsumerState<PickItemScannerPanel> {
  final barcode = TextEditingController();

  @override
  void dispose() {
    barcode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final canScan =
        session?.hasPermission(PosPermissionCodes.scanOnlineOrderItem) == true;
    final canManual = session
            ?.hasPermission(PosPermissionCodes.manuallyEnterOnlineOrderItem) ==
        true;
    return AlertDialog(
      title: const Text('Verify Picked Item'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PickItemProductPanel(line: widget.line),
            const SizedBox(height: 16),
            TextField(
              controller: barcode,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Scanned or manually entered barcode',
                helperText: widget.line.barcode == null
                    ? 'No expected barcode is registered.'
                    : 'The server verifies the expected variant barcode.',
              ),
            ),
            const SizedBox(height: 12),
            PickQuantityPanel(
              requested: widget.line.requestedQuantity,
              picked: widget.line.pickedQuantity,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        OutlinedButton(
          onPressed: canManual
              ? () => Navigator.pop(
                    context,
                    PickItemResult(scanned: false, barcode: barcode.text),
                  )
              : null,
          child: const Text('Manual entry'),
        ),
        FilledButton.icon(
          onPressed: canScan
              ? () => Navigator.pop(
                    context,
                    PickItemResult(scanned: true, barcode: barcode.text),
                  )
              : null,
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Scan & pick'),
        ),
      ],
    );
  }
}

class PickQuantityPanel extends StatelessWidget {
  const PickQuantityPanel({
    required this.requested,
    required this.picked,
    super.key,
  });
  final double requested;
  final double picked;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final values = [
            Text('Requested: $requested'),
            Text('Already picked: $picked'),
            Text('This pick: ${requested - picked}'),
          ];
          if (constraints.maxWidth <= OnlineOrderUi.smallPhoneBreakpoint) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: values
                  .map((value) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: value,
                      ))
                  .toList(growable: false),
            );
          }
          return Row(
            children: values
                .map((value) => Expanded(child: value))
                .toList(growable: false),
          );
        },
      );
}

class PickingOrderSidebar extends StatelessWidget {
  const PickingOrderSidebar({required this.order, super.key});
  final PosPickingOrder order;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Order Progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              PickingProgressMetrics(order: order),
              const SizedBox(height: 14),
              _row('Fulfilment', order.fulfillmentNumber),
              _row('Status', order.status),
              const SizedBox(height: 12),
              const PickingTipsCard(),
              const SizedBox(height: 8),
              const PickingNoteAction(),
            ],
          ),
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(child: Text(label)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ]),
      );
}

class PickingTipsCard extends StatelessWidget {
  const PickingTipsCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text(
          'Verify the product, variant, barcode and quantity before confirming.',
          style: TextStyle(fontSize: 12),
        ),
      );
}

class PickingNoteAction extends StatelessWidget {
  const PickingNoteAction({super.key});
  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'Picking notes require verified API mapping in Chunk 3.',
        child: OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.note_add_outlined),
          label: const Text('Add Picking Note'),
        ),
      );
}

class ReportPickingIssueDialog extends StatefulWidget {
  const ReportPickingIssueDialog({required this.line, super.key});
  final PosPickingLine line;

  static Future<String?> show(
    BuildContext context,
    PosPickingLine line,
  ) =>
      showDialog<String>(
        context: context,
        builder: (_) => ReportPickingIssueDialog(line: line),
      );

  @override
  State<ReportPickingIssueDialog> createState() =>
      _ReportPickingIssueDialogState();
}

class _ReportPickingIssueDialogState extends State<ReportPickingIssueDialog> {
  final note = TextEditingController();
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Report item issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.line.productName,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: note,
              maxLength: 200,
              decoration:
                  const InputDecoration(labelText: 'What could not be found?'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, note.text),
            child: const Text('Report issue'),
          ),
        ],
      );
}
