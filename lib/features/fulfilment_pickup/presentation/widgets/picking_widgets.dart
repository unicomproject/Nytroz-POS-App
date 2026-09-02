import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';

import '../../../../core/access/pos_access_codes.dart';
import '../../../../shared/presentation/app_modal.dart';
import '../../../../shared/widgets/app_cached_network_image.dart';
import '../../../../shared/widgets/pos_action_buttons.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../domain/entities/pos_online_order.dart';
import '../providers/pos_online_orders_provider.dart';
import 'online_order_ui.dart';

class _PickingVisualMetrics {
  const _PickingVisualMetrics._({required this.compact});

  factory _PickingVisualMetrics.forHeight(double height) =>
      _PickingVisualMetrics._(compact: height < 500);

  final bool compact;
  double get gap => compact ? 8 : 10;
  double get lineHeight => compact ? 112 : 126;
  double get progressHeight => compact ? 150 : 174;
  double get progressRing => compact ? 96 : 116;
  double get tipsHeight => compact ? 106 : 128;
  double get noteHeight => compact ? 46 : 52;
  double get ctaHeight => compact ? 48 : 52;
}

class FulfilmentStepper extends StatelessWidget {
  const FulfilmentStepper({required this.status, super.key});
  final String status;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const labels = ['Pick Items', 'Review & Pack', 'Ready for Collection'];
    return Semantics(
      label: 'Fulfilment progress. Step 1 of 3, Pick Items',
      child: Row(
        children: List.generate(
            labels.length,
            (index) => Expanded(
                  child: Row(children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor:
                          index == 0 ? primary : Colors.blueGrey.shade100,
                      foregroundColor:
                          index == 0 ? Colors.white : OnlineOrderUi.muted,
                      child: Text('${index + 1}',
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                        child: Text(labels[index],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: index == 0
                                    ? primary
                                    : OnlineOrderUi.muted))),
                    if (index < 2)
                      const Expanded(child: Divider(indent: 10, endIndent: 10)),
                  ]),
                )),
      ),
    );
  }
}

class PickingHeader extends StatelessWidget {
  const PickingHeader({required this.order, required this.onBack, super.key});
  final PosPickingOrder order;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final urgency = _urgency(order.collectionAt, order.serverTime);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(
        height: 36,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Semantics(
              button: true,
              label: 'Back to Order Detail',
              child: TextButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back to Order Detail'),
              )),
        ),
      ),
      LayoutBuilder(builder: (context, constraints) {
        final identity =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Pick Order #${order.orderNumber}',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontSize: 25, fontWeight: FontWeight.w800)),
                OnlineOrderStatusChip(
                    label: order.status, status: order.status),
              ]),
          const SizedBox(height: 7),
          Wrap(spacing: 10, runSpacing: 4, children: [
            Text('Customer: ${order.customerName}',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            Text('•  Collection: ${_collection(order.collectionAt)}',
                style: TextStyle(
                    color: urgency.isOverdue ? Colors.red : primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            Text(urgency.label,
                style: TextStyle(
                    color: urgency.isOverdue ? Colors.red : primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ]),
        ]);
        if (constraints.maxWidth >= 900) {
          return Row(children: [
            Expanded(flex: 52, child: identity),
            const SizedBox(width: 16),
            Expanded(flex: 48, child: PickingProgressMetrics(order: order))
          ]);
        }
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              identity,
              const SizedBox(height: 14),
              PickingProgressMetrics(order: order)
            ]);
      }),
    ]);
  }
}

