import '../../returns_refunds/domain/entities/return_receipt.dart';
import 'receipt_history_models.dart';

ReturnReceipt mapHistoricalNonSaleReceipt(ReceiptDetail detail) {
  final snapshot = _InsensitiveMap(detail.historicalSnapshot);
  final type = detail.summary.type.trim().toUpperCase();
  final exchange = type == 'EXCHANGE';
  final returned = _items(
    snapshot.value(exchange ? 'returnedItems' : 'items'),
    replacement: false,
  );
  final replacements = _items(
    snapshot.value('replacementItems'),
    replacement: true,
  );
  final settlementCode = snapshot.text('settlementMethodCode') ??
      (exchange ? 'NO_SETTLEMENT' : '');
  final returnId = snapshot.text('returnId');

  return ReturnReceipt(
    returnId: returnId ?? detail.summary.receiptId,
    receiptId: detail.summary.receiptId,
    receiptNumber: detail.summary.receiptNumber,
    originalSaleId: snapshot.text('originalSaleId') ?? detail.summary.saleId,
    originalInvoiceNo: snapshot.text('originalInvoiceNo') ??
        snapshot.text('originalSaleNumber') ??
        detail.summary.saleNumber,
    returnedItemCount:
        returned.fold<double>(0, (sum, item) => sum + item.quantity).round(),
    settlementMethodCode: settlementCode,
    settlementMethodLabel: settlementCode,
    settlementDisplay: settlementCode,
    settlementResult: snapshot.text('differenceDirection') ?? settlementCode,
    currency: detail.summary.currency,
    refundAmount: exchange ? 0 : detail.total,
    customerCreditAmount: exchange
        ? (snapshot.number('returnValue') ?? detail.total)
        : detail.total,
    completedAt: detail.summary.issuedAt,
    returnStatus: 'COMPLETED',
    customerName: '',
    cashierName: detail.summary.cashierName,
    tillName: detail.summary.tillName,
    approvalStatus: 'COMPLETED',
    customerAcknowledgement: '',
    resolution: exchange ? 'EXCHANGE' : 'REFUND',
    returnNumber: snapshot.text('returnNumber'),
    exchangeNumber: snapshot.text('exchangeNumber'),
    salesExchangeId: snapshot.text('exchangeId'),
    replacementOrderNumber: snapshot.text('replacementOrderNumber'),
    returnedItems: returned,
    replacementItems: replacements,
    returnItemValue: snapshot.number('returnValue') ?? detail.subtotal,
    replacementItemValue: snapshot.number('replacementValue'),
    differenceAmount: snapshot.number('difference'),
    differenceDirection: snapshot.text('differenceDirection'),
    outletId: detail.outletId,
    outletName: detail.summary.outletName,
    tillId: detail.tillId,
    processedByUserId: detail.cashierUserId,
    processedByName: detail.summary.cashierName,
    receiptType: type,
    originalSaleNumber: detail.summary.saleNumber,
    amountPaidByCustomer:
        snapshot.text('differenceDirection') == 'CUSTOMER_PAYS'
            ? snapshot.number('difference')
            : null,
    amountRefundedToCustomer:
        snapshot.text('differenceDirection') == 'CUSTOMER_RECEIVES'
            ? snapshot.number('difference')
            : exchange
                ? null
                : detail.total,
    returnSubtotal: exchange ? snapshot.number('returnValue') : detail.subtotal,
    returnDiscount: exchange ? null : detail.discount,
    returnTax: exchange ? null : detail.tax,
    returnTotal: exchange ? snapshot.number('returnValue') : detail.total,
    replacementSubtotal: exchange ? snapshot.number('replacementValue') : null,
    replacementTotal: exchange ? snapshot.number('replacementValue') : null,
    canPrint: true,
  );
}

List<ReturnCompletionItem> _items(Object? value, {required bool replacement}) {
  if (value is! Iterable) return const [];
  return value.whereType<Map>().map((raw) {
    final item = _InsensitiveMap(Map<String, dynamic>.from(raw));
    final quantity = item.number('quantity') ?? 0;
    final unitPrice = item.number('unitPrice') ?? 0;
    final lineTotal = item.number('total') ??
        item.number('lineTotal') ??
        item.number('lineAmount') ??
        0;
    return ReturnCompletionItem(
      saleLineId: item.text('saleLineId') ?? '',
      name: item.text('name') ?? 'Item',
      variantLabel: item.text('variantLabel') ?? item.text('sku') ?? '',
      quantity: quantity,
      unitPrice: unitPrice,
      lineAmount: lineTotal,
      isReplacement: replacement,
      sku: item.text('sku'),
      subtotal: item.number('subtotal'),
      discount: item.number('discount'),
      tax: item.number('tax'),
      total: lineTotal,
      reasonCode: item.text('reasonCode'),
      reasonDisplay: item.text('reasonDisplay') ?? item.text('reasonCode'),
    );
  }).toList(growable: false);
}

class _InsensitiveMap {
  _InsensitiveMap(Map<String, dynamic> source)
      : _values = {
          for (final entry in source.entries)
            entry.key.toLowerCase(): entry.value,
        };

  final Map<String, dynamic> _values;

  Object? value(String key) => _values[key.toLowerCase()];

  String? text(String key) {
    final raw = value(key);
    final text = raw?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  double? number(String key) {
    final raw = value(key);
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '');
  }
}
