import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/access/pos_access_codes.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../domain/entities/pos_online_order.dart';
import '../providers/pos_online_orders_provider.dart';
import '../widgets/online_order_ui.dart';
import '../widgets/picking/fulfilment_stepper.dart';
import '../widgets/picking/picking_progress_metrics.dart';

class ReviewPackScreen extends ConsumerStatefulWidget {
  const ReviewPackScreen({required this.order, super.key});
  final PosPickingOrder order;

  @override
  ConsumerState<ReviewPackScreen> createState() => _ReviewPackScreenState();
}

class _ReviewPackScreenState extends ConsumerState<ReviewPackScreen> {
  final notes = TextEditingController();
  bool busy = false;
  String? error;

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final isPacked = widget.order.status.toUpperCase() == 'PACKED';
    final canPack =
        session?.hasPermission(PosPermissionCodes.viewOnlineOrderPacking) ==
                true &&
            session?.hasPermission(PosPermissionCodes.packOnlineOrder) == true;
    final canMarkReady = session
                ?.hasPermission(PosPermissionCodes.viewOnlineOrderPacking) ==
            true &&
        session?.hasPermission(PosPermissionCodes.markOnlineOrderReady) == true;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth >= OnlineOrderUi.tabletLandscapeBreakpoint;
        final items = PickedItemsReviewList(lines: widget.order.lines);
        final side = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PackingNotesCard(controller: notes),
            const SizedBox(height: 12),
            PackingReadinessSummary(order: widget.order),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: OnlineOrderUi.accent,
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: busy || (isPacked ? !canMarkReady : !canPack)
                  ? null
                  : isPacked
                      ? _ready
                      : _pack,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.inventory_2_outlined),
              label:
                  Text(isPacked ? 'Mark Ready for Collection' : 'Pack Order'),
            ),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FulfilmentStepper(status: widget.order.status),
            const SizedBox(height: 12),
            Expanded(
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 6, child: items),
                        const SizedBox(width: 12),
                        Expanded(
                            flex: 4, child: SingleChildScrollView(child: side)),
                      ],
                    )
                  : ListView(
                      children: [
                        SizedBox(height: 330, child: items),
                        const SizedBox(height: 12),
                        side,
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pack() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(posPickingActionsProvider(widget.order.orderId))
          .pack(notes.text);
    } catch (_) {
      if (mounted) setState(() => error = 'Unable to pack this order.');
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> _ready() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(posPickingActionsProvider(widget.order.orderId)).ready();
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Unable to mark this order as ready.');
      }
    }
    if (mounted) setState(() => busy = false);
  }
}

class PickedItemsReviewList extends StatelessWidget {
  const PickedItemsReviewList({required this.lines, super.key});
  final List<PosPickingLine> lines;

  @override
  Widget build(BuildContext context) => Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Review Picked Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: lines.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, index) {
                  final line = lines[index];
                  return ListTile(
                    leading:
                        const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(line.productName),
                    subtitle: Text([
                      line.variantName,
                      line.sku,
                    ].whereType<String>().join(' • ')),
                    trailing: Text(
                        '${line.pickedQuantity}/${line.requestedQuantity}'),
                  );
                },
              ),
            ),
          ],
        ),
      );
}

class PackingNotesCard extends StatelessWidget {
  const PackingNotesCard({required this.controller, super.key});
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: controller,
            maxLength: 200,
            maxLines: 3,
            decoration:
                const InputDecoration(labelText: 'Packing notes (optional)'),
          ),
        ),
      );
}

class PackingReadinessSummary extends StatelessWidget {
  const PackingReadinessSummary({required this.order, super.key});
  final PosPickingOrder order;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Packing Readiness',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              PickingProgressMetrics(order: order),
              const SizedBox(height: 12),
              Text(order.pickedLines == order.totalLines
                  ? 'All required items are picked and ready to pack.'
                  : 'Complete every required pick before packing.'),
            ],
          ),
        ),
      );
}
