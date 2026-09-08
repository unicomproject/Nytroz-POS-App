import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/pos_online_order.dart';
import '../../utils/picking_formatters.dart';
import '../online_order_ui.dart';
import 'picking_progress_metrics.dart';

class PickingHeader extends StatelessWidget {
  const PickingHeader({required this.order, required this.onBack, super.key});
  final PosPickingOrder order;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final urgency = pickingUrgency(order.collectionAt, order.serverTime);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        height: 32,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
              button: true,
              label: 'Back to Order Detail',
              child: TextButton.icon(
                onPressed: onBack,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.arrow_back, size: 17),
                label: const Text('Back to Order Detail',
                    style: TextStyle(fontSize: 13.5)),
              )),
        ),
      ),
      LayoutBuilder(builder: (context, constraints) {
        final identity =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Pick Order #${order.orderNumber}',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontSize: 23, fontWeight: FontWeight.w800)),
                OnlineOrderStatusChip(
                    label: order.status, status: order.status),
              ]),
          const SizedBox(height: 5),
          Wrap(spacing: 8, runSpacing: 3, children: [
            Text('Customer: ${order.customerName}',
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text('•  Collection: ${_collection(order.collectionAt)}',
                style: TextStyle(
                    color: urgency.isOverdue ? Colors.red : primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
            Text(urgency.label,
                style: TextStyle(
                    color: urgency.isOverdue ? Colors.red : primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700)),
          ]),
        ]);
        if (constraints.maxWidth >= 900) {
          return Row(children: [
            Expanded(flex: 52, child: identity),
            const SizedBox(width: 12),
            Expanded(flex: 48, child: PickingProgressMetrics(order: order))
          ]);
        }
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              identity,
              const SizedBox(height: 10),
              PickingProgressMetrics(order: order)
            ]);
      }),
    ]);
  }

  static String _collection(DateTime? value) => value == null
      ? 'Not scheduled'
      : DateFormat('dd MMM, hh:mm a').format(value.toLocal());
}
