import '../../features/sale/domain/entities/pos_payment_method_type.dart';
import 'effective_permission_set.dart';
import 'pos_access_codes.dart';
import 'pos_permission_access.dart';

/// Shared Chunk 11 Payment / Cash / Completion / Receipt visibility
/// (exact membership only — no parent inference).
class PosPaymentPermissionVisibility {
  const PosPaymentPermissionVisibility._();

  // --- Payment method business accept (independent) ---
  static bool canAcceptCash(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.acceptCashPayment);

  static bool canAcceptCard(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.acceptCardPayment);

  static bool canAcceptQr(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.acceptQrPayment);

  static bool canAcceptSplit(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.acceptSplitPayment);

  static bool canShowMethodsContainer(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.checkoutMethodsContainer) ||
      PosPermissionAccess.canCheckout(p.codes.toSet());

  /// Method tile visibility uses business accept codes (not parent expansion).
  static bool canShowMethod(
    EffectivePermissionSet p,
    PosPaymentMethodType method,
  ) {
    return switch (method) {
      PosPaymentMethodType.cash => canAcceptCash(p),
      PosPaymentMethodType.card => canAcceptCard(p),
      PosPaymentMethodType.qrMobile => canAcceptQr(p),
      PosPaymentMethodType.split => canAcceptSplit(p),
    };
  }

  static List<PosPaymentMethodType> visiblePaymentMethods(
    EffectivePermissionSet p,
  ) {
    return PosPaymentMethodType.values
        .where((m) => canShowMethod(p, m))
        .toList(growable: false);
  }

  // --- Checkout summary (payment method screen) ---
  static bool canShowCheckoutSummaryItems(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.checkoutSummaryItems);

  static bool canShowCheckoutSummaryQuantity(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.checkoutSummaryQuantity);

  static bool canShowCheckoutSummaryPrice(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.checkoutSummaryPrice);

  static bool canShowCheckoutSummaryLineTotal(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.checkoutSummaryLineTotal);

  static bool canShowCheckoutSummarySubtotal(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.checkoutSummarySubtotal);

  static bool canShowCheckoutSummaryDiscount(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.checkoutSummaryDiscount);

  static bool canShowCheckoutSummaryTax(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.checkoutSummaryTax);

  static bool canShowCheckoutSummaryTotal(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.checkoutSummaryTotal);

  static bool canShowCheckoutCustomerSummary(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.checkoutCustomerSummary);

  // --- Cash summary / lines ---
  static bool canShowCashSummaryOrder(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashPaymentSummaryOrder);

  static bool canShowCashLineItem(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashPaymentLineItem);

  static bool canShowCashLineQuantity(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashPaymentLineQuantity);

  static bool canShowCashLinePrice(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashPaymentLinePrice);

  static bool canShowCashLineItemTotal(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashPaymentLineItemTotal);

  static bool canShowCashSummarySubtotal(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashPaymentSummarySubtotal);

  static bool canShowCashSummaryDiscount(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashPaymentSummaryDiscount);

  static bool canShowCashSummaryTax(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashPaymentSummaryTax);

  static bool canShowCashSummaryTotalDue(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashPaymentSummaryTotalDue);

  // --- Cash tender ---
  static bool canShowCashAmountReceivedView(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashPaymentTenderAmountReceivedView);

  static bool canEnterCashAmountReceived(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashPaymentTenderAmountReceivedEntry);

  static bool canShowCashDueAmount(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashPaymentTenderDueAmount);

  static bool canShowExactCash(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashPaymentTenderExact);

  static bool canShowCashChangeDue(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashPaymentTenderChangeDue);

  static bool canShowQuickAmountsContainer(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashPaymentQuickAmountsContainer);

  static bool canShowQuickAmountSlot1(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashPaymentQuickAmountsSlot1);

  static bool canShowQuickAmountSlot2(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashPaymentQuickAmountsSlot2);

  static bool canShowQuickAmountSlot3(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashPaymentQuickAmountsSlot3);

  static bool canShowNumpadContainer(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashPaymentNumpadContainer);

