import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../tenant_admin/presentation/theme/tenant_admin_theme.dart';
import '../../../../domain/entities/pos_receipt_snapshot.dart';

class ReceiptTendersSection extends StatelessWidget {
  const ReceiptTendersSection({super.key, required this.tenders});

  final List<PosReceiptTender> tenders;

  @override
  Widget build(BuildContext context) {
    final validTenders = tenders.where((t) => t.amount > 0).toList();
    if (validTenders.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('TENDERS',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: TenantAdminSpacing.xs),
        for (final tender in validTenders)
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tender.paymentMethod,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (tender.safeReference != null &&
                    tender.safeReference!.isNotEmpty)
                  Expanded(
                    child: Text(
                      tender.safeReference!,
                      style:
                          const TextStyle(fontSize: 10, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: Text(
                    _formatCurrency(tender.amount),
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.right,
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
