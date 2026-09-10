import 'package:flutter/material.dart';

import '../../../domain/entities/pos_online_order.dart';
import '../../utils/picking_formatters.dart';
import '../../utils/picking_visual_metrics.dart';
import '../online_order_ui.dart';

class PickingProgressMetrics extends StatelessWidget {
  const PickingProgressMetrics({
    required this.order,
    this.compact = false,
    super.key,
  });
  final PosPickingOrder order;
  final bool compact;

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
      constraints: BoxConstraints(
        minHeight: compact ? 50 : 68,
        maxHeight: compact ? 56 : 76,
      ),
      decoration: pickingCardDecoration(context),
      child: Row(children: [
        for (var index = 0; index < values.length; index++) ...[
          if (index > 0)
            VerticalDivider(
              width: 1,
              indent: compact ? 4 : 8,
              endIndent: compact ? 4 : 8,
            ),
          Expanded(
              child: _Metric(
                  label: values[index].$1,
                  value: values[index].$2,
                  icon: values[index].$3,
                  index: index,
                  compact: compact)),
        ],
      ]),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.index,
    this.compact = false,
  });
  final String label;
  final String value;
  final IconData icon;
  final int index;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 4 : 6,
          vertical: compact ? 3 : 6,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircleAvatar(
              radius: compact ? 12 : 15,
              backgroundColor: _metricColor(context).withValues(alpha: .09),
              child: Icon(
                icon,
                color: _metricColor(context),
                size: compact ? 13 : 16,
              )),
          SizedBox(width: compact ? 4 : 6),
          Flexible(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(value,
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: compact ? 13 : 15,
                        fontWeight: FontWeight.w800)),
                Text(label,
                    maxLines: 1,
                    softWrap: false,
                    style: OnlineOrderUi.subtitle
                        .copyWith(fontSize: compact ? 10 : 11)),
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
