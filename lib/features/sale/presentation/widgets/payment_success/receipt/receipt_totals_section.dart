import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../domain/entities/pos_receipt_snapshot.dart';

class ReceiptTotalsSection extends StatelessWidget {
  const ReceiptTotalsSection({super.key, required this.totals});

  final PosReceiptTotals totals;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow('Subtotal', totals.subtotal),
        if (totals.discount > 0) _buildRow('Discount', -totals.discount),
        if (totals.tax > 0) _buildRow('Tax', totals.tax),
        if (totals.charges > 0) _buildRow('Charges', totals.charges),
        if (totals.rounding != 0) _buildRow('Rounding', totals.rounding),
        const SizedBox(height: TenantAdminSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TOTAL',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _formatCurrency(totals.total),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(String label, int amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(_formatCurrency(amount), style: const TextStyle(fontSize: 12)),
        ],
      ),
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
