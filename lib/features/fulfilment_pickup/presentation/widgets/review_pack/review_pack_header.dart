import 'package:flutter/material.dart';

import '../../../domain/entities/pos_online_order.dart';
import '../online_order_ui.dart';
import '../picking/picking_progress_metrics.dart';

class ReviewPackHeader extends StatelessWidget {
  const ReviewPackHeader({
    required this.order,
    required this.compact,
    this.onBack,
    super.key,
  });

  final PosPickingOrder order;
  final bool compact;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 28,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Semantics(
              button: true,
              label: 'Back to Pick Order',
              child: TextButton.icon(
                onPressed: onBack,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.arrow_back, size: 17),
                label: const Text('Back to Pick Order',
                    style: TextStyle(fontSize: 13.5)),
              ),
            ),
          ),
        ),
        LayoutBuilder(builder: (context, constraints) {
          final title = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Review & Pack',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: compact ? 20 : 23,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '2 of 3',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 2 : 4),
              Text(
                'Verify picked items and add any notes before marking as ready.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OnlineOrderUi.subtitle.copyWith(fontSize: 13),
              ),
            ],
          );
          final metrics =
              PickingProgressMetrics(order: order, compact: compact);
          if (constraints.maxWidth >= 900) {
            return Row(children: [
              Expanded(flex: 52, child: title),
              const SizedBox(width: 12),
              Expanded(flex: 48, child: metrics),
            ]);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              title,
              SizedBox(height: compact ? 6 : 8),
              metrics,
            ],
          );
        }),
      ],
    );
  }
}
