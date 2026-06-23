import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/presentation/providers/pos_new_sale_cart_provider.dart';
import '../providers/pos_checkout_summary_provider.dart';
import 'pos_cash_payment_provider.dart';

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
    required this.completedAt,
    required this.itemCount,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.cashReceived,
    required this.changeDue,
    required this.items,
  });

  final String receiptNumber;
  final DateTime completedAt;
  final int itemCount;
  final int subtotal;
  final int discount;
  final int tax;
  final int total;
  final int cashReceived;
  final int changeDue;
  final List<PosCashPaymentSuccessLineItem> items;
}

class PosCashPaymentSuccessNotifier extends StateNotifier<PosCashPaymentSuccessData?> {
  PosCashPaymentSuccessNotifier() : super(null);

  void recordCashPayment({
    required PosCheckoutSummaryViewData summary,
    required PosNewSaleCartState cart,
    required int cashReceived,
  }) {
    final completedAt = DateTime.now();
    final items = cart.itemList
        .map(
          (item) => PosCashPaymentSuccessLineItem(
            name: item.product.name,
            quantity: item.quantity,
            unitPrice: item.product.price,
            lineTotal: item.lineTotal,
            variantSummary: item.product.variantSummary.trim().isEmpty
                ? null
                : item.product.variantSummary,
          ),
        )
        .toList(growable: false);

    state = PosCashPaymentSuccessData(
      receiptNumber: _generateTempReceiptNumber(completedAt),
      completedAt: completedAt,
      itemCount: summary.itemCount,
      subtotal: summary.subtotal,
      discount: summary.discount,
      tax: summary.tax,
      total: summary.totalPayable,
      cashReceived: cashReceived,
      changeDue: cashPaymentChangeDue(cashReceived, summary.totalPayable),
      items: items,
    );
  }

  void clear() {
    state = null;
  }

  String _generateTempReceiptNumber(DateTime completedAt) {
    final datePart =
        '${completedAt.year.toString().substring(2)}'
        '${completedAt.month.toString().padLeft(2, '0')}'
        '${completedAt.day.toString().padLeft(2, '0')}';
    final sequence = (completedAt.millisecondsSinceEpoch % 10000)
        .toString()
        .padLeft(4, '0');
    return 'RCPT-$datePart-$sequence';
  }
}

final posCashPaymentSuccessProvider =
    StateNotifierProvider<PosCashPaymentSuccessNotifier, PosCashPaymentSuccessData?>(
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
