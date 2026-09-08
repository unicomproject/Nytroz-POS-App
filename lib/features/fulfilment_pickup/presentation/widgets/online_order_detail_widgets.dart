import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/app_cached_network_image.dart';
import '../../domain/entities/pos_online_order.dart';
import 'online_order_ui.dart';

class OrderDetailHeader extends StatelessWidget {
  const OrderDetailHeader(
      {required this.detail,
      required this.compact,
      this.dense = false,
      this.action,
      super.key});
  final PosOnlineOrderDetail detail;
  final bool compact;
  final bool dense;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final identity =
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        key: const Key('oo02-order-icon'),
        width: compact
            ? 68
            : dense
                ? 60
                : 88,
        height: compact
            ? 68
            : dense
                ? 60
                : 88,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.inventory_2_outlined,
            size: compact
                ? 34
                : dense
                    ? 30
                    : 44,
            color: theme.colorScheme.primary),
      ),
      const SizedBox(width: 20),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (dense)
            Row(children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Order #${detail.order.orderNumber}',
                    maxLines: 1,
                    softWrap: false,
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OnlineOrderStatusChip(
                  label: detail.order.statusLabel, status: detail.order.status),
            ])
          else
            Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Order #${detail.order.orderNumber}',
                      style: theme.textTheme.headlineLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  OnlineOrderStatusChip(
                      label: detail.order.statusLabel,
                      status: detail.order.status),
                ]),
          SizedBox(height: dense ? 2 : 8),
          Text(
              [
                if (detail.placedAt != null)
                  'Placed on ${DateFormat('dd MMM yyyy, hh:mm a').format(detail.placedAt!.toLocal())}',
                if (detail.salesChannel != null) 'Via ${detail.salesChannel}',
              ].join('  •  '),
              style: (dense
                      ? theme.textTheme.bodySmall
                      : theme.textTheme.bodyMedium)
                  ?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
          SizedBox(height: dense ? 5 : 18),
          Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Icon(Icons.person_outline),
                Text(detail.order.customerName,
                    style: (dense
                            ? theme.textTheme.bodyLarge
                            : theme.textTheme.titleMedium)
                        ?.copyWith(fontWeight: FontWeight.w700)),
                if (detail.customerClassification != null)
                  Chip(label: Text(detail.customerClassification!)),
              ]),
        ]),
      ),
    ]);
    final collectBy =
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.schedule_outlined, size: dense ? 24 : 30),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Collect by',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
        SizedBox(height: dense ? 2 : 8),
        Text(OnlineOrderUi.collection(detail.order.collectionAt),
            style: (dense
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.headlineSmall)
                ?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800)),
        if (_relativeTime() case final text?) ...[
          SizedBox(height: dense ? 2 : 8),
          Text(text,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: text.contains('overdue')
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              )),
        ],
      ])),
    ]);
    if (compact) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        identity,
        const SizedBox(height: 18),
        collectBy,
        if (action != null) ...[const SizedBox(height: 18), action!],
      ]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(flex: 13, child: identity),
      const SizedBox(width: 24),
      Container(
          width: 1,
          height: dense ? 74 : 112,
          color: theme.colorScheme.outlineVariant),
      const SizedBox(width: 24),
      Expanded(flex: 6, child: collectBy),
      if (action != null) ...[
        const SizedBox(width: 24),
        Flexible(flex: 7, child: action!)
      ],
    ]);
  }

  String? _relativeTime() {
    final collection = detail.order.collectionAt;
    final server = detail.serverTime;
    if (collection == null || server == null) return null;
    final difference = collection.difference(server);
    final duration = difference.isNegative ? difference.abs() : difference;
    final text = '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    return difference.isNegative ? '$text overdue' : '$text remaining';
  }
}

