import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../shared/widgets/app_cached_network_image.dart';
import '../../../../../shared/widgets/pos_action_buttons.dart';
import '../../../domain/entities/pos_online_order.dart';
import '../../utils/picking_formatters.dart';
import '../../utils/picking_visual_metrics.dart';
import '../online_order_ui.dart';
import 'picking_progress_metrics.dart';

class PickItemWorkspace extends StatelessWidget {
  const PickItemWorkspace({
    required this.order,
    required this.line,
    required this.quantity,
    required this.isSubmitting,
    required this.canScan,
    required this.canManual,
    required this.canPick,
    required this.canReport,
    required this.onBack,
    required this.onDecrease,
    required this.onIncrease,
    required this.onPick,
    required this.onScan,
    required this.onManual,
    required this.onIssue,
    required this.onSelectLine,
    required this.onReviewPack,
    this.verifiedBarcode,
    this.verificationMessage,
    this.verificationIsError = false,
    super.key,
  });

  final PosPickingOrder order;
  final PosPickingLine line;
  final int quantity;
  final bool isSubmitting;
  final bool canScan;
  final bool canManual;
  final bool canPick;
  final bool canReport;
  final String? verifiedBarcode;
  final String? verificationMessage;
  final bool verificationIsError;
  final VoidCallback onBack;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final VoidCallback? onPick;
  final VoidCallback? onScan;
  final VoidCallback? onManual;
  final VoidCallback? onIssue;
  final ValueChanged<PosPickingLine> onSelectLine;
  final VoidCallback? onReviewPack;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 900;
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PickItemHeader(order: order, line: line, onBack: onBack),
              const SizedBox(height: 10),
              if (wide)
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 67,
                        child: _mainCard(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 33,
                        child: _PickItemOrderPanel(
                          order: order,
                          currentLine: line,
                          canReport: canReport,
                          onIssue: onIssue,
                          onSelectLine: onSelectLine,
                          onReviewPack: onReviewPack,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(children: [
                      SizedBox(height: 820, child: _mainCard(context)),
                      const SizedBox(height: 10),
                      _PickItemOrderPanel(
                        order: order,
                        currentLine: line,
                        canReport: canReport,
                        onIssue: onIssue,
                        onSelectLine: onSelectLine,
                        onReviewPack: onReviewPack,
                      ),
                    ]),
                  ),
                ),
            ],
          );
          return content;
        },
      );

  Widget _mainCard(BuildContext context) => Column(children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: pickingCardDecoration(context),
            child: LayoutBuilder(builder: (context, constraints) {
              final scanner = _BarcodeVerificationPanel(
                canScan: canScan,
                canManual: canManual,
                verified: verifiedBarcode != null,
                message: verificationMessage,
                isError: verificationIsError,
                onScan: onScan,
                onManual: onManual,
              );
              if (constraints.maxWidth < 650) {
                return Column(children: [
                  Expanded(flex: 55, child: scanner),
                  const SizedBox(height: 8),
                  Expanded(flex: 45, child: _ProductPanel(line: line)),
                ]);
              }
              return Row(children: [
                Expanded(flex: 55, child: scanner),
                const SizedBox(width: 12),
                Expanded(flex: 45, child: _ProductPanel(line: line)),
              ]);
            }),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: pickingCardDecoration(context),
          child: Row(children: [
            Expanded(
              flex: 28,
              child: _QuantityControl(
                quantity: quantity,
                maximum: line.remainingQuantity,
                onDecrease: onDecrease,
                onIncrease: onIncrease,
              ),
            ),
            const VerticalDivider(width: 16, indent: 6, endIndent: 6),
            Expanded(
              flex: 18,
              child: _ValueBlock(
                  label: 'Picked', value: line.pickedQuantity, semantic: true),
            ),
            const VerticalDivider(width: 16, indent: 6, endIndent: 6),
            Expanded(
              flex: 20,
              child: _ValueBlock(
                  label: 'Remaining', value: line.remainingQuantity),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 34,
              child: PosPrimaryActionButton(
                key: const Key('mark-as-picked'),
                label: isSubmitting ? 'Saving…' : 'Mark as Picked',
                leadingIcon: Icons.check_circle_outline,
                fullWidth: true,
                compact: true,
                minimumHeight: 44,
                verticalPadding: 8,
                horizontalPadding: 12,
                iconSize: 18,
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                onPressed: isSubmitting || !canPick ? null : onPick,
              ),
            ),
          ]),
        ),
      ]);
}

