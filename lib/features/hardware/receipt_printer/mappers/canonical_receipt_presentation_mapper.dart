import '../../../sale/domain/entities/pos_checkout_summary.dart';
import '../../../sale/presentation/providers/pos_cash_payment_success_provider.dart';
import '../../../../shared/pos_session/pos_session_context.dart';
import '../models/canonical_receipt_presentation.dart';
import '../models/completed_sale_receipt.dart';

/// Maps authoritative completed-sale data into the shared receipt presentation.
class CanonicalReceiptPresentationMapper {
  const CanonicalReceiptPresentationMapper();

  CanonicalReceiptPresentation fromCompletedSale(
    CompletedSaleReceipt receipt, {
    String? brandSubtitle,
    String? outletLocation,
    String? outletTimezoneId,
  }) {
    final paymentDisplay = _paymentMethodDisplay(receipt);
    final itemCount = receipt.items.fold<int>(0, (sum, i) => sum + i.quantity);
    return CanonicalReceiptPresentation(
      merchantName: receipt.merchantName.trim().isEmpty
          ? 'POS'
          : receipt.merchantName.trim(),
      brandSubtitle: brandSubtitle?.trim() ?? '',
      outletName: receipt.outletName.trim(),
      outletLocation: outletLocation?.trim() ?? '',
      receiptNumber: receipt.receiptNumber.trim(),
      issuedAtUtc: receipt.completedAt.toUtc(),
      issuedAtDisplay: ReceiptDateTimeFormatter.format(
        receipt.completedAt,
        outletTimezoneId: outletTimezoneId,
      ),
      cashierName: receipt.cashierName.trim(),
      customerDisplayName: _resolveCustomerDisplayName(receipt.customerName),
      terminalName: receipt.tillName.trim(),
      paymentMethodDisplay: paymentDisplay,
      currency: receipt.currency.trim().isEmpty
          ? 'LKR'
          : receipt.currency.trim().toUpperCase(),
      items: receipt.items
          .map(_itemFromCompleted)
          .toList(growable: false),
      itemCount: itemCount,
      subtotal: receipt.subtotal,
      discountTotal: receipt.discountTotal,
      taxTotal: receipt.taxTotal,
      total: receipt.total,
      amountTendered: receipt.amountTendered,
      changeDue: receipt.change,
      barcodeValue: receipt.barcodeValue.trim().isNotEmpty
          ? receipt.barcodeValue.trim()
          : receipt.receiptNumber.trim(),
      thankYouText: _thankYou(receipt.footerLines),
      policyText: _policy(receipt.footerLines),
      isReprint: receipt.isReprint,
      copyType: receipt.copyType,
    );
  }

  /// Payment Success preview path — prefers authoritative payload when present.
  CanonicalReceiptPresentation fromPaymentSuccess({
    required PosCashPaymentSuccessData success,
    required PosSessionContext session,
    required String cashierFallback,
    String? outletTimezoneId,
  }) {
    final payment = success.authoritativePayment;
    if (payment != null) {
      return fromCheckoutPayload(
        payment,
        merchantFallback: session.brandName,
        brandSubtitle: session.brandSubtitle,
        outletNameFallback: session.outletName,
        outletLocation: _cleanPending(session.outletLocation) ?? '',
        tillNameFallback: session.tillName,
        cashierFallback: cashierFallback,
        outletTimezoneId: outletTimezoneId,
        customerNameOverride: success.customerName,
      );
    }

    final itemCount = success.items.fold<int>(0, (sum, i) => sum + i.quantity);
    return CanonicalReceiptPresentation(
      merchantName: session.brandName.trim().isEmpty
          ? 'POS'
          : session.brandName.trim(),
      brandSubtitle: session.brandSubtitle.trim(),
      outletName: _cleanPending(session.outletName) ?? '',
      outletLocation: _cleanPending(session.outletLocation) ?? '',
      receiptNumber: success.receiptNumber.trim(),
      issuedAtUtc: success.completedAt.toUtc(),
      issuedAtDisplay: ReceiptDateTimeFormatter.format(
        success.completedAt,
        outletTimezoneId: outletTimezoneId,
      ),
      cashierName: (success.cashierName ?? cashierFallback).trim(),
      customerDisplayName: _resolveCustomerDisplayName(success.customerName),
      terminalName: _cleanPending(session.tillName) ?? '',
      paymentMethodDisplay: 'Cash',
      currency: 'LKR',
      items: success.items
          .map(
            (item) => CanonicalReceiptItemPresentation(
              name: item.name,
              sku: item.variantSummary?.trim() ?? '',
              quantity: item.quantity,
              valueUnitPrice: item.unitPrice,
              rateUnitPrice: _rate(item.quantity, item.lineTotal, item.unitPrice),
              lineTotal: item.lineTotal,
            ),
          )
          .toList(growable: false),
      itemCount: itemCount,
      subtotal: success.subtotal,
      discountTotal: success.discount,
      taxTotal: success.tax,
      total: success.total,
      amountTendered: success.cashReceived,
      changeDue: success.changeDue,
      barcodeValue: success.barcodeValue.trim().isNotEmpty
          ? success.barcodeValue.trim()
          : success.receiptNumber.trim(),
      thankYouText: CanonicalReceiptPresentation.defaultThankYouText,
      policyText: CanonicalReceiptPresentation.defaultPolicyText,
    );
  }

