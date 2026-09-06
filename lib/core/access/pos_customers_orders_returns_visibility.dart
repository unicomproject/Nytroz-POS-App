import 'effective_permission_set.dart';
import 'pos_access_codes.dart';
import 'pos_permission_access.dart';

/// Chunk 12 Customers / Receipt-History / Online-Orders / Returns visibility
/// (exact membership only — no parent inference).
class PosCustomersOrdersReturnsVisibility {
  const PosCustomersOrdersReturnsVisibility._();

  // --- Customers ---
  static bool canViewCustomers(EffectivePermissionSet p) =>
      PosPermissionAccess.canViewCustomers(p.codes.toSet());

  static bool canCreateCustomer(EffectivePermissionSet p) =>
      PosPermissionAccess.canCreateCustomer(p.codes.toSet());

  static bool canUpdateCustomer(EffectivePermissionSet p) =>
      PosPermissionAccess.canEditCustomer(p.codes.toSet());

  static bool canAttachCustomerToSale(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.customersAttachSale);

  static bool canDeactivateCustomer(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.customersDeactivate);

  static bool canShowCustomerSearch(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.customersListSearch);

  static bool canShowCustomerFilters(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.customersListFilters);

  static bool canShowCustomerId(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.customersListId);

  static bool canShowCustomerName(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.customersListName);

  static bool canShowCustomerPhone(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.customersListPhone);

  static bool canShowCustomerEmail(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.customersListEmail);

  static bool canShowCustomerSource(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.customersListSource);

  static bool canShowCustomerStatus(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.customersListStatus);

  static bool canShowCustomerOrderCount(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.customersListOrderCount);

  static bool canShowCustomerTotalSpend(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.customersListTotalSpend);

  static bool canShowCustomerPagination(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.customersListPagination);

  static bool canShowCustomerJoinedDate(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.customersDetailsJoinedDate);

  static bool canShowCustomerAov(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.customersDetailsAverageOrderValue);

  static bool canShowRecentPurchases(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.customersHistoryRecentPurchases);

  static bool canShowPurchaseAmounts(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.customersHistoryPurchaseAmounts);

  static bool canShowPurchaseHistory(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.customersHistoryPurchaseHistory);

  // --- Receipt / transaction history (`/pos/orders`) ---
  static bool canViewReceiptHistory(EffectivePermissionSet p) =>
      PosPermissionAccess.canViewReceipts(p.codes.toSet());

  static bool canShowHistoryReceiptNumber(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsReceiptNumber);

  static bool canShowHistoryDatetime(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsDatetime);

  static bool canShowHistoryCustomer(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsCustomer);

  static bool canShowHistoryStore(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsStore);

  static bool canShowHistoryCashier(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsCashier);

  static bool canShowHistoryTerminal(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsTerminal);

  static bool canShowHistoryPaymentMethod(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsPaymentMethod);

  static bool canShowHistoryTotal(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsTotal);

  static bool canShowHistorySubtotal(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsSubtotal);

  static bool canShowHistoryDiscount(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsDiscount);

  static bool canShowHistoryPaidAmount(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsPaidAmount);

  static bool canShowHistoryChangeDue(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsChangeDue);

  static bool canShowHistoryItems(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsItems);

  static bool canShowHistoryItemQuantity(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsItemQuantity);

  static bool canShowHistoryItemRate(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsItemRate);

  static bool canShowHistoryItemValue(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.receiptsDetailsItemValue);

  static bool canPrintReceipt(EffectivePermissionSet p) =>
      PosPermissionAccess.canPrintReceipts(p.codes.toSet());

  static bool canReprintReceipt(EffectivePermissionSet p) =>
      PosPermissionAccess.canReprintReceipts(p.codes.toSet());

  // --- Online orders ---
  static bool canAccessOnlineOrders(EffectivePermissionSet p) =>
      PosPermissionAccess.canViewOnlineOrders(p.codes.toSet());

  static bool canStartOnlineFulfilment(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.startOnlineOrderFulfillment);

  static bool canViewOnlinePicking(EffectivePermissionSet p) =>
      PosPermissionAccess.canViewOnlineOrderPicking(p.codes.toSet());

  static bool canPickOnlineItem(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.pickOnlineOrderItem);

  static bool canPackOnlineOrder(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.packOnlineOrder);

  static bool canMarkOnlineReady(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.markOnlineOrderReady);

  // --- Returns ---
  static bool canViewReturnsSearch(EffectivePermissionSet p) =>
      PosPermissionAccess.canViewReturns(p.codes.toSet());

  static bool canCreateReturnWorkflow(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.returnsWorkflowCreate) ||
      PosPermissionAccess.canCreateReturn(p.codes.toSet());

  static bool canApproveRefund(EffectivePermissionSet p) =>
      PosPermissionAccess.canApproveRefund(p.codes.toSet());
}