class PickingProgressMetrics extends StatelessWidget {
  const PickingProgressMetrics({required this.order, super.key});
  final PosPickingOrder order;
  @override
  Widget build(BuildContext context) {
    final urgency = _urgency(order.collectionAt, order.serverTime);
    final values = [
      ('Items', '${order.totalLines}', Icons.inventory_2_outlined),
      (
        'Picked',
        '${order.pickedLines} / ${order.totalLines}',
        Icons.check_circle_outline
      ),
      ('Remaining', urgency.shortLabel, Icons.schedule_outlined),
      ('Units', _quantity(order.totalUnits), Icons.shopping_bag_outlined),
    ];
    return Container(
      constraints: const BoxConstraints(minHeight: 82, maxHeight: 92),
      decoration: _cardDecoration(context),
      child: Row(children: [
        for (var index = 0; index < values.length; index++) ...[
          if (index > 0)
            const VerticalDivider(width: 1, indent: 12, endIndent: 12),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          CircleAvatar(
              radius: 19,
              backgroundColor: _metricColor(context).withValues(alpha: .09),
              child: Icon(icon, color: _metricColor(context), size: 20)),
          const SizedBox(width: 8),
          Flexible(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(value,
                    maxLines: 1,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800)),
                Text(label,
                    maxLines: 1,
                    softWrap: false,
                    style: OnlineOrderUi.subtitle.copyWith(fontSize: 12)),
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

class PickingItemsList extends ConsumerWidget {
  const PickingItemsList(
      {required this.orderId, required this.order, super.key});
  final String orderId;
  final PosPickingOrder order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);
    final canPick =
        session?.hasPermission(PosPermissionCodes.pickOnlineOrderItem) == true;
    final canScan = canPick &&
        session?.hasPermission(PosPermissionCodes.scanOnlineOrderItem) == true;
    final canManual = canPick &&
        session?.hasPermission(
                PosPermissionCodes.manuallyEnterOnlineOrderItem) ==
            true;
    final canReport = session
            ?.hasPermission(PosPermissionCodes.reportOnlineOrderPickingIssue) ==
        true;
    PosPickingLine? active;
    for (final line in order.lines) {
      if (!line.isPicked) {
        active = line;
        break;
      }
    }
    return Container(
      decoration: _cardDecoration(context),
      padding: const EdgeInsets.all(8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const FulfilmentStepper(status: 'PICKING'),
        const SizedBox(height: 8),
        Expanded(
            child: order.lines.isEmpty
                ? const OnlineOrderScreenState(
                    message: 'No picking items are available.')
                : order.lines.length <= 3
                    ? LayoutBuilder(builder: (context, constraints) {
                        final metrics = _PickingVisualMetrics.forHeight(
                            constraints.maxHeight);
                        final availablePerLine = (constraints.maxHeight -
                                (order.lines.length - 1) * metrics.gap) /
                            3;
                        final cardHeight = availablePerLine
                            .clamp(90.0, metrics.lineHeight)
                            .toDouble();
                        return Column(
                          children: [
                            for (var index = 0;
                                index < order.lines.length;
                                index++) ...[
                              SizedBox(
                                height: cardHeight,
                                child: PickingItemCard(
                                  line: order.lines[index],
                                  selected:
                                      order.lines[index].status.toUpperCase() ==
                                          'PICKING',
                                  onPick: canScan || canManual
                                      ? () => _showPick(
                                          context, ref, order.lines[index])
                                      : null,
                                  onIssue:
                                      canReport && !order.lines[index].isPicked
                                          ? () => _showIssue(
                                              context, ref, order.lines[index])
                                          : null,
                                ),
                              ),
                              if (index < order.lines.length - 1)
                                SizedBox(height: metrics.gap),
                            ],
                          ],
                        );
                      })
                    : ListView.separated(
                        key: const Key('picking-lines-list'),
                        itemCount: order.lines.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) => PickingItemCard(
                          line: order.lines[index],
                          selected: order.lines[index].status.toUpperCase() ==
                              'PICKING',
                          onPick: canScan || canManual
                              ? () =>
                                  _showPick(context, ref, order.lines[index])
                              : null,
                          onIssue: canReport && !order.lines[index].isPicked
                              ? () =>
                                  _showIssue(context, ref, order.lines[index])
                              : null,
                        ),
                      )),
        if (canScan && active != null) ...[
          const SizedBox(height: 8),
          Semantics(
              button: true,
              label: 'Scan Item Barcode',
              child: OutlinedButton.icon(
                key: const Key('scan-item-barcode'),
                onPressed: () =>
                    _showPick(context, ref, active!, preferScan: true),
                icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.qr_code_scanner, size: 22)),
                label: const Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Scan Item Barcode',
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w800)),
                          Text('Scan to pick item quickly',
                              style: TextStyle(fontSize: 12)),
                        ])),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    padding: const EdgeInsets.symmetric(horizontal: 14)),
              )),
        ],
      ]),
    );
  }

  Future<void> _showPick(
      BuildContext context, WidgetRef ref, PosPickingLine line,
      {bool preferScan = false}) async {
    final result = await showAppDialog<PickItemResult>(
        context: context,
        builder: (_) =>
            PickItemScannerPanel(line: line, preferScan: preferScan));
    if (result == null || !context.mounted) return;
    try {
      await ref
          .read(posPickingActionsProvider(orderId))
          .pick(order, line, scanned: result.scanned, barcode: result.barcode);
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }

  Future<void> _showIssue(
      BuildContext context, WidgetRef ref, PosPickingLine line) async {
    final note = await ReportPickingIssueDialog.show(context, line);
    if (note == null || !context.mounted) return;
    try {
      await ref
          .read(posPickingActionsProvider(orderId))
          .issue(order, line, 'ITEM_NOT_FOUND', note);
    } catch (error) {
      if (context.mounted) _showError(context, error);
    }
  }
}

