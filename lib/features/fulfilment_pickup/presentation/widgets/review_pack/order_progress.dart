import 'package:flutter/material.dart';

import '../../../domain/entities/pos_online_order.dart';
import '../../utils/picking_visual_metrics.dart';

class OrderProgress extends StatelessWidget {
  const OrderProgress({
    required this.order,
    required this.pending,
    required this.issues,
    required this.compact,
    this.ultraCompact = false,
    super.key,
  });

  final PosPickingOrder order;
  final int pending;
  final int issues;
  final bool compact;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    final readyToPack = order.canPack || order.isPacked || order.allPicked;
    final successTone = Colors.green.shade700;
    return Container(
      padding: EdgeInsets.all(ultraCompact ? 4 : (compact ? 6 : 8)),
      decoration: pickingCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Order Progress',
            style: TextStyle(
              fontSize: ultraCompact ? 12 : (compact ? 13 : 14),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: ultraCompact ? 2 : 4),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final ring = (constraints.maxHeight - 4)
                  .clamp(32.0, ultraCompact ? 44.0 : (compact ? 58.0 : 72.0))
                  .toDouble();
              final showLegendLabels =
                  !ultraCompact && constraints.maxHeight >= 58;
              return Row(
                children: [
                  Semantics(
                    label:
                        'Order progress ${order.pickedLines} of ${order.totalLines} picked',
                    child: SizedBox.square(
                      dimension: ring,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.square(
                            dimension: ring,
                            child: CircularProgressIndicator(
                              value: order.totalLines == 0
                                  ? 0
                                  : order.pickedLines / order.totalLines,
                              strokeWidth: ultraCompact ? 4 : 5,
                              backgroundColor: Theme.of(context).dividerColor,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(
                            '${order.pickedLines}/${order.totalLines}',
                            style: TextStyle(
                              fontSize: ring < 44 ? 10 : 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: showLegendLabels
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _legend('Picked', order.pickedLines, successTone),
                              _legend(
                                'Pending',
                                pending,
                                Theme.of(context).colorScheme.primary,
                              ),
                              _legend(
                                'Issues',
                                issues,
                                Theme.of(context).colorScheme.error,
                              ),
                            ],
                          )
                        : Text(
                            'Picked ${order.pickedLines} · Pending $pending · Issues $issues',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: ultraCompact ? 10.5 : 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              );
            }),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: ultraCompact ? 3 : 5,
            ),
            decoration: BoxDecoration(
              color: readyToPack
                  ? successTone.withValues(alpha: .08)
                  : Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: .06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              readyToPack
                  ? (order.isPacked
                      ? 'Packed — ready for collection'
                      : 'All items picked — Ready to pack')
                  : 'Complete picking before packing',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ultraCompact ? 10.5 : 11.5,
                fontWeight: FontWeight.w700,
                color: readyToPack
                    ? successTone
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, int value, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Text('$value',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
