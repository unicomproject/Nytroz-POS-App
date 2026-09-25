import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/pos_online_order.dart';
import '../../utils/picking_visual_metrics.dart';
import '../online_order_ui.dart';

class OrderSummary extends StatelessWidget {
  const OrderSummary({
    required this.order,
    required this.urgency,
    required this.compact,
    this.ultraCompact = false,
    super.key,
  });

  final PosPickingOrder order;
  final ({String label, String shortLabel, bool isOverdue}) urgency;
  final bool compact;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    final remainingLabel = urgency.shortLabel == 'Not set'
        ? 'Not set'
        : urgency.isOverdue
            ? '${urgency.shortLabel} overdue'
            : '${urgency.shortLabel} remaining';
    final rows = <Widget>[
      _summaryRow(
        context,
        'Order',
        '#${order.orderNumber}',
        trailing: OnlineOrderStatusChip(
          label: order.status,
          status: order.status,
        ),
      ),
      _summaryRow(context, 'Customer', order.customerName),
      _summaryRow(
        context,
        'Outlet',
        order.outletName?.trim().isNotEmpty == true
            ? order.outletName!
            : 'Outlet unavailable',
      ),
      if (!ultraCompact)
        _summaryRow(
          context,
          'Collection',
          order.collectionAt == null
              ? 'Not scheduled'
              : DateFormat('dd MMM, hh:mm a')
                  .format(order.collectionAt!.toLocal()),
        ),
      if (!ultraCompact &&
          order.collectionAt != null &&
          order.serverTime != null)
        _summaryRow(
          context,
          urgency.isOverdue ? 'Overdue' : 'Remaining',
          remainingLabel,
          valueColor: urgency.isOverdue
              ? Theme.of(context).colorScheme.error
              : null,
        ),
    ];
    return Container(
      padding: EdgeInsets.all(ultraCompact ? 4 : (compact ? 6 : 8)),
      decoration: pickingCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontSize: ultraCompact ? 12 : (compact ? 13 : 14),
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: ultraCompact ? 2 : 4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: rows,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    BuildContext context,
    String label,
    String value, {
    Widget? trailing,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OnlineOrderUi.subtitle.copyWith(fontSize: 11),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: valueColor,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            trailing,
          ],
        ],
      ),
    );
  }
}
