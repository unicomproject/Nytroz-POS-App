import 'package:flutter/material.dart';

import '../../../domain/entities/pos_online_order.dart';
import '../../utils/picking_visual_metrics.dart';
import '../picking/picking_item_card.dart';

class PickedItemsList extends StatelessWidget {
  const PickedItemsList({
    required this.order,
    required this.compact,
    super.key,
  });

  final PosPickingOrder order;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final success = Colors.green.shade700;
    return Container(
      decoration: pickingCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, compact ? 8 : 10, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Picked Items (${order.pickedLines} of ${order.totalLines})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 15 : 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (order.allPicked || order.canPack || order.isPacked)
                  Text(
                    '✓ All items picked',
                    style: TextStyle(
                      color: success,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: order.lines.isEmpty
                ? const Center(child: Text('No picked items to review.'))
                : ListView.separated(
                    padding: EdgeInsets.all(compact ? 8 : 10),
                    itemCount: order.lines.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: compact ? 6 : 8),
                    itemBuilder: (_, index) => SizedBox(
                      height: compact ? 78 : 88,
                      child: PickingItemCard(
                        line: order.lines[index],
                        reviewMode: true,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
