import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/entities/pos_receipt_snapshot.dart';

class ReceiptIdentitySection extends StatelessWidget {
  const ReceiptIdentitySection({
    super.key,
    required this.identity,
    required this.operatorDetails,
  });

  final PosReceiptIdentity identity;
  final PosReceiptOperator operatorDetails;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    return Column(
      children: [
        _buildRow('Receipt:', identity.receiptNumber),
        _buildRow('Date:', dateFormat.format(identity.issuedAt)),
        if (operatorDetails.cashierName != null)
          _buildRow('Cashier:', operatorDetails.cashierName!),
        if (operatorDetails.tillName != null)
          _buildRow('Terminal:', operatorDetails.tillName!),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
