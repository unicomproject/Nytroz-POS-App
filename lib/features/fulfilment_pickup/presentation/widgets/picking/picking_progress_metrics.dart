import 'package:flutter/material.dart';

import '../../../domain/entities/pos_online_order.dart';
import '../../utils/picking_formatters.dart';
import '../../utils/picking_visual_metrics.dart';
import '../online_order_ui.dart';

class PickingProgressMetrics extends StatelessWidget {
  const PickingProgressMetrics({required this.order, super.key});
  final PosPickingOrder order;

  @override
  Widget build(BuildContext context) {
    final urgency = pickingUrgency(order.collectionAt, order.serverTime);
    final values = [
      ('Items', '${order.totalLines}', Icons.inventory_2_outlined),
      (
        'Picked',
        '${order.pickedLines} / ${order.totalLines}',
        Icons.check_circle_outline
      ),
      ('Remaining', urgency.shortLabel, Icons.schedule_outlined),
      ('Units', pickingQuantity(order.totalUnits), Icons.shopping_bag_outlined),
    ];
    return Container(
      constraints: const BoxConstraints(minHeight: 68, maxHeight: 76),
      decoration: pickingCardDecoration(context),
      child: Row(children: [
        for (var index = 0; index < values.length; index++) ...[
          if (index > 0)
            const VerticalDivider(width: 1, indent: 8, endIndent: 8),
          Expanded(
              child: _Metric(
                  label: values[index].$1,
                  value: values[index].$2,
                  icon: values[index].$3,
                  index: index)),
        ],
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(
      {required this.label,
      required this.value,
      required this.icon,
      required this.index});
  final String label;
  final String value;
  final IconData icon;
  final int index;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircleAvatar(
              radius: 15,
              backgroundColor: _metricColor(context).withValues(alpha: .09),
              child: Icon(icon, color: _metricColor(context), size: 16)),
          const SizedBox(width: 6),
          Flexible(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(value,
                    maxLines: 1,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),
                Text(label,
                    maxLines: 1,
                    softWrap: false,
                    style: OnlineOrderUi.subtitle.copyWith(fontSize: 11)),
              ])),
        ]),
      );

  Color _metricColor(BuildContext context) => switch (index) {
        0 => Theme.of(context).colorScheme.primary,
        1 => Colors.green.shade700,
        2 => Theme.of(context).colorScheme.tertiary,
        _ => Theme.of(context).colorScheme.secondary,
      };
}