  static bool canShowNumpadDigit(EffectivePermissionSet p, String digit) {
    return switch (digit) {
      '0' => p.hasPermission(PosPermissionCodes.cashPaymentNumpadDigit0),
      '1' => p.hasPermission(PosPermissionCodes.cashPaymentNumpadDigit1),
      '2' => p.hasPermission(PosPermissionCodes.cashPaymentNumpadDigit2),
      '3' => p.hasPermission(PosPermissionCodes.cashPaymentNumpadDigit3),
      '4' => p.hasPermission(PosPermissionCodes.cashPaymentNumpadDigit4),
      '5' => p.hasPermission(PosPermissionCodes.cashPaymentNumpadDigit5),
      '6' => p.hasPermission(PosPermissionCodes.cashPaymentNumpadDigit6),
      '7' => p.hasPermission(PosPermissionCodes.cashPaymentNumpadDigit7),
      '8' => p.hasPermission(PosPermissionCodes.cashPaymentNumpadDigit8),
      '9' => p.hasPermission(PosPermissionCodes.cashPaymentNumpadDigit9),
      '00' => p.hasPermission(PosPermissionCodes.cashPaymentNumpadDigit00),
      '.' => p.hasPermission(PosPermissionCodes.cashPaymentNumpadDecimal),
      _ => false,
    };
  }

  static bool canShowNumpadBackspace(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashPaymentControlsBackspace);

  static bool canShowNumpadClear(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cashPaymentControlsClear);

  static bool canCompleteCashSale(EffectivePermissionSet p) =>
      canAcceptCash(p) &&
      p.hasPermission(PosPermissionCodes.cashPaymentCompletionExecute);

  /// Filters generated quick amounts: exact uses tender.exact; remaining
  /// non-exact values map to slot_1..slot_3 in catalog order.
  static List<int> filterQuickAmounts(
    EffectivePermissionSet p, {
    required List<int> amounts,
    required int exactAmount,
  }) {
    if (!canShowQuickAmountsContainer(p)) {
      return const [];
    }
    final slots = <bool>[
      canShowQuickAmountSlot1(p),
      canShowQuickAmountSlot2(p),
      canShowQuickAmountSlot3(p),
    ];
    var slotIndex = 0;
    final visible = <int>[];
    for (final amount in amounts) {
      if (amount == exactAmount) {
        if (canShowExactCash(p)) {
          visible.add(amount);
        }
        continue;
      }
      if (slotIndex < slots.length && slots[slotIndex]) {
        visible.add(amount);
      }
      slotIndex++;
    }
    return visible;
  }

  // --- Sale complete ---
  static bool canShowSaleCompleteSuccessMessage(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.saleCompleteMessageSuccess);

  static bool canShowSaleCompleteReceiptNumber(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.saleCompleteDetailsReceiptNumber);

  static bool canShowSaleCompletePaymentMethod(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.saleCompleteDetailsPaymentMethod);

  static bool canShowSaleCompleteDatetime(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.saleCompleteDetailsDatetime);

  static bool canShowSaleCompleteCashier(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.saleCompleteDetailsCashier);

  static bool canShowSaleCompleteCustomer(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.saleCompleteDetailsCustomer);

  static bool canShowSaleCompleteCashReceived(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.saleCompleteDetailsCashReceived);

  static bool canShowSaleCompleteChangeDue(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.saleCompleteDetailsChangeDue);

  static bool canShowSaleCompleteTotalPaid(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.saleCompleteDetailsTotalPaid);

  static bool canPrintPhysicalReceipt(EffectivePermissionSet p) =>
      PosPermissionAccess.canPrintReceipts(p.codes.toSet());

  static bool canReprintReceipt(EffectivePermissionSet p) =>
      PosPermissionAccess.canReprintReceipts(p.codes.toSet());

  static bool canStartNewSaleFromSuccess(EffectivePermissionSet p) =>
      PosPermissionAccess.canAccessNewSale(p.codes.toSet());

  // --- Receipt preview details ---
  static bool canShowReceiptStore(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsStore);

  static bool canShowReceiptNumber(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsReceiptNumber);

  static bool canShowReceiptDatetime(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsDatetime);

  static bool canShowReceiptCashier(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsCashier);

  static bool canShowReceiptCustomer(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsCustomer);

  static bool canShowReceiptTerminal(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsTerminal);

  static bool canShowReceiptPaymentMethod(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsPaymentMethod);

  static bool canShowReceiptItems(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsItems);

  static bool canShowReceiptItemQuantity(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsItemQuantity);

  static bool canShowReceiptItemValue(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsItemValue);

  static bool canShowReceiptItemRate(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsItemRate);

  static bool canShowReceiptSubtotal(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsSubtotal);

  static bool canShowReceiptDiscount(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsDiscount);

  static bool canShowReceiptTotal(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsTotal);

  static bool canShowReceiptPaidAmount(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsPaidAmount);

  static bool canShowReceiptChangeDue(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsChangeDue);
}

/// Which summary permission family applies to the shared sale-summary column.
enum PaymentSummaryPermissionSurface {
  checkout,
  cash,
}