class PickingItemCard extends StatelessWidget {
  const PickingItemCard(
      {required this.line,
      this.selected = false,
      this.onPick,
      this.onIssue,
      super.key});
  final PosPickingLine line;
  final bool selected;
  final VoidCallback? onPick;
  final VoidCallback? onIssue;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: onPick != null,
      label:
          'Pick line ${line.lineNumber}, ${line.productName}, ${_quantity(line.pickedQuantity)} of ${_quantity(line.requestedQuantity)} picked',
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(
                    primary.withValues(alpha: .035),
                    Theme.of(context).colorScheme.surfaceContainerLowest,
                  )
                : Theme.of(context).colorScheme.surfaceContainerLowest,
            border: Border.all(
                color: selected ? primary : Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: LayoutBuilder(builder: (context, constraints) {
            final imageSize = constraints.hasBoundedHeight
                ? (constraints.maxHeight - 22).clamp(68.0, 88.0).toDouble()
                : 88.0;
            final product = Row(children: [
              Semantics(
                  image: true,
                  label: line.altText ?? line.productName,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: imageSize,
                        height: imageSize,
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: AppCachedNetworkImage(
                            imageUrl: line.imageUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: (imageSize * 2).round(),
                            memCacheHeight: (imageSize * 2).round(),
                            errorWidget: const Icon(Icons.inventory_2_outlined,
                                size: 34)),
                      ))),
              const SizedBox(width: 13),
              Expanded(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('${line.lineNumber}. ${line.productName}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    if (line.variantName != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(line.variantName!,
                              style: TextStyle(
                                  fontSize: 13, color: OnlineOrderUi.muted))),
                    if (line.sku != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('SKU: ${line.sku}',
                              style: TextStyle(
                                  fontSize: 13, color: OnlineOrderUi.muted))),
                  ])),
            ]);
            final detail = Row(children: [
              Expanded(child: _LocationBlock(line: line)),
              const SizedBox(width: 8),
              SizedBox(
                  width: 84,
                  child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pick',
                                style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(
                                '${_quantity(line.pickedQuantity)} / ${_quantity(line.requestedQuantity)}',
                                style: TextStyle(
                                    color: primary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800)),
                            const Text('picked',
                                style: TextStyle(fontSize: 13)),
                          ]))),
              if (onIssue != null && line.hasReportedIssue)
                IconButton(
                    tooltip: 'View reported issue',
                    onPressed: onIssue,
                    icon: Icon(Icons.report_problem_outlined,
                        color: Theme.of(context).colorScheme.error)),
              Icon(Icons.chevron_right,
                  color: onPick == null ? OnlineOrderUi.muted : null),
            ]);
            if (constraints.maxWidth < 620) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [product, const SizedBox(height: 12), detail]);
            }
            return Row(children: [
              Expanded(flex: 5, child: product),
              const SizedBox(width: 12),
              Expanded(flex: 4, child: detail)
            ]);
          }),
        ),
      ),
    );
  }
}

