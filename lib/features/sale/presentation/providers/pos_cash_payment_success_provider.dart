import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/pos_checkout_summary.dart';

class PosCashPaymentSuccessLineItem {
  const PosCashPaymentSuccessLineItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.variantSummary,
  });

  final String name;
  final int quantity;
  final int unitPrice;
  final int lineTotal;
  final String? variantSummary;
}

class PosCashPaymentSuccessData {
  const PosCashPaymentSuccessData({
    required this.receiptNumber,
    required this.barcodeValue,
    required this.saleId,
    required this.completedAt,
    required this.itemCount,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.cashReceived,
    required this.changeDue,
    required this.items,
    this.customerName,
    this.customerPhone,
    this.cashierName,
    this.receiptDataJson,
  });

  final String receiptNumber;
  final String barcodeValue;
  final String saleId;
  final DateTime completedAt;
  final int itemCount;
  final int subtotal;
  final int discount;
  final int tax;
  final int total;
  final int cashReceived;
  final int changeDue;
  final List<PosCashPaymentSuccessLineItem> items;
  final String? customerName;
  final String? customerPhone;
  final String? cashierName;
  final String? receiptDataJson;
}

class PosCashPaymentSuccessNotifier
    extends StateNotifier<PosCashPaymentSuccessData?> {
  PosCashPaymentSuccessNotifier() : super(null);

  void recordCheckoutPayment(
    PosCheckoutStartPaymentPayload payload, {
    String? customerName,
    String? customerPhone,
  }) {
    state = PosCashPaymentSuccessData(
      receiptNumber: payload.receiptNumber,
      barcodeValue: payload.barcodeValue.isNotEmpty
          ? payload.barcodeValue
          : payload.receiptNumber,
      saleId: payload.saleId,
      completedAt: payload.completedAt ?? DateTime.now(),
      itemCount: payload.items.fold<int>(
        0,
        (sum, item) => sum + item.quantity,
      ),
      subtotal: payload.subtotal,
      discount: payload.discount,
      tax: payload.tax,
      total: payload.grandTotal,
      cashReceived: payload.cashReceived,
      changeDue: payload.changeDue,
      customerName: customerName?.trim().isNotEmpty == true
          ? customerName!.trim()
          : (payload.customerName?.trim().isNotEmpty == true
              ? payload.customerName!.trim()
              : null),
      customerPhone: customerPhone?.trim().isNotEmpty == true
          ? customerPhone!.trim()
          : (payload.customerPhone?.trim().isNotEmpty == true
              ? payload.customerPhone!.trim()
              : null),
      cashierName: payload.cashierName?.trim().isNotEmpty == true
          ? payload.cashierName!.trim()
          : null,
      items: payload.items
          .map(
            (item) => PosCashPaymentSuccessLineItem(
              name: item.name,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              lineTotal: item.lineTotal,
              variantSummary: item.variantSummary,
            ),
          )
          .toList(growable: false),
      receiptDataJson: payload.receiptDataJson,
    );
  }

  void clear() {
    state = null;
  }
}

final posCashPaymentSuccessProvider = StateNotifierProvider<
    PosCashPaymentSuccessNotifier, PosCashPaymentSuccessData?>(
  (ref) => PosCashPaymentSuccessNotifier(),
);

String formatReceiptDateTime(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';

  return '${months[value.month - 1]} ${value.day}, ${value.year} | '
      '$hour:$minute $period';
}
