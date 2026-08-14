import '../../domain/entities/pos_receipt_snapshot.dart';

/// Prefer human-readable cashier names over email addresses on receipts.
String resolveReceiptCashierDisplayName({
  String? receiptDataJson,
  String? paymentCashierName,
  String? sessionDisplayName,
}) {
  final snapshot = PosReceiptSnapshot.parse(receiptDataJson);
  final candidates = <String?>[
    snapshot?.operatorDetails.cashierName,
    paymentCashierName,
    sessionDisplayName,
  ];

  for (final raw in candidates) {
    final value = raw?.trim();
    if (value != null && value.isNotEmpty && !_looksLikeEmail(value)) {
      return value;
    }
  }

  for (final raw in candidates) {
    final value = raw?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }

  return 'Unknown Cashier';
}

bool _looksLikeEmail(String value) {
  final trimmed = value.trim();
  return trimmed.contains('@') && trimmed.contains('.');
}
