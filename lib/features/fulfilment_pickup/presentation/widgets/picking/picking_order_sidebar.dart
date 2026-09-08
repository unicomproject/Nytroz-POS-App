import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/access/pos_access_codes.dart';
import '../../../../../shared/widgets/pos_action_buttons.dart';
import '../../../../auth/presentation/providers/session_provider.dart';
import '../../../domain/entities/pos_online_order.dart';
import '../../providers/pos_online_orders_provider.dart';
import '../../utils/picking_visual_metrics.dart';
import '../online_order_ui.dart';
import 'picking_note_dialog.dart';

class PickingOrderSidebar extends ConsumerWidget {
  const PickingOrderSidebar(
      {required this.order, this.orderId, this.onReviewPack, super.key});
  final PosPickingOrder order;
  final String? orderId;
  final VoidCallback? onReviewPack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final canNote =
        session?.hasPermission(PosPermissionCodes.addOnlineOrderPickingNote) ==
            true;
    final issues = order.lines.where((line) => line.hasReportedIssue).length;
    final pending =
        (order.totalLines - order.pickedLines).clamp(0, order.totalLines);
    return LayoutBuilder(builder: (context, constraints) {
      final bounded = constraints.hasBoundedHeight &&
          constraints.maxHeight.isFinite &&
          constraints.maxHeight > 0;
      final metrics = PickingVisualMetrics.forHeight(
          bounded ? constraints.maxHeight : 600);
      final compact = metrics.compact;
      final gap = metrics.gap;
      final ringSize = metrics.progressRing;
      final showNote = canNote && orderId != null;

      Widget progressCard() => Container(
            padding: EdgeInsets.all(compact ? 10 : 12),
            decoration: pickingCardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Order Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 15 : 16,
                      ),
                ),
                SizedBox(height: compact ? 6 : 8),
                Expanded(
                  child: Row(children: [
                    SizedBox.square(
                      dimension: ringSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.square(
                            dimension: ringSize,
                            child: CircularProgressIndicator(
                              value: order.totalLines == 0
                                  ? 0
                                  : order.pickedLines / order.totalLines,
                              strokeWidth: compact ? 7 : 9,
                              backgroundColor: Theme.of(context).dividerColor,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${order.pickedLines} / ${order.totalLines}',
                                style: TextStyle(
                                  fontSize: compact ? 16 : 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                'Picked',
                                style: TextStyle(fontSize: compact ? 10 : 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: compact ? 10 : 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _legend('Picked', order.pickedLines,
                              Colors.green.shade700,
                              compact: compact),
                          _legend(
                              'Pending',
                              pending,
                              Theme.of(context).colorScheme.primary,
                              compact: compact),
                          _legend('Issues', issues,
                              Theme.of(context).colorScheme.error,
                              compact: compact),
                        ],
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          );

      Widget tipsCard() => Container(
            padding: EdgeInsets.all(compact ? 9 : 11),
            decoration: pickingCardDecoration(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: compact ? 18 : 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Picking Tips',
                    style: TextStyle(
                      fontSize: compact ? 14 : 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ]),
                SizedBox(height: compact ? 4 : 6),
                Expanded(
                  child: Text(
                    '• Follow the product location for faster picking\n'
                    '• Scan the product barcode to confirm\n'
                    '• Complete all required items to continue',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      height: compact ? 1.28 : 1.35,
                    ),
                  ),
                ),
              ],
            ),
          );

      final noteButton = showNote
          ? SizedBox(
              height: metrics.noteHeight,
              child: Semantics(
                button: true,
                label: 'Add Picking Note',
                child: OutlinedButton.icon(
                  key: const Key('add-picking-note'),
                  onPressed: () => PickingNoteDialog.show(
                    context,
                    onSave: (note) => ref
                        .read(posPickingActionsProvider(orderId!))
                        .addNote(order, note),
                    existingNotes: order.notes,
                  ),
                  icon: Icon(Icons.note_add_outlined, size: compact ? 18 : 19),
                  label: Row(children: [
                    const Expanded(child: Text('Add Picking Note')),
                    Icon(Icons.chevron_right, size: compact ? 18 : 19),
                  ]),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
            )
          : null;

      final cta = SizedBox(
        height: metrics.ctaHeight,
        child: PosPrimaryActionButton(
          key: const Key('review-pack-button'),
          label: 'Review & Pack',
          trailingIcon: Icons.arrow_forward,
          fullWidth: true,
          compact: true,
          minimumHeight: metrics.ctaHeight,
          verticalPadding: 0,
          semanticLabel: order.canPack
              ? 'Review and Pack enabled'
              : 'Review and Pack disabled. Pick all items to continue',
          backgroundColor: Theme.of(context).colorScheme.primary,
          gradient: null,
          onPressed: order.canPack ? onReviewPack : null,
        ),
      );

      final helper = Text(
        order.canPack
            ? 'All required items are ready for review'
            : 'Pick all items to continue',
        textAlign: TextAlign.center,
        maxLines: 1,
        style: OnlineOrderUi.subtitle.copyWith(fontSize: compact ? 10.5 : 11.5),
      );

      if (!bounded) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: metrics.progressHeight, child: progressCard()),
            SizedBox(height: gap),
            SizedBox(height: metrics.tipsHeight, child: tipsCard()),
            if (noteButton != null) ...[
              SizedBox(height: gap),
              noteButton,
            ],
            SizedBox(height: gap),
            cta,
            const SizedBox(height: 2),
            helper,
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 55, child: progressCard()),
          SizedBox(height: gap),
          Expanded(flex: 32, child: tipsCard()),
          if (noteButton != null) ...[
            SizedBox(height: gap),
            noteButton,
          ],
          SizedBox(height: gap),
          cta,
          const SizedBox(height: 2),
          helper,
        ],
      );
    });
  }

  Widget _legend(String label, int value, Color color,
          {required bool compact}) =>
      Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 2 : 3),
        child: Row(children: [
          Container(
            width: compact ? 7 : 8,
            height: compact ? 7 : 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: compact ? 11 : 12.5),
            ),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontSize: compact ? 11 : 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ]),
      );
}
