import 'package:flutter/material.dart';

import '../../domain/entities/pos_online_order.dart';
import 'online_order_ui.dart';

class OnlineOrderHero extends StatelessWidget {
  const OnlineOrderHero({required this.detail, super.key});

  final PosOnlineOrderDetail detail;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(detail.order.orderNumber, style: OnlineOrderUi.title),
          OnlineOrderStatusChip(
            label: detail.order.statusLabel,
            status: detail.order.status,
          ),
        ],
      );
}

class OrderCollectionSummaryCard extends StatelessWidget {
  const OrderCollectionSummaryCard({required this.detail, super.key});
  final PosOnlineOrderDetail detail;

  @override
  Widget build(BuildContext context) => _SummaryCard(
        icon: Icons.storefront_outlined,
        label: 'Collection',
        value: detail.outletName,
        footer: OnlineOrderUi.collection(detail.order.collectionAt),
      );
}

class OrderPaymentSummaryCard extends StatelessWidget {
  const OrderPaymentSummaryCard({required this.detail, super.key});
  final PosOnlineOrderDetail detail;

  @override
  Widget build(BuildContext context) => _SummaryCard(
        icon: Icons.payments_outlined,
        label: 'Payment',
        value: detail.paymentStatus,
        footer: OnlineOrderUi.money(
          detail.order.currencyCode,
          detail.order.totalAmount,
        ),
      );
}

class OrderItemsSummaryCard extends StatelessWidget {
  const OrderItemsSummaryCard({required this.detail, super.key});
  final PosOnlineOrderDetail detail;

  @override
  Widget build(BuildContext context) => _SummaryCard(
        icon: Icons.inventory_2_outlined,
        label: 'Items',
        value: '${detail.lines.length} lines',
        footer:
            '${detail.lines.fold<double>(0, (sum, line) => sum + line.quantity)} units',
      );
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.footer,
  });
  final IconData icon;
  final String label;
  final String value;
  final String footer;

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: OnlineOrderUi.accentSoft,
                foregroundColor: OnlineOrderUi.accent,
                child: Icon(icon),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: OnlineOrderUi.subtitle),
                    Text(value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(footer,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OnlineOrderUi.subtitle),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class OnlineOrderItemList extends StatelessWidget {
  const OnlineOrderItemList({
    required this.detail,
    this.shrinkWrap = false,
    super.key,
  });
  final PosOnlineOrderDetail detail;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) => ListView.separated(
        shrinkWrap: shrinkWrap,
        physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
        itemCount: detail.lines.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, index) => OnlineOrderItemRow(
          line: detail.lines[index],
          currencyCode: detail.order.currencyCode,
        ),
      );
}

class OnlineOrderItemRow extends StatelessWidget {
  const OnlineOrderItemRow({
    required this.line,
    required this.currencyCode,
    super.key,
  });
  final PosOnlineOrderLine line;
  final String currencyCode;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(child: Text('${line.lineNumber}')),
        title: Text(line.productName,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text([
          line.variantName,
          if (line.sku != null) 'SKU ${line.sku}',
          'Picked ${line.pickedQuantity}/${line.quantity}',
        ].whereType<String>().join(' • ')),
        trailing: Text(
          OnlineOrderUi.money(currencyCode, line.lineTotal),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
}

class OrderTotals extends StatelessWidget {
  const OrderTotals({required this.detail, super.key});
  final PosOnlineOrderDetail detail;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _row('Subtotal', detail.subtotal),
          _row('Discount', -detail.discount, color: Colors.red),
          _row('Tax', detail.tax, color: Colors.blue),
          _row('Total', detail.order.totalAmount, strong: true),
        ],
      );

  Widget _row(String label, double amount,
          {Color? color, bool strong = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: strong ? FontWeight.w800 : FontWeight.w500)),
            ),
            Flexible(
              child: Text(
                OnlineOrderUi.money(detail.order.currencyCode, amount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(
                  color: color,
                  fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}