class _PickItemHeader extends StatelessWidget {
  const _PickItemHeader(
      {required this.order, required this.line, required this.onBack});
  final PosPickingOrder order;
  final PosPickingLine line;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final index = order.lines.indexWhere((item) => item.id == line.id) + 1;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: const Key('back-to-pick-items'),
          onPressed: onBack,
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: const Icon(Icons.arrow_back, size: 16),
          label:
              const Text('Back to Pick Items', style: TextStyle(fontSize: 13)),
        ),
      ),
      const SizedBox(height: 2),
      LayoutBuilder(builder: (context, constraints) {
        final identity =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Flexible(
              child: Text(
                'Pick: ${line.productName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              labelPadding: EdgeInsets.zero,
              label: Text('$index of ${order.totalLines}',
                  style: const TextStyle(fontSize: 11)),
            ),
          ]),
          const SizedBox(height: 2),
          Text(
            [
              if (line.variantName?.isNotEmpty == true) line.variantName!,
              if (line.sku?.isNotEmpty == true) 'SKU: ${line.sku}',
            ].join('  •  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OnlineOrderUi.subtitle.copyWith(fontSize: 11),
          ),
        ]);
        if (constraints.maxWidth < 900) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: 6),
                PickingProgressMetrics(order: order, compact: true),
              ]);
        }
        return Row(children: [
          Expanded(child: identity),
          const SizedBox(width: 12),
          SizedBox(
            width: 440,
            child: PickingProgressMetrics(order: order, compact: true),
          ),
        ]);
      }),
    ]);
  }
}

class _BarcodeVerificationPanel extends StatelessWidget {
  const _BarcodeVerificationPanel({
    required this.canScan,
    required this.canManual,
    required this.verified,
    required this.isError,
    required this.onScan,
    required this.onManual,
    this.message,
  });
  final bool canScan;
  final bool canManual;
  final bool verified;
  final bool isError;
  final VoidCallback? onScan;
  final VoidCallback? onManual;
  final String? message;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Scan item barcode to pick',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text('Scan the barcode on the product or packaging',
              textAlign: TextAlign.center,
              style: OnlineOrderUi.subtitle.copyWith(fontSize: 11)),
          const SizedBox(height: 8),
          Semantics(
            button: canScan,
            label: verified ? 'Barcode verified' : 'Ready to scan',
            child: InkWell(
              key: const Key('scanner-ready-card'),
              onTap: onScan,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: .035),
                  border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: .25)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          verified
                              ? Icons.verified_outlined
                              : Icons.qr_code_scanner,
                          size: 30,
                          color: verified
                              ? Colors.green.shade700
                              : Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 4),
                      Text(verified ? 'Barcode verified' : 'Ready to scan',
                          style: TextStyle(
                              fontSize: 13,
                              color: verified
                                  ? Colors.green.shade700
                                  : Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700)),
                    ]),
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    color: isError
                        ? Theme.of(context).colorScheme.error
                        : Colors.green.shade700,
                    fontWeight: FontWeight.w600)),
          ],
          if (canManual) ...[
            const SizedBox(height: 6),
            Row(children: const [
              Expanded(child: Divider(height: 1)),
              Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('OR', style: TextStyle(fontSize: 10))),
              Expanded(child: Divider(height: 1)),
            ]),
            const SizedBox(height: 6),
            Center(
              child: OutlinedButton.icon(
                key: const Key('enter-barcode-manually'),
                onPressed: onManual,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.keyboard_alt_outlined, size: 16),
                label: const Text('Enter Barcode Manually',
                    style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
          if (!canScan && !canManual)
            const Text('Barcode verification permission is required.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 11)),
        ],
      );
}

class _ProductPanel extends StatelessWidget {
  const _ProductPanel({required this.line});
  final PosPickingLine line;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(children: [
          Expanded(
            child: AppCachedNetworkImage(
              imageUrl: line.imageUrl,
              fit: BoxFit.contain,
              errorWidget: const Icon(Icons.inventory_2_outlined, size: 44),
            ),
          ),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.location_on_outlined, size: 15),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                [line.locationCode, line.locationName]
                    .whereType<String>()
                    .where((value) => value.trim().isNotEmpty)
                    .join('  •  ')
                    .ifEmpty('Location unavailable'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ]),
        ]),
      );
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl(
      {required this.quantity,
      required this.maximum,
      required this.onDecrease,
      required this.onIncrease});
  final int quantity;
  final double maximum;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Quantity to pick',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton.filledTonal(
              key: const Key('decrease-pick-quantity'),
              onPressed: onDecrease,
              iconSize: 16,
              style: IconButton.styleFrom(
                minimumSize: const Size(28, 28),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.remove),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '$quantity',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton.filledTonal(
              key: const Key('increase-pick-quantity'),
              onPressed: onIncrease,
              iconSize: 16,
              style: IconButton.styleFrom(
                minimumSize: const Size(28, 28),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.add),
            ),
          ]),
          const SizedBox(height: 1),
          Text(
            'of ${pickingQuantity(maximum)} remaining',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OnlineOrderUi.subtitle.copyWith(fontSize: 10),
          ),
        ],
      );
}