class _LocationBlock extends StatelessWidget {
  const _LocationBlock({required this.line});
  final PosPickingLine line;
  @override
  Widget build(BuildContext context) => Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Location',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            Text(line.locationName ?? 'Location unavailable',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13)),
            if (line.locationCode != null)
              Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: .07),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(line.locationCode!,
                        style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700)),
                  )),
          ]);
}

class PickItemResult {
  const PickItemResult({required this.scanned, required this.barcode});
  final bool scanned;
  final String barcode;
}

class PickQuantityPanel extends StatelessWidget {
  const PickQuantityPanel({
    required this.requested,
    required this.picked,
    super.key,
  });
  final double requested;
  final double picked;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 16,
        runSpacing: 6,
        children: [
          Text('Requested: ${_quantity(requested)}'),
          Text('Already picked: ${_quantity(picked)}'),
          Text(
              'This pick: ${_quantity((requested - picked).clamp(0, requested))}'),
        ],
      );
}

class PickItemScannerPanel extends ConsumerStatefulWidget {
  const PickItemScannerPanel(
      {required this.line, this.preferScan = false, super.key});
  final PosPickingLine line;
  final bool preferScan;
  @override
  ConsumerState<PickItemScannerPanel> createState() =>
      _PickItemScannerPanelState();
}

