import 'package:flutter/material.dart';

import '../../domain/entities/pos_online_order.dart';
import 'online_order_ui.dart';

class StartFulfilmentDialog extends StatelessWidget {
  const StartFulfilmentDialog({required this.detail, super.key});

  final PosOnlineOrderDetail detail;

  static Future<bool> show(
    BuildContext context,
    PosOnlineOrderDetail detail,
  ) async {
    final compact =
        MediaQuery.sizeOf(context).width < OnlineOrderUi.phoneBreakpoint;
    if (compact) {
      return await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: StartFulfilmentDialog(detail: detail),
              ),
            ),
          ) ??
          false;
    }
    return await showDialog<bool>(
          context: context,
          builder: (_) => Dialog(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: StartFulfilmentDialog(detail: detail),
              ),
            ),
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final units =
        detail.lines.fold<double>(0, (sum, line) => sum + line.quantity);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Start Fulfilment?', style: OnlineOrderUi.title),
        const SizedBox(height: 6),
        const Text('This order will be assigned to the current cashier.'),
        const SizedBox(height: 18),
        _row('Order', detail.order.orderNumber),
        _row('Customer', detail.order.customerName),
        _row('Outlet', detail.outletName),
        _row('Collect by', OnlineOrderUi.collection(detail.order.collectionAt)),
        _row('Items', '${detail.lines.length} lines • $units units'),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: OnlineOrderUi.accent),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Start Fulfilment'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 88,
              child: Text(label, style: OnlineOrderUi.subtitle),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}