  CanonicalReceiptPresentation fromCheckoutPayload(
    PosCheckoutStartPaymentPayload payment, {
    required String merchantFallback,
    String brandSubtitle = '',
    String outletNameFallback = '',
    String outletLocation = '',
    String tillNameFallback = '',
    String cashierFallback = '',
    String? outletTimezoneId,
    String? customerNameOverride,
  }) {
    final completedAt = payment.completedAt ?? DateTime.now().toUtc();
    final paymentDisplay = payment.tenders.isNotEmpty
        ? payment.tenders
            .map((t) => t.methodName.trim())
            .where((n) => n.isNotEmpty)
            .join(' + ')
        : (payment.paymentMethod.trim().isEmpty
            ? 'Cash'
            : _titleCase(payment.paymentMethod.trim()));
    final itemCount = payment.items.fold<int>(0, (sum, i) => sum + i.quantity);

    return CanonicalReceiptPresentation(
      merchantName: _fallback(payment.merchantName, merchantFallback),
      brandSubtitle: brandSubtitle.trim(),
      outletName: _fallback(payment.outletName, outletNameFallback),
      outletLocation: outletLocation.trim(),
      receiptNumber: payment.receiptNumber.trim(),
      issuedAtUtc: completedAt.toUtc(),
      issuedAtDisplay: ReceiptDateTimeFormatter.format(
        completedAt,
        outletTimezoneId: outletTimezoneId,
      ),
      cashierName: _fallback(payment.cashierName, cashierFallback),
      customerDisplayName: _resolveCustomerDisplayName(
        payment.customerName,
        customerNameOverride,
      ),
      terminalName: _fallback(payment.tillName, tillNameFallback),
      paymentMethodDisplay: paymentDisplay.isEmpty ? 'Cash' : paymentDisplay,
      currency: payment.currency.trim().isEmpty
          ? 'LKR'
          : payment.currency.trim().toUpperCase(),
      items: payment.items
          .map(
            (item) => CanonicalReceiptItemPresentation(
              name: item.name,
              sku: item.variantSummary?.trim() ?? '',
              quantity: item.quantity,
              valueUnitPrice: item.unitPrice,
              rateUnitPrice:
                  _rate(item.quantity, item.lineTotal, item.unitPrice),
              lineTotal: item.lineTotal,
            ),
          )
          .toList(growable: false),
      itemCount: itemCount,
      subtotal: payment.subtotal,
      discountTotal: payment.discount,
      taxTotal: payment.tax,
      total: payment.grandTotal,
      amountTendered: payment.cashReceived,
      changeDue: payment.changeDue,
      barcodeValue: payment.barcodeValue.trim().isNotEmpty
          ? payment.barcodeValue.trim()
          : payment.receiptNumber.trim(),
      thankYouText: CanonicalReceiptPresentation.defaultThankYouText,
      policyText: CanonicalReceiptPresentation.defaultPolicyText,
    );
  }

  CanonicalReceiptItemPresentation _itemFromCompleted(
    CompletedSaleReceiptLine item,
  ) {
    return CanonicalReceiptItemPresentation(
      name: item.name,
      sku: item.variantOrSku?.trim() ?? '',
      quantity: item.quantity,
      valueUnitPrice: item.unitPrice,
      rateUnitPrice: _rate(item.quantity, item.lineTotal, item.unitPrice),
      lineTotal: item.lineTotal,
    );
  }

  int _rate(int quantity, int lineTotal, int unitPrice) {
    if (quantity <= 0) return unitPrice;
    return (lineTotal / quantity).round();
  }

  String _paymentMethodDisplay(CompletedSaleReceipt receipt) {
    if (receipt.tenders.isNotEmpty) {
      final names = receipt.tenders
          .map((t) => t.methodName.trim())
          .where((n) => n.isNotEmpty)
          .toList(growable: false);
      if (names.isNotEmpty) return names.join(' + ');
    }
    final methods = receipt.paymentMethods
        .map((m) => _titleCase(m.trim()))
        .where((m) => m.isNotEmpty)
        .toList(growable: false);
    if (methods.isNotEmpty) return methods.join(' + ');
    return 'Cash';
  }

  String _thankYou(List<String> footerLines) {
    if (footerLines.isEmpty) {
      return CanonicalReceiptPresentation.defaultThankYouText;
    }
    return footerLines.first.trim().isEmpty
        ? CanonicalReceiptPresentation.defaultThankYouText
        : footerLines.first.trim();
  }

  String _policy(List<String> footerLines) {
    if (footerLines.length < 2) {
      return CanonicalReceiptPresentation.defaultPolicyText;
    }
    final policy = footerLines[1].trim();
    return policy.isEmpty
        ? CanonicalReceiptPresentation.defaultPolicyText
        : policy;
  }

  String _resolveCustomerDisplayName([
    String? preferred,
    String? fallback,
  ]) {
    for (final candidate in [preferred, fallback]) {
      final value = candidate?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return CanonicalReceiptPresentation.walkInCustomerLabel;
  }

  String _fallback(String? preferred, String fallback) {
    final value = preferred?.trim() ?? '';
    return value.isNotEmpty ? value : fallback.trim();
  }

  String? _cleanPending(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty ||
        trimmed.toLowerCase().contains('pending') ||
        trimmed.toLowerCase().contains('unpaired')) {
      return null;
    }
    return trimmed;
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    final lower = value.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }
}
