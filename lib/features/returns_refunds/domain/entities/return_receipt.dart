class ReturnReceipt {
  const ReturnReceipt({
    required this.returnId,
    required this.receiptNumber,
    required this.originalInvoiceNo,
    required this.returnedItemCount,
    required this.settlementMethodCode,
    required this.settlementMethodLabel,
    required this.settlementDisplay,
    required this.settlementResult,
    required this.currency,
    required this.refundAmount,
    required this.customerCreditAmount,
    required this.completedAt,
    required this.returnStatus,
    required this.customerName,
    required this.cashierName,
    required this.tillName,
    required this.approvalStatus,
    required this.customerAcknowledgement,
  });

  final String returnId;
  final String receiptNumber;
  final String originalInvoiceNo;
  final int returnedItemCount;
  final String settlementMethodCode;
  final String settlementMethodLabel;
  final String settlementDisplay;
  final String settlementResult;
  final String currency;
  final double refundAmount;
  final double customerCreditAmount;
  final DateTime? completedAt;
  final String returnStatus;
  final String customerName;
  final String cashierName;
  final String tillName;
  final String approvalStatus;
  final String customerAcknowledgement;

  factory ReturnReceipt.fromJson(Map<String, dynamic> json) {
    return ReturnReceipt(
      returnId: _readString(json, 'returnId'),
      receiptNumber: _readString(json, 'receiptNumber'),
      originalInvoiceNo: _readString(json, 'originalInvoiceNo'),
      returnedItemCount: _readInt(json, 'returnedItemCount'),
      settlementMethodCode: _readString(json, 'settlementMethodCode'),
      settlementMethodLabel: _readString(json, 'settlementMethodLabel'),
      settlementDisplay: _readString(json, 'settlementDisplay'),
      settlementResult: _readString(json, 'settlementResult'),
      currency: _readString(json, 'currency'),
      refundAmount: _readDouble(json, 'refundAmount'),
      customerCreditAmount: _readDouble(json, 'customerCreditAmount'),
      completedAt: _readDateTime(json['completedAt']),
      returnStatus: _readString(json, 'returnStatus'),
      customerName: _readString(json, 'customerName'),
      cashierName: _readString(json, 'cashierName'),
      tillName: _readString(json, 'tillName'),
      approvalStatus: _readString(json, 'approvalStatus'),
      customerAcknowledgement: _readString(json, 'customerAcknowledgement'),
    );
  }
}

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return '';
  }
  return value.toString();
}

double _readDouble(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _readInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _readDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value.toLocal();
  }
  return DateTime.tryParse(value.toString())?.toLocal();
}
