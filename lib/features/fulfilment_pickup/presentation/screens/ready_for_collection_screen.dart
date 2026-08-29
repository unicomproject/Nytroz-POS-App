import 'package:flutter/material.dart';

import '../../domain/entities/pos_online_order.dart';
import '../widgets/online_order_ui.dart';
import '../widgets/picking_widgets.dart';

class ReadyForCollectionScreen extends StatelessWidget {
  const ReadyForCollectionScreen({
    required this.order,
    required this.onBack,
    super.key,
  });
  final PosPickingOrder order;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final hero = ReadyForCollectionHero(order: order, onBack: onBack);
          final summary = ReadyOrderSummary(order: order);
          if (constraints.maxWidth >= OnlineOrderUi.tabletLandscapeBreakpoint) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 6, child: hero),
                const SizedBox(width: 12),
                Expanded(flex: 4, child: summary),
              ],
            );
          }
          return ListView(
            children: [
              hero,
              const SizedBox(height: 12),
              summary,
            ],
          );
        },
      );
}

class ReadyForCollectionHero extends StatelessWidget {
  const ReadyForCollectionHero({
    required this.order,
    required this.onBack,
    super.key,
  });
  final PosPickingOrder order;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: Color(0xFFE8F8EE),
                child: Icon(Icons.check, color: Colors.green, size: 42),
              ),
              const SizedBox(height: 16),
              const Text('Ready for Collection',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Order ${order.orderNumber} is packed and ready for ${order.customerName}.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: OnlineOrderUi.accent),
                onPressed: onBack,
                icon: const Icon(Icons.list_alt),
                label: const Text('Back to Online Orders'),
              ),
            ],
          ),
        ),
      );
}

class ReadyOrderSummary extends StatelessWidget {
  const ReadyOrderSummary({required this.order, super.key});
  final PosPickingOrder order;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Order Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              _row('Order', order.orderNumber),
              _row('Customer', order.customerName),
              _row('Fulfilment', order.fulfillmentNumber),
              _row('Collection', OnlineOrderUi.collection(order.collectionAt)),
              const SizedBox(height: 16),
              PickingProgressMetrics(order: order),
            ],
          ),
        ),
      );

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(child: Text(label, style: OnlineOrderUi.subtitle)),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}