class _ValueBlock extends StatelessWidget {
  const _ValueBlock(
      {required this.label, required this.value, this.semantic = false});
  final String label;
  final double value;
  final bool semantic;
  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            pickingQuantity(value),
            maxLines: 1,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: semantic ? Colors.green.shade700 : null),
          ),
          Text(
            'unit',
            maxLines: 1,
            style: OnlineOrderUi.subtitle.copyWith(fontSize: 10),
          ),
        ],
      );
}

class _PickItemOrderPanel extends StatelessWidget {
  const _PickItemOrderPanel({
    required this.order,
    required this.currentLine,
    required this.canReport,
    required this.onIssue,
    required this.onSelectLine,
    required this.onReviewPack,
  });
  final PosPickingOrder order;
  final PosPickingLine currentLine;
  final bool canReport;
  final VoidCallback? onIssue;
  final ValueChanged<PosPickingLine> onSelectLine;
  final VoidCallback? onReviewPack;

  @override
  Widget build(BuildContext context) {
    final pending = order.lines
        .where((item) => !item.isPicked && item.id != currentLine.id)
        .toList(growable: false);
    final issues = order.lines.where((item) => item.hasReportedIssue).length;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: pickingCardDecoration(context),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(
            child: Text(
              'Order #${order.orderNumber}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
          OnlineOrderStatusChip(label: order.status, status: order.status),
        ]),
        const SizedBox(height: 2),
        Text(
          order.customerName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: OnlineOrderUi.subtitle.copyWith(fontSize: 12),
        ),
        const Divider(height: 12),
        const Text('Collection',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(
          order.collectionAt == null
              ? 'Collection time unavailable'
              : DateFormat('dd MMM, hh:mm a')
                  .format(order.collectionAt!.toLocal()),
          style: OnlineOrderUi.subtitle.copyWith(fontSize: 11),
        ),
        const Divider(height: 12),
        const Text('Order Progress',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Row(children: [
          SizedBox.square(
            dimension: 66,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: order.totalUnits <= 0
                    ? 0
                    : order.pickedUnits / order.totalUnits,
                strokeWidth: 6,
                backgroundColor: Theme.of(context).dividerColor,
                color: Theme.of(context).colorScheme.primary,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${pickingQuantity(order.pickedUnits)} / ${pickingQuantity(order.totalUnits)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    'Picked',
                    style: OnlineOrderUi.subtitle.copyWith(
                      fontSize: 10,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(children: [
            _legend(
                context, 'Picked', order.pickedUnits, Colors.green.shade700),
            _legend(context, 'Pending', order.remainingUnits,
                Theme.of(context).colorScheme.primary),
            _legend(context, 'Issues', issues.toDouble(),
                Theme.of(context).colorScheme.error),
          ])),
        ]),
        const Divider(height: 12),
        Row(children: [
          const Expanded(
              child: Text('Next Items',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800))),
          Text('${pending.length} pending',
              style: OnlineOrderUi.subtitle.copyWith(fontSize: 11)),
        ]),
        const SizedBox(height: 4),
        if (pending.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              order.canPack ? 'All items picked' : 'No other pending items',
              style: OnlineOrderUi.subtitle.copyWith(fontSize: 11),
            ),
          )
        else
          Column(
            key: const Key('next-items-list'),
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in pending.take(3))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: InkWell(
                    onTap: () => onSelectLine(item),
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox.square(
                              dimension: 28,
                              child: AppCachedNetworkImage(
                                imageUrl: item.imageUrl,
                                fit: BoxFit.cover,
                                errorWidget: const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.productName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700),
                                ),
                                if (item.variantName?.isNotEmpty == true ||
                                    item.locationName?.isNotEmpty == true)
                                  Text(
                                    [item.variantName, item.locationName]
                                        .whereType<String>()
                                        .join(' • '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: OnlineOrderUi.subtitle
                                        .copyWith(fontSize: 10),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        const Spacer(),
        if (canReport)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: TextButton.icon(
              key: const Key('cant-find-item'),
              onPressed: onIssue,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(vertical: 2),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.help_outline, size: 15),
              label: const Text("Can't Find Item?",
                  style: TextStyle(fontSize: 12)),
            ),
          ),
        PosPrimaryActionButton(
          key: const Key('pick-next-item'),
          label: order.canPack ? 'Review & Pack' : 'Pick Next Item',
          trailingIcon: Icons.arrow_forward,
          fullWidth: true,
          compact: true,
          minimumHeight: 40,
          verticalPadding: 6,
          horizontalPadding: 12,
          iconSize: 16,
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          backgroundColor: Theme.of(context).colorScheme.primary,
          gradient: null,
          onPressed: order.canPack
              ? onReviewPack
              : pending.isEmpty
                  ? null
                  : () => onSelectLine(pending.first),
        ),
      ]),
    );
  }

  Widget _legend(
          BuildContext context, String label, double value, Color color) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.5),
        child: Row(children: [
          Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 11))),
          Text(pickingQuantity(value),
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ]),
      );
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
