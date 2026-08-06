import 'dart:math';

import '../models/local_print_agent_models.dart';

class LocalPrintAgentTestReceiptBuilder {
  const LocalPrintAgentTestReceiptBuilder();

  LocalPrintAgentReceiptRequest build({
    required String merchantName,
    String? outletName,
    String? tillName,
    String? cashierName,
    DateTime? now,
  }) {
    final printedAt = now ?? DateTime.now();
    return LocalPrintAgentReceiptRequest(
      requestId: _uuidV4(),
      receiptNumber: 'PRINTER-TEST',
      printedAt: printedAt,
      merchantName:
          merchantName.trim().isEmpty ? 'TM-EPOS' : merchantName.trim(),
      outletName: outletName,
      tillName: tillName,
      cashierName: cashierName,
      currency: 'LKR',
      items: const [
        LocalPrintAgentReceiptLine(
          name: 'PRINTER TEST - NOT A SALE',
          quantity: 1,
          unitPrice: 0,
          lineTotal: 0,
        ),
      ],
      subtotal: 0,
      discountTotal: 0,
      taxTotal: 0,
      total: 0,
      paymentMethod: 'TEST ONLY',
      amountTendered: 0,
      change: 0,
      footerLines: const [
        'PRINTER TEST - NOT A SALE',
        'No sale or payment was recorded.',
      ],
    );
  }

  String _uuidV4() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}
