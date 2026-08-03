import '../../sale/domain/entities/pos_checkout_summary.dart';

class ReceiptHistoryItem {
  const ReceiptHistoryItem({
    required this.receiptId,
    required this.saleId,
    required this.receiptNumber,
    required this.saleNumber,
    required this.type,
    required this.status,
    required this.issuedAt,
    required this.cashierName,
    required this.tillName,
    required this.outletName,
    required this.paymentMethod,
    required this.currency,
    required this.total,
    required this.reprintCount,
  });

  final String receiptId;
  final String saleId;
  final String receiptNumber;
  final String saleNumber;
  final String type;
  final String status;
  final DateTime issuedAt;
  final String cashierName;
  final String tillName;
  final String outletName;
  final String paymentMethod;
  final String currency;
  final double total;
  final int reprintCount;

  factory ReceiptHistoryItem.fromJson(Map<String, dynamic> json) =>
      ReceiptHistoryItem(
        receiptId: '${json['receiptId'] ?? ''}',
        saleId: '${json['saleId'] ?? ''}',
        receiptNumber: '${json['receiptNumber'] ?? ''}',
        saleNumber: '${json['saleNumber'] ?? ''}',
        type: '${json['receiptType'] ?? ''}',
        status: '${json['receiptStatus'] ?? ''}',
        issuedAt: DateTime.parse('${json['issuedAt']}'),
        cashierName: '${json['cashierName'] ?? ''}',
        tillName: '${json['tillName'] ?? ''}',
        outletName: '${json['outletName'] ?? ''}',
        paymentMethod: '${json['paymentMethod'] ?? ''}',
        currency: '${json['currencyCode'] ?? ''}',
        total: (json['totalAmount'] as num?)?.toDouble() ?? 0,
        reprintCount: (json['reprintCount'] as num?)?.toInt() ?? 0,
      );
}

class ReceiptDetail {
  const ReceiptDetail({
    required this.summary,
    required this.cashierUserId,
    required this.tillId,
    required this.outletId,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paid,
    required this.change,
    required this.lines,
    this.lastReprintedAt,
    this.merchantName,
    this.tenders = const [],
    this.discountLines = const [],
    this.taxLines = const [],
    this.copyPolicy = const PosReceiptCopyPolicyPayload(),
    this.taxRegistrationNumber,
    this.taxInvoiceLabel,
    this.historicalSnapshot = const {},
  });

  final ReceiptHistoryItem summary;
  final String cashierUserId;
  final String tillId;
  final String outletId;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final double paid;
  final double change;
  final List<ReceiptDetailLine> lines;
  final DateTime? lastReprintedAt;
  final String? merchantName;
  final List<PosReceiptTenderPayload> tenders;
  final List<PosReceiptDiscountPayload> discountLines;
  final List<PosReceiptTaxPayload> taxLines;
  final PosReceiptCopyPolicyPayload copyPolicy;
  final String? taxRegistrationNumber, taxInvoiceLabel;
  final Map<String, dynamic> historicalSnapshot;

  factory ReceiptDetail.fromJson(Map<String, dynamic> json) => ReceiptDetail(
        summary: ReceiptHistoryItem.fromJson(json),
        cashierUserId: '${json['cashierUserId'] ?? ''}',
        tillId: '${json['tillId'] ?? ''}',
        outletId: '${json['outletId'] ?? ''}',
        subtotal: (json['subtotalAmount'] as num?)?.toDouble() ?? 0,
        discount: (json['discountAmount'] as num?)?.toDouble() ?? 0,
        tax: (json['taxAmount'] as num?)?.toDouble() ?? 0,
        total: (json['totalAmount'] as num?)?.toDouble() ?? 0,
        paid: (json['paidAmount'] as num?)?.toDouble() ?? 0,
        change: (json['changeAmount'] as num?)?.toDouble() ?? 0,
        lines: (json['items'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => ReceiptDetailLine.fromJson(e.cast<String, dynamic>()))
            .toList(growable: false),
        lastReprintedAt: json['lastReprintedAt'] == null
            ? null
            : DateTime.tryParse('${json['lastReprintedAt']}'),
        merchantName: json['merchantName']?.toString(),
        tenders: _maps(json['tenders'])
            .map(PosReceiptTenderPayload.fromJson)
            .toList(growable: false),
        discountLines: _maps(json['discountLines'])
            .map(PosReceiptDiscountPayload.fromJson)
            .toList(growable: false),
        taxLines: _maps(json['taxLines'])
            .map(PosReceiptTaxPayload.fromJson)
            .toList(growable: false),
        copyPolicy: PosReceiptCopyPolicyPayload.fromJson(
          json['copyPolicy'] is Map
              ? Map<String, dynamic>.from(json['copyPolicy'] as Map)
              : const {},
        ),
        taxRegistrationNumber: json['taxRegistrationNumber']?.toString(),
        taxInvoiceLabel: json['taxInvoiceLabel']?.toString(),
        historicalSnapshot: json['historicalSnapshot'] is Map
            ? Map<String, dynamic>.from(json['historicalSnapshot'] as Map)
            : const {},
      );
}

List<Map<String, dynamic>> _maps(Object? value) => value is Iterable
    ? value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false)
    : const [];

class ReceiptDetailLine {
  const ReceiptDetailLine(this.name, this.sku, this.quantity, this.unitPrice,
      this.lineTotal, this.saleLineId);
  final String name;
  final String? sku;
  final double quantity;
  final double unitPrice;
  final double lineTotal;
  final String? saleLineId;

  factory ReceiptDetailLine.fromJson(Map<String, dynamic> json) =>
      ReceiptDetailLine(
        '${json['name'] ?? 'Item'}',
        json['sku']?.toString(),
        (json['quantity'] as num?)?.toDouble() ?? 0,
        (json['unitPrice'] as num?)?.toDouble() ?? 0,
        (json['lineTotal'] as num?)?.toDouble() ?? 0,
        json['saleLineId']?.toString(),
      );
}

abstract final class ReceiptReprintReasons {
  static const values = <String, String>{
    'CUSTOMER_REQUEST': 'Customer request',
    'ORIGINAL_DAMAGED': 'Original damaged',
    'ORIGINAL_LOST': 'Original lost',
    'PRINTER_FAILURE': 'Printer failure',
    'OTHER': 'Other',
  };
}
