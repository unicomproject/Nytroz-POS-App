import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/entities/pos_receipt_snapshot.dart';

class ReceiptItemsSection extends StatelessWidget {
  const ReceiptItemsSection({super.key, required this.items});

  final List<PosReceiptItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Expanded(
                flex: 2,
                child: Text('Item',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Expanded(
                child: Text('Qty',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            Expanded(
                flex: 2,
                child: Text('Total',
                    textAlign: TextAlign.right,
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
        ),
        const SizedBox(height: 4),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName,
                          style: const TextStyle(fontSize: 12)),
                      if (item.variantName != null &&
                          item.variantName!.isNotEmpty)
                        Text(
                          item.variantName!,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black54),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    '${item.quantity}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatCurrency(item.lineTotal),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _formatCurrency(int cents) {
    final format = NumberFormat.currency(
      symbol: '',
      decimalDigits: 2,
    );
    return format.format(cents / 100);
  }
}