class _PickItemScannerPanelState extends ConsumerState<PickItemScannerPanel> {
  final barcode = TextEditingController();
  @override
  void dispose() {
    barcode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider);
    final canScan =
        session?.hasPermission(PosPermissionCodes.scanOnlineOrderItem) == true;
    final canManual = session
            ?.hasPermission(PosPermissionCodes.manuallyEnterOnlineOrderItem) ==
        true;
    return AlertDialog(
      title: Text(widget.preferScan ? 'Scan Item Barcode' : 'Pick Item'),
      content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.line.productName,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextField(
                    controller: barcode,
                    autofocus: true,
                    decoration: const InputDecoration(
                        labelText: 'Barcode',
                        helperText:
                            'The server verifies the product barcode.')),
                const SizedBox(height: 12),
                Text(
                    'This pick: ${_quantity(widget.line.remainingQuantity)} unit(s)'),
              ])),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        if (canManual)
          OutlinedButton(
              onPressed: () => Navigator.pop(context,
                  PickItemResult(scanned: false, barcode: barcode.text)),
              child: const Text('Manual pick')),
        if (canScan)
          FilledButton.icon(
              onPressed: () => Navigator.pop(context,
                  PickItemResult(scanned: true, barcode: barcode.text)),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan & pick')),
      ],
    );
  }
}

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
      final bounded = constraints.hasBoundedHeight;
      final metrics = _PickingVisualMetrics.forHeight(constraints.maxHeight);
      final compact = metrics.compact;
      final gap = metrics.gap;
      final ringSize = metrics.progressRing;
      final progressHeight = metrics.progressHeight;
      final tipsHeight = metrics.tipsHeight;
      return Column(
          mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: progressHeight,
              child: Container(
                  padding: EdgeInsets.all(compact ? 12 : 16),
                  decoration: _cardDecoration(context),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Order Progress',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: compact ? 16 : 18)),
                        SizedBox(height: compact ? 7 : 10),
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
                                                : order.pickedLines /
                                                    order.totalLines,
                                            strokeWidth: compact ? 8 : 10,
                                            backgroundColor:
                                                Theme.of(context).dividerColor,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary),
                                      ),
                                      Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                                '${order.pickedLines} / ${order.totalLines}',
                                                style: TextStyle(
                                                    fontSize: compact ? 18 : 21,
                                                    fontWeight:
                                                        FontWeight.w800)),
                                            Text('Picked',
                                                style: TextStyle(
                                                    fontSize:
                                                        compact ? 11 : 13))
                                          ]),
                                    ])),
                            SizedBox(width: compact ? 12 : 16),
                            Expanded(
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                  _legend('Picked', order.pickedLines,
                                      Colors.green.shade700,
                                      compact: compact),
                                  _legend('Pending', pending,
                                      Theme.of(context).colorScheme.primary,
                                      compact: compact),
                                  _legend('Issues', issues,
                                      Theme.of(context).colorScheme.error,
                                      compact: compact),
                                ])),
                          ]),
                        ),
                      ])),
            ),
            SizedBox(height: gap),
            SizedBox(
              height: tipsHeight,
              child: Container(
                  padding: EdgeInsets.all(compact ? 11 : 14),
                  decoration: _cardDecoration(context),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(Icons.lightbulb_outline,
                              size: compact ? 20 : 22,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 7),
                          Text('Picking Tips',
                              style: TextStyle(
                                  fontSize: compact ? 15 : 16,
                                  fontWeight: FontWeight.w800))
                        ]),
                        SizedBox(height: compact ? 5 : 8),
                        Text(
                            '• Follow the product location for faster picking\n• Scan the product barcode to confirm\n• Complete all required items to continue',
                            maxLines: 3,
                            style: TextStyle(
                                fontSize: compact ? 11.5 : 12.5,
                                height: compact ? 1.35 : 1.45)),
                      ])),
            ),
            if (canNote && orderId != null) ...[
              SizedBox(height: gap),
              SizedBox(
                height: metrics.noteHeight,
                child: Semantics(
                    button: true,
                    label: 'Add Picking Note',
                    child: OutlinedButton.icon(
                      key: const Key('add-picking-note'),
                      onPressed: () => PickingNoteDialog.show(context,
                          onSave: (note) => ref
                              .read(posPickingActionsProvider(orderId!))
                              .addNote(order, note),
                          existingNotes: order.notes),
                      icon: const Icon(Icons.note_add_outlined, size: 21),
                      label: const Row(children: [
                        Expanded(child: Text('Add Picking Note')),
                        Icon(Icons.chevron_right, size: 21),
                      ]),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.centerLeft),
                    )),
              ),
            ],
            SizedBox(height: canNote && orderId != null ? gap * 2 : gap),
            SizedBox(
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
            ),
            const SizedBox(height: 4),
            Text(
                order.canPack
                    ? 'All required items are ready for review'
                    : 'Pick all items to continue',
                textAlign: TextAlign.center,
                maxLines: 1,
                style: OnlineOrderUi.subtitle
                    .copyWith(fontSize: compact ? 11 : 12)),
          ]);
    });
  }

  Widget _legend(String label, int value, Color color,
          {required bool compact}) =>
      Padding(
          padding: EdgeInsets.symmetric(vertical: compact ? 4 : 5),
          child: Row(children: [
            Container(
                width: compact ? 8 : 10,
                height: compact ? 8 : 10,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 7),
            Expanded(
                child:
                    Text(label, style: TextStyle(fontSize: compact ? 12 : 14))),
            Text('$value',
                style: TextStyle(
                    fontSize: compact ? 12 : 14, fontWeight: FontWeight.w800)),
          ]));
}

