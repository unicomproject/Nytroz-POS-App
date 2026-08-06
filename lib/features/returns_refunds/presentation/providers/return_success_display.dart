import '../../domain/entities/return_receipt.dart';
import 'return_flow_provider.dart';

enum ReturnSuccessPrintStatus {
  idle,
  unavailable,
  inProgress,
  failed,
  succeeded,
  auditFailed,
  unknown,
  partial,
}

class CompletedItemDisplay {
  const CompletedItemDisplay({
    required this.id,
    required this.name,
    required this.variantLabel,
    required this.amount,
    this.imageValue,
    this.quantity,
    this.isReplacement = false,
    this.subtotal,
    this.discount,
    this.tax,
    this.reasonDisplay,
    this.conditionDisplay,
  });

  final String id;
  final String name;
  final String variantLabel;
  final double amount;
  final String? imageValue;
  final double? quantity;
  final bool isReplacement;
  final double? subtotal;
  final double? discount;
  final double? tax;
  final String? reasonDisplay;
  final String? conditionDisplay;
}

class ReturnSuccessDisplay {
  const ReturnSuccessDisplay({
    required this.isExchange,
    required this.heading,
    required this.supportingMessage,
    required this.reference,
    required this.customerName,
    required this.processedBy,
    required this.itemCount,
    required this.currencyCode,
    required this.totalAmount,
    required this.methodLabel,
    required this.completedAt,
    required this.items,
    required this.canPrint,
    this.settlementMessage,
    this.policyMessage,
    this.returnNumber,
    this.exchangeNumber,
    this.replacementOrderNumber,
    this.receiptNumber,
    this.originalInvoiceNo,
    this.returnItemValue,
    this.replacementItemValue,
    this.differenceAmount,
    this.differenceDirection,
    this.replacementProductName,
    this.tillName,
    this.outletName,
    this.maskedCard,
    this.cardBrand,
    this.providerTransactionReference,
    this.returnSubtotal,
    this.returnDiscount,
    this.returnTax,
    this.returnTotal,
    this.replacementSubtotal,
    this.replacementDiscount,
    this.replacementTax,
    this.replacementTotal,
    this.amountPaidByCustomer,
    this.amountRefundedToCustomer,
    this.isCashSettlement = false,
    this.isEvenExchange = false,
    this.hasBeenPrinted = false,
    this.showCardDetails = false,
    this.showPaidRefundedAmount = false,
  });

  final bool isExchange;
  final String heading;
  final String supportingMessage;
  final String reference;
  final String customerName;
  final String processedBy;
  final int itemCount;
  final String currencyCode;
  final double totalAmount;
  final String methodLabel;
  final DateTime? completedAt;
  final List<CompletedItemDisplay> items;
  final bool canPrint;
  final String? settlementMessage;
  final String? policyMessage;
  final String? returnNumber;
  final String? exchangeNumber;
  final String? replacementOrderNumber;
  final String? receiptNumber;
  final String? originalInvoiceNo;
  final double? returnItemValue;
  final double? replacementItemValue;
  final double? differenceAmount;
  final String? differenceDirection;
  final String? replacementProductName;
  final String? tillName;
  final String? outletName;
  final String? maskedCard;
  final String? cardBrand;
  final String? providerTransactionReference;
  final double? returnSubtotal;
  final double? returnDiscount;
  final double? returnTax;
  final double? returnTotal;
  final double? replacementSubtotal;
  final double? replacementDiscount;
  final double? replacementTax;
  final double? replacementTotal;
  final double? amountPaidByCustomer;
  final double? amountRefundedToCustomer;
  final bool isCashSettlement;
  final bool isEvenExchange;
  final bool hasBeenPrinted;
  final bool showCardDetails;
  final bool showPaidRefundedAmount;
}

bool isValidCompletedReceipt(ReturnReceipt? receipt) {
  if (receipt == null) {
    return false;
  }
  if (receipt.isStoreCredit) {
    return false;
  }

  final reference = receipt.returnNumber?.trim().isNotEmpty == true
      ? receipt.returnNumber!.trim()
      : (receipt.receiptNumber.trim().isNotEmpty
          ? receipt.receiptNumber.trim()
          : receipt.returnId.trim());
  if (reference.isEmpty) {
    return false;
  }

  return receipt.isCompleted;
}

bool isValidReturnCompletion(ReturnFlowState flowState) {
  return isValidCompletedReceipt(flowState.completedReceipt);
}

