import 'package:flutter/material.dart';

import '../../../../../shared/widgets/pos_action_buttons.dart';
import '../../../domain/entities/pos_online_order.dart';
import '../../utils/picking_formatters.dart';
import '../online_order_ui.dart';
import 'order_progress.dart';
import 'order_summary.dart';
import 'packing_notes.dart';

class ReviewPackSidebar extends StatelessWidget {
  const ReviewPackSidebar({
    required this.order,
    required this.notesController,
    required this.noteLength,
    required this.maxLength,
    required this.busy,
    required this.primaryEnabled,
    required this.showPackingNote,
    required this.compact,
    this.hideHelper = false,
    this.bounded = true,
    this.error,
    this.onPrimary,
    this.onBack,
    super.key,
  });

  final PosPickingOrder order;
  final TextEditingController notesController;
  final int noteLength;
  final int maxLength;
  final bool busy;
  final bool primaryEnabled;
  final bool showPackingNote;
  final bool compact;
  final bool hideHelper;
  final bool bounded;
  final String? error;
  final VoidCallback? onPrimary;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final issues = order.lines.where((line) => line.hasReportedIssue).length;
    final pending =
        (order.totalLines - order.pickedLines).clamp(0, order.totalLines);
    final urgency = pickingUrgency(order.collectionAt, order.serverTime);
    final gap = compact ? 6.0 : 8.0;

    final summary = OrderSummary(
      order: order,
      urgency: urgency,
      compact: true,
      ultraCompact: hideHelper,
    );
    final progress = OrderProgress(
      order: order,
      pending: pending,
      issues: issues,
      compact: true,
      ultraCompact: hideHelper,
    );

    return Column(
      mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showPackingNote) ...[
          PackingNotes(
            controller: notesController,
            noteLength: noteLength,
            maxLength: maxLength,
            compact: compact,
            ultraCompact: hideHelper,
            enabled: !busy,
          ),
          SizedBox(height: gap),
        ],
        if (bounded)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  flex: hideHelper ? 4 : 5,
                  child: summary,
                ),
                SizedBox(height: gap),
                Flexible(
                  flex: hideHelper ? 4 : 5,
                  child: progress,
                ),
              ],
            ),
          )
        else ...[
          SizedBox(height: 168, child: summary),
          SizedBox(height: gap),
          SizedBox(height: 148, child: progress),
        ],
        SizedBox(height: gap),
        if (!hideHelper)
          Text(
            'Ensure all items are packed securely and in perfect condition before marking the order ready.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: OnlineOrderUi.subtitle.copyWith(
              fontSize: compact ? 10.5 : 11.5,
              height: 1.2,
            ),
          ),
        if (!hideHelper) SizedBox(height: gap),
        if (error != null) ...[
          SizedBox(height: gap),
          Text(
            error!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        SizedBox(height: gap),
        if (onPrimary != null || busy)
          SizedBox(
            height: hideHelper ? 36 : (compact ? 40 : 44),
            child: PosPrimaryActionButton(
              key: const Key('mark-ready-for-collection'),
              label: 'Mark as Ready for Collection',
              fullWidth: true,
              compact: true,
              isLoading: busy,
              minimumHeight: hideHelper ? 36 : (compact ? 40 : 44),
              verticalPadding: 0,
              backgroundColor: Theme.of(context).colorScheme.primary,
              gradient: null,
              semanticLabel: primaryEnabled
                  ? 'Mark as Ready for Collection'
                  : 'Mark as Ready for Collection disabled',
              onPressed: onPrimary,
            ),
          )
        else
          const SizedBox.shrink(),
        SizedBox(height: gap),
        SizedBox(
          height: hideHelper ? 32 : (compact ? 36 : 40),
          child: OutlinedButton(
            key: const Key('back-to-pick-items'),
            onPressed: busy ? null : onBack,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: hideHelper ? 8 : 12),
              visualDensity:
                  hideHelper ? VisualDensity.compact : VisualDensity.standard,
            ),
            child: const Text('Back to Pick Items'),
          ),
        ),
      ],
    );
  }
}