class PickingNoteDialog extends StatefulWidget {
  const PickingNoteDialog(
      {required this.onSave, required this.existingNotes, super.key});
  final Future<PosPickingNoteCommandResult> Function(String note) onSave;
  final List<PosPickingNote> existingNotes;
  static Future<void> show(BuildContext context,
          {required Future<PosPickingNoteCommandResult> Function(String note)
              onSave,
          required List<PosPickingNote> existingNotes}) =>
      showAppDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) =>
              PickingNoteDialog(onSave: onSave, existingNotes: existingNotes));
  @override
  State<PickingNoteDialog> createState() => _PickingNoteDialogState();
}

class _PickingNoteDialogState extends State<PickingNoteDialog> {
  final controller = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = controller.text.trim();
    if (value.isEmpty) {
      setState(() => error = 'Picking note is required.');
      return;
    }
    if (value.length > 500 || busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.onSave(value);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (exception) {
      if (mounted) {
        if (exception is DioException &&
            exception.response?.statusCode == 409) {
          final messenger = ScaffoldMessenger.maybeOf(context);
          Navigator.pop(context);
          messenger?.showSnackBar(const SnackBar(
              content:
                  Text('This order changed. Picking details were refreshed.')));
          return;
        }
        setState(() {
          busy = false;
          error = 'Unable to save the picking note. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Add Picking Note'),
        content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.existingNotes.isNotEmpty)
                    Text('${widget.existingNotes.length} saved note(s)',
                        style: OnlineOrderUi.subtitle),
                  TextField(
                      key: const Key('picking-note-field'),
                      controller: controller,
                      autofocus: true,
                      maxLength: 500,
                      maxLines: 4,
                      enabled: !busy,
                      decoration: InputDecoration(
                          labelText: 'Operational note', errorText: error)),
                ])),
        actions: [
          TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text('Cancel')),
          PosPrimaryActionButton(
              label: 'Save Note',
              compact: true,
              isLoading: busy,
              onPressed: busy ? null : _save,
              backgroundColor: Theme.of(context).colorScheme.primary,
              gradient: null),
        ],
      );
}

class ReportPickingIssueDialog extends StatefulWidget {
  const ReportPickingIssueDialog({required this.line, super.key});
  final PosPickingLine line;
  static Future<String?> show(BuildContext context, PosPickingLine line) =>
      showAppDialog<String>(
          context: context,
          builder: (_) => ReportPickingIssueDialog(line: line));
  @override
  State<ReportPickingIssueDialog> createState() =>
      _ReportPickingIssueDialogState();
}

class _ReportPickingIssueDialogState extends State<ReportPickingIssueDialog> {
  final note = TextEditingController();
  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Report Item Not Found'),
        content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.line.productName,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                  controller: note,
                  maxLength: 500,
                  decoration:
                      const InputDecoration(labelText: 'Optional note')),
            ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, note.text.trim()),
              child: const Text('Report issue')),
        ],
      );
}

BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      border: Border.all(color: Theme.of(context).dividerColor),
      borderRadius: BorderRadius.circular(12),
    );
String _quantity(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);
String _collection(DateTime? value) => value == null
    ? 'Not scheduled'
    : DateFormat('dd MMM, hh:mm a').format(value.toLocal());

({String label, String shortLabel, bool isOverdue}) _urgency(
    DateTime? collection, DateTime? server) {
  if (collection == null || server == null) {
    return (label: '', shortLabel: 'Not set', isOverdue: false);
  }
  final difference = collection.difference(server);
  final overdue = difference.isNegative;
  final duration = difference.abs();
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final short = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  return (
    label: overdue ? '(overdue by $short)' : '(in $short)',
    shortLabel: short,
    isOverdue: overdue
  );
}

void _showError(BuildContext context, Object error) {
  final message = error is DioException
      ? onlineOrderErrorMessage(error)
      : 'Unable to complete the picking action. Try again.';
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