class OrderSummaryCards extends StatelessWidget {
  const OrderSummaryCards(
      {required this.detail, this.dense = false, super.key});
  final PosOnlineOrderDetail detail;
  final bool dense;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final cards = [
          OnlineOrderSummaryCard(
              icon: Icons.location_on_outlined,
              title: 'Collection',
              semantic: OnlineOrderSummarySemantic.collection,
              minHeight: dense ? 84 : 92,
              content: _SummaryCardContent(
                primary: detail.outletName,
                secondary: OnlineOrderUi.collection(detail.order.collectionAt),
              )),
          OnlineOrderSummaryCard(
              icon: Icons.payment_outlined,
              title: 'Payment',
              semantic:
                  OnlineOrderPaymentStatusStyle.fromStatus(detail.paymentStatus)
                      .summarySemantic,
              minHeight: dense ? 84 : 92,
              content: _SummaryCardContent(
                primaryWidget: PaymentStatusChip(status: detail.paymentStatus),
                secondary: OnlineOrderUi.money(
                    detail.order.currencyCode, detail.order.totalAmount),
                emphasizeSecondary: true,
              )),
          OnlineOrderSummaryCard(
              icon: Icons.inventory_2_outlined,
              title: 'Items',
              semantic: OnlineOrderSummarySemantic.items,
              minHeight: dense ? 84 : 92,
              content: _SummaryCardContent(
                primary: '${detail.itemCount} items',
                secondary: '${_quantity(detail.unitCount)} units',
              )),
        ];
        if (constraints.maxWidth >= 760) {
          return Row(children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i < cards.length - 1) const SizedBox(width: 16),
            ]
          ]);
        }
        return Column(
            children: cards
                .map((card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12), child: card))
                .toList(growable: false));
      });
}

class _SummaryCardContent extends StatelessWidget {
  const _SummaryCardContent({
    this.primary,
    this.primaryWidget,
    required this.secondary,
    this.emphasizeSecondary = false,
  }) : assert(primary != null || primaryWidget != null);

  final String? primary;
  final Widget? primaryWidget;
  final String secondary;
  final bool emphasizeSecondary;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          primaryWidget ??
              Text(
                primary!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
          const SizedBox(height: 1),
          Text(
            secondary,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: emphasizeSecondary
                ? Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)
                : Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
}

class OrderItemsSection extends StatelessWidget {
  const OrderItemsSection(
      {required this.detail, this.dense = false, super.key});
  final PosOnlineOrderDetail detail;
  final bool dense;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: dense ? 14 : 24, vertical: dense ? 8 : 22),
              child: Text('Order Items (${detail.itemCount})',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800))),
          const Divider(height: 1),
          for (var i = 0; i < detail.lines.length; i++) ...[
            OnlineOrderItemRow(line: detail.lines[i], dense: dense),
            if (i < detail.lines.length - 1) const Divider(height: 1),
          ],
        ]),
      );
}

class OnlineOrderItemRow extends StatelessWidget {
  const OnlineOrderItemRow({required this.line, this.dense = false, super.key});
  final PosOnlineOrderLine line;
  final bool dense;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final image = Semantics(
            image: true,
            label: line.altText ?? '${line.productName} product image',
            child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ColoredBox(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: AppCachedNetworkImage(
                        imageUrl: line.imageUrl,
                        width: dense ? 60 : 100,
                        height: dense ? 60 : 100,
                        fit: BoxFit.contain,
                        errorWidget: SizedBox(
                            width: dense ? 60 : 100,
                            height: dense ? 60 : 100,
                            child:
                                Icon(Icons.image_not_supported_outlined))))));
        final description =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(line.productName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          if (line.variantName != null) ...[
            const SizedBox(height: 6),
            Text(line.variantName!),
          ],
          if (line.sku != null) ...[
            const SizedBox(height: 4),
            Text('SKU: ${line.sku}'),
          ],
        ]);
        final quantity =
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Quantity'),
          Text(_quantity(line.quantity),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          Text('${_quantity(line.remainingQuantity)} remaining'),
        ]);
        if (constraints.maxWidth < 600) {
          return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                image,
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      description,
                      const SizedBox(height: 10),
                      quantity
                    ]))
              ]));
        }
        return Padding(
            padding: EdgeInsets.symmetric(
                horizontal: dense ? 14 : 24, vertical: dense ? 6 : 16),
            child: Row(children: [
              image,
              const SizedBox(width: 18),
              Expanded(child: description),
              const SizedBox(width: 18),
              SizedBox(width: 150, child: quantity)
            ]));
      });
}

String _quantity(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(2);
