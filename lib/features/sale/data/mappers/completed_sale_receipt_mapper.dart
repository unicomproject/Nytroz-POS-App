import '../../../auth/domain/entities/auth_session.dart';
import '../../../device_activation/domain/entities/pos_device_context.dart';
import '../../../hardware/receipt_printer/models/canonical_receipt_presentation.dart';
import '../../../hardware/receipt_printer/models/completed_sale_receipt.dart';
import '../../domain/entities/pos_checkout_summary.dart';

class CompletedSaleReceiptMapper {
  const CompletedSaleReceiptMapper();

  CompletedSaleReceipt fromCompletedPayment({
    required PosCheckoutStartPaymentPayload payment,
    required PosDeviceContext device,
    required AuthSession session,
    String? customerNameOverride,
    String? customerPhoneOverride,
  }) {
    if (!_isCompleted(payment)) {
      throw const FormatException(
        'A receipt can only be mapped from a completed persisted sale.',
      );
    }
    if (payment.tenders.isEmpty ||
        payment.tenders.fold<int>(0, (sum, line) => sum + line.amount) !=
            payment.grandTotal) {
      throw const FormatException(
        'Authoritative completed receipt payment data is unavailable.',
      );
    }

    final receiptId = payment.receiptId?.trim();
    final customerName = _firstNonEmpty(
          payment.customerName,
          customerNameOverride,
        );
    final customerPhone = _firstNonEmpty(
          payment.customerPhone,
          customerPhoneOverride,
        );
    return CompletedSaleReceipt(
      receiptId:
          receiptId?.isNotEmpty == true ? receiptId! : payment.saleId.trim(),
      saleId: payment.saleId.trim(),
      receiptNumber: payment.receiptNumber.trim(),
      completedAt: payment.completedAt!,
      merchantName: _fallback(payment.merchantName, 'POS'),
      outletName: _fallback(payment.outletName, device.outletName),
      tillId: _fallback(payment.tillId, device.tillId),
      tillName: _fallback(payment.tillName, device.tillName),
      cashierId: _fallback(payment.cashierId, session.userId),
      cashierName: _fallback(payment.cashierName, session.userDisplayName),
      customerName: customerName,
      customerPhone: customerPhone,
      deviceId: device.deviceId,
      currency: payment.currency.trim().toUpperCase(),
      items: payment.items
          .map(
            (item) => CompletedSaleReceiptLine(
              name: item.name,
              quantity: item.quantity,
              unitPrice: item.unitPrice,
              lineTotal: item.lineTotal,
              variantOrSku: item.variantSummary,
              saleLineId: item.saleLineId,
            ),
          )
          .toList(growable: false),
      subtotal: payment.subtotal,
      discountTotal: payment.discount,
      taxTotal: payment.tax,
      total: payment.grandTotal,
      paymentMethods: [payment.paymentMethod.trim()],
      amountTendered: payment.cashReceived,
      change: payment.changeDue,
      barcodeValue: _fallback(payment.barcodeValue, payment.receiptNumber),
      footerLines: const [
        CanonicalReceiptPresentation.defaultThankYouText,
        CanonicalReceiptPresentation.defaultPolicyText,
      ],
      tenders: payment.tenders
          .map(
            (line) => CompletedSaleTender(
              methodCode: line.methodCode,
              methodName: line.methodName,
              methodType: line.methodType,
              amount: line.amount,
              amountTendered: line.amountTendered,
              changeAmount: line.changeAmount,
              currency: line.currency,
              status: line.status,
              providerName: line.providerName,
              cardBrand: line.cardBrand,
              maskedCardLast4: line.maskedCardLast4,
              authorizationReference: line.authorizationReference,
              terminalReference: line.terminalReference,
            ),
          )
          .toList(growable: false),
      discountLines: payment.discountLines
          .map(
            (line) => CompletedSaleDiscount(
              scope: line.scope,
              saleLineId: line.saleLineId,
              name: line.name,
              code: line.code,
              promotionReference: line.promotionReference,
              amount: line.amount,
            ),
          )
          .toList(growable: false),
      taxLines: payment.taxLines
          .map(
            (line) => CompletedSaleTax(
              taxCode: line.taxCode,
              taxName: line.taxName,
              rate: line.rate,
              taxableAmount: line.taxableAmount,
              taxAmount: line.taxAmount,
            ),
          )
          .toList(growable: false),
      copyPolicy: CompletedSaleCopyPolicy(
        customerCopyCount: payment.copyPolicy.customerCopyCount,
        merchantCopyCount: payment.copyPolicy.merchantCopyCount,
        printCustomerCopy: payment.copyPolicy.printCustomerCopy,
        printMerchantCopy: payment.copyPolicy.printMerchantCopy,
        terminalSlipExpected: payment.copyPolicy.terminalSlipExpected,
        terminalSlipPrintedByExternalTerminal:
            payment.copyPolicy.terminalSlipPrintedByExternalTerminal,
      ),
      taxRegistrationNumber: payment.taxRegistrationNumber,
      taxInvoiceLabel: payment.taxInvoiceLabel,
    );
  }

  bool _isCompleted(PosCheckoutStartPaymentPayload payment) {
    return payment.saleId.trim().isNotEmpty &&
        payment.receiptNumber.trim().isNotEmpty &&
        payment.completedAt != null &&
        payment.saleStatus.trim().toLowerCase() == 'completed';
  }

  String _fallback(String? preferred, String fallback) {
    final value = preferred?.trim() ?? '';
    return value.isNotEmpty ? value : fallback.trim();
  }

  String? _firstNonEmpty(String? preferred, String? fallback) {
    final a = preferred?.trim();
    if (a != null && a.isNotEmpty) return a;
    final b = fallback?.trim();
    if (b != null && b.isNotEmpty) return b;
    return null;
  }
}
