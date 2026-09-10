import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../../shared/widgets/pos_action_buttons.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../domain/entities/pos_online_order.dart';
import '../providers/pos_online_orders_provider.dart';
import '../utils/picking_formatters.dart';
import '../utils/picking_visual_metrics.dart';
import '../widgets/online_order_ui.dart';
import '../widgets/picking/picking_item_card.dart';
import '../widgets/picking/picking_progress_metrics.dart';

class ReviewPackScreen extends ConsumerStatefulWidget {
  const ReviewPackScreen({
    required this.order,
    this.onBackToPickItems,
    super.key,
  });

  final PosPickingOrder order;
  final VoidCallback? onBackToPickItems;

  @override
  ConsumerState<ReviewPackScreen> createState() => _ReviewPackScreenState();
}

class _ReviewPackScreenState extends ConsumerState<ReviewPackScreen> {
  static const packingNoteMaxLength = 200;

  late final TextEditingController _notes;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _notes = TextEditingController();
    _notes.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(posPickingOrderProvider(widget.order.orderId)).maybeWhen(
          data: (value) => value,
          orElse: () => widget.order,
        );
    final granted =
        ref.watch(authSessionProvider)?.permissionCodes.toSet() ?? const {};
    final canViewPacking = PosPermissionAccess.canViewOnlineOrderPacking(granted);
    final canPack = PosPermissionAccess.canPackOnlineOrder(granted);
    final canMarkReady = PosPermissionAccess.canMarkOnlineOrderReady(granted);

    if (!canViewPacking) {
      return const OnlineOrderScreenState(
        message: 'Packing workspace permission is required.',
        icon: Icons.lock_outline,
      );
    }

    if (order.isTerminal) {
      return Column(
        children: [
          if (widget.onBackToPickItems != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: widget.onBackToPickItems,
                icon: const Icon(Icons.arrow_back, size: 17),
                label: const Text('Back'),
              ),
            ),
          const Expanded(
            child: OnlineOrderScreenState(
              message: 'This order is no longer available for packing.',
              icon: Icons.block_outlined,
            ),
          ),
        ],
      );
    }

    final primaryEnabled = !_busy &&
        !order.isTerminal &&
        ((order.isPacked && canMarkReady) ||
            (!order.isPacked &&
                order.canPack &&
                canPack &&
                canMarkReady));

    return LayoutBuilder(builder: (context, constraints) {
      final wide =
          constraints.maxWidth >= OnlineOrderUi.tabletLandscapeBreakpoint;
      final compact = constraints.maxHeight < 720;
      final ultraCompact = constraints.maxHeight < 600;
      final header = _ReviewPackHeader(
        order: order,
        onBack: widget.onBackToPickItems,
        compact: compact || ultraCompact,
      );
      final items = _PickedItemsPanel(
        order: order,
        compact: compact || ultraCompact,
      );
      final side = _ReviewPackSidebar(
        order: order,
        notesController: _notes,
        noteLength: _notes.text.characters.length,
        maxLength: packingNoteMaxLength,
        busy: _busy,
        error: _error,
        primaryEnabled: primaryEnabled,
        showPackingNote: !order.isPacked && canPack,
        onPrimary: primaryEnabled ? () => _submit(order) : null,
        onBack: widget.onBackToPickItems,
        compact: compact || ultraCompact,
        hideHelper: ultraCompact,
        bounded: wide,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          SizedBox(height: compact ? 6 : 8),
          Expanded(
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 62, child: items),
                      const SizedBox(width: 12),
                      Expanded(flex: 38, child: side),
                    ],
                  )
                : ListView(
                    children: [
                      SizedBox(height: 280, child: items),
                      const SizedBox(height: 12),
                      side,
                    ],
                  ),
          ),
        ],
      );
    });
  }

  Future<void> _submit(PosPickingOrder order) async {
    if (_busy) return;
    final note = _notes.text;
    if (note.characters.length > packingNoteMaxLength) {
      setState(() => _error = 'Packing note must be $packingNoteMaxLength characters or fewer.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(posPickingActionsProvider(order.orderId))
          .markReadyForCollection(packingNote: note);
    } on DioException catch (error) {
      if (!mounted) return;
      setState(() => _error = _mapError(error));
    } catch (_) {
      if (!mounted) return;
      setState(() =>
          _error = 'Unable to mark this order ready for collection.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _mapError(DioException error) {
    final code = error.response?.data is Map
        ? (error.response!.data as Map)['errorCode']?.toString()
        : null;
    return switch (code) {
      'online_orders.concurrency_conflict' =>
        'This order changed. Refresh and try again.',
      'online_orders.not_packable' =>
        'This order is not eligible to pack yet.',
      'online_orders.not_readyable' =>
        'This order must be packed before it can be marked ready.',
      'online_orders.permission_denied' =>
        'You do not have permission for this action.',
      'online_orders.invalid_packing_note' =>
        'Packing note is invalid.',
      _ => error.response?.statusCode == 409
          ? 'This order changed. Refresh and try again.'
          : 'Unable to mark this order ready for collection.',
    };
  }
}

class _ReviewPackHeader extends StatelessWidget {
  const _ReviewPackHeader({
    required this.order,
    required this.compact,
    this.onBack,
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

class _PickedItemsPanel extends StatelessWidget {
  const _PickedItemsPanel({required this.order, required this.compact});

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

class _ReviewPackSidebar extends StatelessWidget {
  const _ReviewPackSidebar({
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

    final summary = _OrderSummaryCard(
      order: order,
      urgency: urgency,
      compact: true,
      ultraCompact: hideHelper,
    );
    final progress = _OrderProgressCard(
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
          _PackingNotesSection(
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

class _PackingNotesSection extends StatelessWidget {
  const _PackingNotesSection({
    required this.controller,
    required this.noteLength,
    required this.maxLength,
    required this.compact,
    required this.enabled,
    this.ultraCompact = false,
  });

  final TextEditingController controller;
  final int noteLength;
  final int maxLength;
  final bool compact;
  final bool enabled;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ultraCompact ? 6 : (compact ? 8 : 10)),
      decoration: pickingCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Packing Notes',
                  style: TextStyle(
                    fontSize: ultraCompact ? 12.5 : 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                'Optional',
                style: OnlineOrderUi.subtitle.copyWith(fontSize: 11),
              ),
            ],
          ),
          SizedBox(height: ultraCompact ? 2 : (compact ? 4 : 6)),
          Semantics(
            textField: true,
            label: 'Packing Notes',
            child: TextField(
              key: const Key('packing-notes-field'),
              controller: controller,
              enabled: enabled,
              maxLength: maxLength,
              maxLines: ultraCompact ? 1 : 2,
              minLines: 1,
              decoration: InputDecoration(
                hintText: 'Add packing instructions…',
                counterText: '$noteLength / $maxLength',
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: ultraCompact ? 6 : 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.order,
    required this.urgency,
    required this.compact,
    this.ultraCompact = false,
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

class _OrderProgressCard extends StatelessWidget {
  const _OrderProgressCard({
    required this.order,
    required this.pending,
    required this.issues,
    required this.compact,
    this.ultraCompact = false,
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