ReturnSuccessDisplay? buildReturnSuccessDisplayFromReceipt(
    ReturnReceipt receipt) {
  if (!isValidCompletedReceipt(receipt)) {
    return null;
  }

  final isExchange = receipt.isExchange;
  final items = _itemsFromReceipt(receipt);
  final reference = isExchange
      ? (receipt.exchangeNumber?.trim().isNotEmpty == true
          ? receipt.exchangeNumber!.trim()
          : (receipt.returnNumber?.trim().isNotEmpty == true
              ? receipt.returnNumber!.trim()
              : receipt.receiptNumber.trim()))
      : (receipt.returnNumber?.trim().isNotEmpty == true
          ? receipt.returnNumber!.trim()
          : (receipt.receiptNumber.trim().isNotEmpty
              ? receipt.receiptNumber.trim()
              : receipt.returnId.trim()));

  final methodLabel = receipt.settlementDisplay.trim().isNotEmpty
      ? receipt.settlementDisplay.trim()
      : receipt.settlementMethodLabel.trim();

  final settlementMessage = receipt.policyMessage?.trim().isNotEmpty == true
      ? receipt.policyMessage!.trim()
      : (receipt.settlementResult.trim().isNotEmpty
          ? receipt.settlementResult.trim()
          : null);

  final replacementName = receipt.replacementItems.isNotEmpty
      ? receipt.replacementItems.first.name
      : null;

  final customerName =
      (receipt.customerDisplayName ?? receipt.customerName).trim();
  final processedBy = (receipt.processedByName ?? receipt.cashierName).trim();

  final showCardDetails = !receipt.isCashSettlement &&
      !receipt.isEvenExchange &&
      (receipt.maskedCard?.trim().isNotEmpty == true ||
          receipt.cardBrand?.trim().isNotEmpty == true ||
          receipt.providerTransactionReference?.trim().isNotEmpty == true);

  final showPaidRefundedAmount = isExchange && !receipt.isEvenExchange;

  return ReturnSuccessDisplay(
    isExchange: isExchange,
    heading: isExchange
        ? 'Exchange Completed Successfully'
        : 'Return Completed Successfully',
    supportingMessage: isExchange
        ? 'The exchange has been processed and recorded.'
        : 'The return has been processed and the refund is now recorded.',
    reference: reference,
    customerName: customerName,
    processedBy: processedBy,
    itemCount: receipt.returnedItemCount > 0
        ? receipt.returnedItemCount
        : items.where((item) => !item.isReplacement).length,
    currencyCode: receipt.currency.trim(),
    totalAmount: isExchange
        ? (receipt.replacementTotal ??
            receipt.replacementItemValue ??
            receipt.refundAmount)
        : (receipt.returnTotal ?? receipt.refundAmount),
    methodLabel: methodLabel,
    completedAt: receipt.completedAt,
    items: items,
    canPrint: receipt.canPrint &&
        (receipt.receiptId?.trim().isNotEmpty == true ||
            receipt.originalSaleId?.trim().isNotEmpty == true),
    settlementMessage: settlementMessage,
    policyMessage: receipt.policyMessage,
    returnNumber: receipt.returnNumber,
    exchangeNumber: receipt.exchangeNumber,
    replacementOrderNumber: receipt.replacementOrderNumber,
    receiptNumber: receipt.receiptNumber,
    originalInvoiceNo: receipt.originalInvoiceNo,
    returnItemValue: receipt.returnItemValue ?? receipt.returnTotal,
    replacementItemValue:
        receipt.replacementItemValue ?? receipt.replacementTotal,
    differenceAmount: receipt.differenceAmount,
    differenceDirection: receipt.differenceDirection,
    replacementProductName: replacementName,
    tillName: receipt.tillName.trim().isEmpty ? null : receipt.tillName.trim(),
    outletName: receipt.outletName,
    maskedCard: receipt.maskedCard,
    cardBrand: receipt.cardBrand,
    providerTransactionReference: receipt.providerTransactionReference,
    returnSubtotal: receipt.returnSubtotal,
    returnDiscount: receipt.returnDiscount,
    returnTax: receipt.returnTax,
    returnTotal: receipt.returnTotal,
    replacementSubtotal: receipt.replacementSubtotal,
    replacementDiscount: receipt.replacementDiscount,
    replacementTax: receipt.replacementTax,
    replacementTotal: receipt.replacementTotal,
    amountPaidByCustomer: receipt.amountPaidByCustomer,
    amountRefundedToCustomer: receipt.amountRefundedToCustomer,
    isCashSettlement: receipt.isCashSettlement,
    isEvenExchange: receipt.isEvenExchange,
    hasBeenPrinted: receipt.hasBeenPrinted || receipt.printCount > 0,
    showCardDetails: showCardDetails,
    showPaidRefundedAmount: showPaidRefundedAmount,
  );
}

ReturnSuccessDisplay? buildReturnSuccessDisplay(ReturnFlowState flowState) {
  final receipt = flowState.completedReceipt;
  if (receipt == null) {
    return null;
  }
  return buildReturnSuccessDisplayFromReceipt(receipt);
}

List<CompletedItemDisplay> _itemsFromReceipt(ReturnReceipt receipt) {
  final items = <CompletedItemDisplay>[];

  for (final item in receipt.returnedItems) {
    items.add(
      CompletedItemDisplay(
        id: item.saleLineId,
        name: item.name,
        variantLabel: item.variantLabel,
        amount: item.total ?? item.lineAmount,
        imageValue: item.imageStorageKey,
        quantity: item.quantity,
        subtotal: item.subtotal,
        discount: item.discount,
        tax: item.tax,
        reasonDisplay: item.reasonDisplay ?? item.reasonCode,
        conditionDisplay: item.conditionDisplay ?? item.conditionCode,
      ),
    );
  }

  for (final item in receipt.replacementItems) {
    items.add(
      CompletedItemDisplay(
        id: item.saleLineId,
        name: item.name,
        variantLabel: item.variantLabel,
        amount: item.total ?? item.lineAmount,
        imageValue: item.imageStorageKey,
        quantity: item.quantity,
        isReplacement: true,
        subtotal: item.subtotal,
        discount: item.discount,
        tax: item.tax,
      ),
    );
  }

  return items;
}
