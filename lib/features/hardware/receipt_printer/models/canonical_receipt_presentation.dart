import '../../../../core/utils/timezone_resolver.dart';

/// Single customer-facing receipt presentation contract.
///
/// Flutter preview and ESC/POS (Android + Windows) renderers consume this model.
/// Business values are authoritative; renderers must not recalculate money.
class CanonicalReceiptPresentation {
  const CanonicalReceiptPresentation({
    required this.merchantName,
    required this.brandSubtitle,
    required this.outletName,
    required this.outletLocation,
    required this.receiptNumber,
    required this.issuedAtUtc,
    required this.issuedAtDisplay,
    required this.cashierName,
    required this.customerDisplayName,
    required this.terminalName,
    required this.paymentMethodDisplay,
    required this.currency,
    required this.items,
    required this.itemCount,
    required this.subtotal,
    required this.discountTotal,
    required this.taxTotal,
    required this.total,
    required this.amountTendered,
    required this.changeDue,
    required this.barcodeValue,
    required this.thankYouText,
    required this.policyText,
    this.isReprint = false,
    this.copyType = 'CUSTOMER',
  });

  static const defaultThankYouText = 'Thank you for your purchase';
  static const defaultPolicyText =
      'Goods once sold can be exchanged with the original receipt.';
  static const walkInCustomerLabel = 'Walk-in Customer';
  static const terminalFieldLabel = 'Terminal';
  static const receiptNoLabel = 'Receipt No';
  static const dateTimeLabel = 'Date & Time';

  final String merchantName;
  final String brandSubtitle;
  final String outletName;
  final String outletLocation;
  final String receiptNumber;
  final DateTime issuedAtUtc;
  final String issuedAtDisplay;
  final String cashierName;
  final String customerDisplayName;
  final String terminalName;
  final String paymentMethodDisplay;
  final String currency;
  final List<CanonicalReceiptItemPresentation> items;
  final int itemCount;
  final int subtotal;
  final int discountTotal;
  final int taxTotal;
  final int total;
  final int amountTendered;
  final int changeDue;
  final String barcodeValue;
  final String thankYouText;
  final String policyText;
  final bool isReprint;
  final String copyType;

  String get paidByLabel => 'Paid by $paymentMethodDisplay';

  String formatMoney(int amount) =>
      ReceiptMoneyFormatter.format(currency, amount);

  String formatMoneyAmountOnly(int amount) =>
      ReceiptMoneyFormatter.formatAmountOnly(amount);

  List<String> get footerLines => [
        thankYouText,
        if (policyText.trim().isNotEmpty) policyText.trim(),
      ];
}

class CanonicalReceiptItemPresentation {
  const CanonicalReceiptItemPresentation({
    required this.name,
    required this.sku,
    required this.quantity,
    required this.valueUnitPrice,
    required this.rateUnitPrice,
    required this.lineTotal,
  });

  /// ITEM name.
  final String name;

  /// SKU / variant summary (may be empty).
  final String sku;

  final int quantity;

  /// VALUE — list/original unit price (authoritative unit price).
  final int valueUnitPrice;

  /// RATE — effective unit price charged after promotion/discount.
  final int rateUnitPrice;

  final int lineTotal;
}

/// Shared receipt money formatting (no LKR hardcoding).
class ReceiptMoneyFormatter {
  const ReceiptMoneyFormatter._();

  static String format(String currency, int amount) {
    final code = currency.trim().isEmpty ? '' : '${currency.trim()} ';
    return '$code${formatAmountOnly(amount)}';
  }

  static String formatAmountOnly(int amount) {
    final negative = amount < 0;
    final abs = amount.abs().toString();
    final grouped = _groupThousands(abs);
    return '${negative ? '-' : ''}$grouped.00';
  }

  static String _groupThousands(String raw) {
    final buffer = StringBuffer();
    for (var index = 0; index < raw.length; index += 1) {
      final digitsFromEnd = raw.length - index;
      buffer.write(raw[index]);
      if (digitsFromEnd > 1 && digitsFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }
}

/// Shared customer-facing receipt date/time formatting.
class ReceiptDateTimeFormatter {
  const ReceiptDateTimeFormatter._();

  static String format(
    DateTime issuedAt, {
    String? outletTimezoneId,
  }) {
    final localized = TimezoneResolver.toTimezone(issuedAt, outletTimezoneId);
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
    final hour = localized.hour % 12 == 0 ? 12 : localized.hour % 12;
    final minute = localized.minute.toString().padLeft(2, '0');
    final period = localized.hour >= 12 ? 'PM' : 'AM';
    return '${months[localized.month - 1]} ${localized.day}, ${localized.year} | '
        '$hour:$minute $period';
  }
}
