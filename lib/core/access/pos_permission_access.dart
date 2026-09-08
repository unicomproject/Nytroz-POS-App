import 'package:flutter/material.dart';

import '../../features/auth/domain/entities/auth_session.dart';
import 'effective_permission_set.dart';
import 'pos_access_codes.dart';

/// Permission helpers for POS routes and UI. Canonical codes are defined in
/// [PosPermissionCodes]; legacy seeded aliases are accepted for backward compatibility.
class PosPermissionAccess {
  const PosPermissionAccess._();

  /// Canonical New Sale screen access. Legacy `pos.sale.start` is still accepted.
  static const newSaleAccessCodes = [
    PosPermissionCodes.salesNewSaleView,
    PosPermissionCodes.viewNewSale,
    PosPermissionCodes.createSale,
  ];

  static const homeAccessCodes = [
    PosPermissionCodes.salesDashboardView,
    PosPermissionCodes.viewHome,
    PosPermissionCodes.viewDashboard,
  ];

  static const saleViewAccessCodes = [
    PosPermissionCodes.viewSales,
  ];

  static const receiptViewAccessCodes = [
    PosPermissionCodes.receiptsDigitalView,
    PosPermissionCodes.viewReceipts,
    PosPermissionCodes.printReceipts,
    PosPermissionCodes.receiptsPhysicalPrint,
  ];

  static const receiptPrintAccessCodes = [
    PosPermissionCodes.receiptsPhysicalPrint,
    PosPermissionCodes.printReceipts,
  ];

  static const receiptReprintAccessCodes = [
    PosPermissionCodes.receiptsHistoryReprint,
    PosPermissionCodes.reprintReceipts,
  ];

  /// Shell top-bar child codes (container is separate).
  static const shellTopBarChildCodes = [
    PosPermissionCodes.shellTopbarBrand,
    PosPermissionCodes.shellTopbarSessionStatus,
    PosPermissionCodes.shellTopbarOutlet,
    PosPermissionCodes.shellTopbarTill,
    PosPermissionCodes.shellTopbarConnectivity,
    PosPermissionCodes.shellTopbarClock,
    PosPermissionCodes.shellTopbarNotificationBell,
  ];

  static const customerViewAccessCodes = [
    PosPermissionCodes.viewNewSaleCustomers,
    PosPermissionCodes.viewCustomers,
  ];

  static const customerCreateAccessCodes = [
    PosPermissionCodes.createNewSaleCustomer,
    PosPermissionCodes.createCustomer,
  ];

  static const customerUpdateAccessCodes = [
    PosPermissionCodes.updateNewSaleCustomer,
    PosPermissionCodes.updateCustomer,
  ];

  static const customerViewOrCreateAccessCodes = [
    ...customerViewAccessCodes,
    ...customerCreateAccessCodes,
  ];

  static const returnsViewAccessCodes = [
    PosPermissionCodes.homeActionsReturnsEntry,
    PosPermissionCodes.returnsSearchSaleView,
    PosPermissionCodes.viewReturns,
  ];

  static const refundsViewAccessCodes = [
    PosPermissionCodes.viewRefunds,
  ];

  static const exchangesViewAccessCodes = [
    PosPermissionCodes.viewExchanges,
  ];

  /// Sidebar / module entry: any returns, refunds, or exchanges view right.
  static const returnsModuleAccessCodes = [
    PosPermissionCodes.homeActionsReturnsEntry,
    PosPermissionCodes.returnsSearchSaleView,
    PosPermissionCodes.viewReturns,
    PosPermissionCodes.viewRefunds,
    PosPermissionCodes.viewExchanges,
  ];

  static const returnsCreateAccessCodes = [
    PosPermissionCodes.returnsWorkflowCreate,
    PosPermissionCodes.createReturn,
  ];

  static const refundsCreateAccessCodes = [
    PosPermissionCodes.createRefund,
    PosPermissionCodes.createReturn,
  ];

  static const exchangesCreateAccessCodes = [
    PosPermissionCodes.createExchange,
    PosPermissionCodes.createReturn,
  ];

  static const refundApproveAccessCodes = [
    PosPermissionCodes.approveRefund,
  ];

  static const cashDrawerViewAccessCodes = [
    PosPermissionCodes.cashDrawerPositionView,
    PosPermissionCodes.viewCashDrawer,
  ];

  /// Canonical Parked Sales access: view, create, or recall a backend hold.
  /// Prefer this list — and [canAccessParkedSalesCanonical] — for any new
  /// checks (New Sale actions, Home Parked Sales route).
  static const parkedSaleCanonicalAccessCodes = [
    PosPermissionCodes.heldSalesView,
    PosPermissionCodes.heldSalesCreate,
    PosPermissionCodes.heldSalesRecall,
    PosPermissionCodes.viewBackendParkedSales,
    PosPermissionCodes.createParkedSale,
    PosPermissionCodes.recallBackendParkedSale,
  ];

  /// Legacy aliases retained only for backward compatibility with older
  /// seeded permission sets. Obsolete — do not use as primary for New Sale
  /// or the Home Parked Sales route; prefer [parkedSaleCanonicalAccessCodes].
  static const parkedSaleLegacyAccessCodes = [
    PosPermissionCodes.parkSale,
    PosPermissionCodes.recallSale,
    PosPermissionCodes.viewParkedSales,
  ];

  static const parkedSaleAccessCodes = [
    ...parkedSaleCanonicalAccessCodes,
    ...parkedSaleLegacyAccessCodes,
  ];

  /// Exact membership. Prefer [EffectivePermissionSet] / PermissionGate for new UI.
  /// Alias OR lists below are legacy compatibility only — not parent→child expand.
  static bool hasAny(Set<String> granted, List<String> codes) {
    return EffectivePermissionSet.fromIterable(granted).hasAnyPermission(codes);
  }

  static bool hasAll(Set<String> granted, List<String> codes) {
    return EffectivePermissionSet.fromIterable(granted).hasAllPermissions(codes);
  }

  static bool hasExact(Set<String> granted, String code) {
    return EffectivePermissionSet.fromIterable(granted).hasPermission(code);
  }

  static bool canViewHome(Set<String> granted) {
    return hasAny(granted, homeAccessCodes);
  }

  static bool canViewHomeSession(AuthSession? session) {
    if (session == null) {
      return false;
    }

    return canViewHome(session.permissionCodes.toSet());
  }

  /// New Sale route/sidebar access. Does not require [PosPermissionCodes.viewHome].
  static bool canAccessNewSale(Set<String> granted) {
    return hasAny(granted, newSaleAccessCodes);
  }

  static bool canAccessNewSaleSession(AuthSession? session) {
    if (session == null) {
      return false;
    }

    return canAccessNewSale(session.permissionCodes.toSet());
  }

  static bool canViewProducts(Set<String> granted) {
    return hasAny(granted, [
      PosPermissionCodes.salesCatalogView,
      PosPermissionCodes.viewProducts,
    ]);
  }

  static bool canViewProductsSession(AuthSession? session) {
    if (session == null) {
      return false;
    }

    return canViewProducts(session.permissionCodes.toSet());
  }

  static bool canSearchProducts(Set<String> granted) {
    return hasAny(granted, [
      PosPermissionCodes.salesCatalogSearch,
      PosPermissionCodes.catalogSearchBar,
      PosPermissionCodes.searchProducts,
    ]);
  }

  static bool canAddCartItem(Set<String> granted) {
    return hasAny(granted, [
      PosPermissionCodes.salesCartAddItem,
      PosPermissionCodes.addCartItem,
      PosPermissionCodes.salesCartManage,
      PosPermissionCodes.manageCart,
    ]);
  }

  static bool canAddCartItemSession(AuthSession? session) {
    if (session == null) {
      return false;
    }

    return canAddCartItem(session.permissionCodes.toSet());
  }

  static bool canUpdateCartItem(Set<String> granted) {
    return hasAny(granted, [
      PosPermissionCodes.salesCartUpdateItem,
      PosPermissionCodes.updateCartItem,
      PosPermissionCodes.salesCartManage,
      PosPermissionCodes.manageCart,
    ]);
  }

  static bool canUpdateCartItemSession(AuthSession? session) {
    if (session == null) {
      return false;
    }

    return canUpdateCartItem(session.permissionCodes.toSet());
  }

  static bool canRemoveCartItem(Set<String> granted) {
    return hasAny(granted, [
      PosPermissionCodes.salesCartUpdateItem,
      PosPermissionCodes.removeCartItem,
      PosPermissionCodes.salesCartManage,
      PosPermissionCodes.manageCart,
    ]);
  }

  static bool canClearCart(Set<String> granted) {
    return hasAny(granted, [
      PosPermissionCodes.salesCartClear,
      PosPermissionCodes.clearCart,
      PosPermissionCodes.newSaleChromeClearCartAction,
      PosPermissionCodes.salesCartManage,
      PosPermissionCodes.manageCart,
    ]);
  }

  static bool canViewCustomers(Set<String> granted) {
    return hasAny(granted, customerViewAccessCodes);
  }

  static bool canCreateCustomer(Set<String> granted) {
    return hasAny(granted, customerCreateAccessCodes);
  }

  /// Requires canonical customers.update (legacy pos.customers.update accepted).
  static bool canEditCustomer(Set<String> granted) {
    return hasAny(granted, customerUpdateAccessCodes);
  }

  static bool canAttachCustomerToSale(Set<String> granted) {
    return granted.contains(PosPermissionCodes.customersAttachSale);
  }

  static bool canDeactivateCustomer(Set<String> granted) {
    return granted.contains(PosPermissionCodes.customersDeactivate);
  }

  /// Module entry for Returns & Exchanges (sidebar + shared early steps).
  static bool canViewReturnsOrRefunds(Set<String> granted) {
    return hasAny(granted, returnsModuleAccessCodes);
  }

  static bool canViewReturns(Set<String> granted) {
    return hasAny(granted, returnsViewAccessCodes);
  }

  static bool canCreateReturn(Set<String> granted) {
    return hasAny(granted, returnsCreateAccessCodes);
  }

  static bool canViewRefunds(Set<String> granted) {
    return hasAny(granted, refundsViewAccessCodes);
  }

  static bool canCreateRefund(Set<String> granted) {
    return hasAny(granted, refundsCreateAccessCodes);
  }

  static bool canViewExchanges(Set<String> granted) {
    return hasAny(granted, exchangesViewAccessCodes);
  }

  static bool canCreateExchange(Set<String> granted) {
    return hasAny(granted, exchangesCreateAccessCodes);
  }

  static bool canApproveRefund(Set<String> granted) {
    return hasAny(granted, refundApproveAccessCodes);
  }

  static bool canCompleteRefundBranch(Set<String> granted) {
    return canCreateRefund(granted);
  }

  static bool canCompleteExchangeBranch(Set<String> granted) {
    return canCreateExchange(granted);
  }

  /// Strict Refund branch processing (preview, methods, refund details).
  static bool canProcessRefund(Set<String> granted) {
    return canViewReturns(granted) &&
        canCreateReturn(granted) &&
        granted.contains(PosPermissionCodes.createRefund);
  }

  /// Alias for resolution save on Choose Option.
  static bool canSelectRefundResolution(Set<String> granted) =>
      canProcessRefund(granted);

  /// Strict Exchange branch processing (products, replacement, preview, exchange flow).
  static bool canProcessExchange(Set<String> granted) {
    return canViewReturns(granted) &&
        canCreateReturn(granted) &&
        granted.contains(PosPermissionCodes.createExchange);
  }

  /// Alias for resolution save on Choose Option.
  static bool canSelectExchangeResolution(Set<String> granted) =>
      canProcessExchange(granted);

  /// Immediate Refund success or historical reload with receipts.view.
  static bool canViewRefundSuccess(Set<String> granted) {
    return canProcessRefund(granted) ||
        (canViewReturns(granted) &&
            granted.contains(PosPermissionCodes.viewReceipts));
  }

  /// Immediate Exchange success or historical reload with receipts.view.
  static bool canViewExchangeSuccess(Set<String> granted) {
    return canProcessExchange(granted) ||
        (canViewReturns(granted) &&
            granted.contains(PosPermissionCodes.viewReceipts));
  }

  /// Route entry for Step 10 before branch resolution is known.
  static bool canAccessReturnSuccessRoute(Set<String> granted) {
    return canProcessRefund(granted) ||
        canProcessExchange(granted) ||
        (canViewReturns(granted) &&
            granted.contains(PosPermissionCodes.viewReceipts));
  }

  static bool canStartNewReturn(Set<String> granted) {
    return canViewReturns(granted) && canCreateReturn(granted);
  }

  static bool canViewCashDrawer(Set<String> granted) {
    return hasAny(granted, [
      PosPermissionCodes.cashDrawerPositionView,
      PosPermissionCodes.viewCashDrawer,
    ]);
  }

  /// Online Order queue/detail access requires the frozen feature pair from
  /// Permission_Code_List: `orders.access` AND `orders.view`. Neither alone
  /// is sufficient; workflow children (fulfilment/picking/packing) are separate.
  static bool canViewOnlineOrders(Set<String> granted) {
    return granted.contains(PosPermissionCodes.accessOnlineOrders) &&
        granted.contains(PosPermissionCodes.viewOnlineOrders);
  }

  static bool canViewOnlineOrdersSession(AuthSession? session) {
    if (session == null) return false;
    return canViewOnlineOrders(session.permissionCodes.toSet());
  }

  static bool canViewOnlineOrderPicking(Set<String> granted) {
    return canViewOnlineOrders(granted) &&
        granted.contains(PosPermissionCodes.viewOnlineOrderPicking);
  }

  static bool canViewOnlineOrderPacking(Set<String> granted) {
    return canViewOnlineOrderPicking(granted) &&
        granted.contains(PosPermissionCodes.viewOnlineOrderPacking);
  }

  /// Legacy broad movement.create — prefer [canCashIn]/[canCashOut]/[canCashDrop].
  static bool canCreateCashDrawerMovement(Set<String> granted) {
    return canCashIn(granted) || canCashOut(granted) || canCashDrop(granted);
  }

  static bool canCashIn(Set<String> granted) {
    return hasAny(granted, [
      PosPermissionCodes.cashDrawerCashIn,
      PosPermissionCodes.createCashDrawerMovement,
    ]);
  }

  static bool canCashOut(Set<String> granted) {
    return hasAny(granted, [
      PosPermissionCodes.cashDrawerCashOut,
      PosPermissionCodes.createCashDrawerMovement,
    ]);
  }

  static bool canCashDrop(Set<String> granted) {
    return hasAny(granted, [
      PosPermissionCodes.cashDrawerCashDrop,
      PosPermissionCodes.createCashDrawerMovement,
    ]);
  }

  static bool canManageCashDrawerPhysical(Set<String> granted) {
    return hasAny(granted, [
      PosPermissionCodes.cashDrawerPhysicalManage,
      PosPermissionCodes.manageCashDrawer,
    ]);
  }

  /// @Deprecated Prefer [canManageCashDrawerPhysical].
  static bool canManageCashDrawerActions(Set<String> granted) {
    return canManageCashDrawerPhysical(granted);
  }

  static bool canOpenTill(Set<String> granted) {
    return hasAny(granted, [
      PosPermissionCodes.tillSessionOpen,
      PosPermissionCodes.openTill,
    ]);
  }

  static bool canCloseTill(Set<String> granted) {
    return hasAny(granted, [
      PosPermissionCodes.tillSessionClose,
      PosPermissionCodes.closeTill,
    ]);
  }

  static bool canParkOrViewParkedSales(Set<String> granted) {
    return hasAny(granted, parkedSaleAccessCodes);
  }

  /// Canonical-only Parked Sales access (no legacy `pos.sale.park*`
  /// fallback). Used by the Home Parked Sales route guard.
  static bool canAccessParkedSalesCanonical(Set<String> granted) {
    return hasAny(granted, parkedSaleCanonicalAccessCodes);
  }

  static bool canCheckout(Set<String> granted) {
    return hasAny(granted, [
      PosPermissionCodes.salesCheckoutExecute,
      PosPermissionCodes.checkoutSale,
      PosPermissionCodes.newSaleChromeCheckoutAction,
    ]);
  }

  static bool canCheckoutSession(AuthSession? session) {
    if (session == null) {
      return false;
    }

    return canCheckout(session.permissionCodes.toSet());
  }

  static bool canAcceptCashPayment(Set<String> granted) {
    return canAcceptPaymentPermission(
      granted,
      PosPermissionCodes.acceptCashPayment,
    );
  }

  static bool canAcceptCardPayment(Set<String> granted) {
    return canAcceptPaymentPermission(
      granted,
      PosPermissionCodes.acceptCardPayment,
    );
  }

  static bool canAcceptQrPayment(Set<String> granted) {
    return canAcceptPaymentPermission(
      granted,
      PosPermissionCodes.acceptQrPayment,
    );
  }

  static bool canAcceptSplitPayment(Set<String> granted) {
    return canAcceptPaymentPermission(
      granted,
      PosPermissionCodes.acceptSplitPayment,
    );
  }

  static bool canAcceptPaymentPermission(Set<String> granted, String code) {
    return granted.contains(code);
  }

  /// Payment Method screen access and billing/sale summary inherit checkout.
  static bool canAccessPaymentMethodScreenSession(AuthSession? session) {
    return canCheckoutSession(session);
  }

  static bool canAccessCashPaymentScreenSession(AuthSession? session) {
    if (session == null) {
      return false;
    }

    final granted = session.permissionCodes.toSet();
    return canCheckout(granted) && canAcceptCashPayment(granted);
  }

  static bool canAccessCardPaymentScreenSession(AuthSession? session) {
    if (session == null) {
      return false;
    }

    final granted = session.permissionCodes.toSet();
    return canCheckout(granted) && canAcceptCardPayment(granted);
  }

  static bool canAccessQrPaymentScreenSession(AuthSession? session) {
    if (session == null) {
      return false;
    }

    final granted = session.permissionCodes.toSet();
    return canCheckout(granted) && canAcceptQrPayment(granted);
  }

  static bool canAccessSplitPaymentScreenSession(AuthSession? session) {
    if (session == null) {
      return false;
    }

    final granted = session.permissionCodes.toSet();
    return canCheckout(granted) && canAcceptSplitPayment(granted);
  }

  static bool canViewSales(Set<String> granted) {
    return hasAny(granted, saleViewAccessCodes);
  }

  static bool canViewReceipts(Set<String> granted) {
    return hasAny(granted, receiptViewAccessCodes);
  }

  static bool canPrintReceipts(Set<String> granted) {
    return hasAny(granted, receiptPrintAccessCodes);
  }

  static bool canReprintReceipts(Set<String> granted) {
    return hasAny(granted, receiptReprintAccessCodes);
  }

  static bool canReprintReceiptsSession(AuthSession? session) {
    if (session == null) {
      return false;
    }
    return canReprintReceipts(session.permissionCodes.toSet());
  }

  static bool canViewPaymentSuccessSession(AuthSession? session) {
    if (session == null) {
      return false;
    }

    final granted = session.permissionCodes.toSet();
    return canViewSales(granted) || canViewReceipts(granted);
  }

  static bool canViewReceiptSession(AuthSession? session) {
    if (session == null) {
      return false;
    }

    return canViewReceipts(session.permissionCodes.toSet());
  }

  static bool canPrintReceiptsSession(AuthSession? session) {
    if (session == null) {
      return false;
    }

    return canPrintReceipts(session.permissionCodes.toSet());
  }

  /// Continue requires checkout plus the selected payment method permission.
  static bool canContinueWithPaymentPermission(
    Set<String> granted,
    String? paymentPermissionCode,
  ) {
    if (paymentPermissionCode == null || paymentPermissionCode.isEmpty) {
      return false;
    }

    return canCheckout(granted) &&
        canAcceptPaymentPermission(granted, paymentPermissionCode);
  }

  /// Home dashboard and nav visibility for a canonical permission key.
  static bool grantsCanonicalPermission(
    Set<String> granted,
    String canonicalPermissionKey,
  ) {
    switch (canonicalPermissionKey) {
      case PosPermissionCodes.viewHome:
      case PosPermissionCodes.viewDashboard:
      case PosPermissionCodes.salesDashboardView:
        return canViewHome(granted);
      case PosPermissionCodes.viewNewSale:
      case PosPermissionCodes.createSale:
      case PosPermissionCodes.salesNewSaleView:
      case PosPermissionCodes.salesNewSaleCreate:
        return canAccessNewSale(granted);
      case PosPermissionCodes.addCartItem:
      case PosPermissionCodes.updateCartItem:
      case PosPermissionCodes.removeCartItem:
      case PosPermissionCodes.clearCart:
      case PosPermissionCodes.manageCart:
      case PosPermissionCodes.salesCartAddItem:
      case PosPermissionCodes.salesCartUpdateItem:
      case PosPermissionCodes.salesCartClear:
      case PosPermissionCodes.salesCartManage:
        return canAddCartItem(granted) ||
            canUpdateCartItem(granted) ||
            canClearCart(granted);
      case PosPermissionCodes.viewNewSaleCustomers:
        return hasAny(granted, customerViewAccessCodes);
      case PosPermissionCodes.createNewSaleCustomer:
        return hasAny(granted, customerCreateAccessCodes);
      case PosPermissionCodes.updateNewSaleCustomer:
        return hasAny(granted, customerUpdateAccessCodes);
      case PosPermissionCodes.viewReturns:
      case PosPermissionCodes.returnsSearchSaleView:
        return canViewReturns(granted);
      case PosPermissionCodes.homeActionsReturnsEntry:
        return granted.contains(PosPermissionCodes.homeActionsReturnsEntry);
      case PosPermissionCodes.createReturn:
        return canCreateReturn(granted);
      case PosPermissionCodes.viewRefunds:
        return canViewRefunds(granted);
      case PosPermissionCodes.createRefund:
        return canCreateRefund(granted);
      case PosPermissionCodes.viewExchanges:
        return canViewExchanges(granted);
      case PosPermissionCodes.createExchange:
        return canCreateExchange(granted);
      case PosPermissionCodes.approveRefund:
        return canApproveRefund(granted);
      case PosPermissionCodes.viewCashDrawer:
      case PosPermissionCodes.manageCashDrawer:
      case PosPermissionCodes.cashDrawerPositionView:
        return canViewCashDrawer(granted);
      case PosPermissionCodes.createParkedSale:
      case PosPermissionCodes.heldSalesCreate:
      case PosPermissionCodes.heldSalesView:
      case PosPermissionCodes.viewBackendParkedSales:
        return canParkOrViewParkedSales(granted);
      case PosPermissionCodes.heldSalesRecall:
      case PosPermissionCodes.recallBackendParkedSale:
        return hasAny(granted, [
          PosPermissionCodes.heldSalesRecall,
          PosPermissionCodes.recallBackendParkedSale,
          PosPermissionCodes.recallSale,
        ]);
      case PosPermissionCodes.heldSalesCancel:
        return granted.contains(PosPermissionCodes.heldSalesCancel);
      case PosPermissionCodes.homeActionsOnlineOrdersEntry:
        return granted
            .contains(PosPermissionCodes.homeActionsOnlineOrdersEntry);
      case PosPermissionCodes.closeTill:
      case PosPermissionCodes.tillSessionClose:
        return canCloseTill(granted);
      case PosPermissionCodes.viewSales:
        return canViewSales(granted);
      case PosPermissionCodes.viewReceipts:
      case PosPermissionCodes.receiptsDigitalView:
        return canViewReceipts(granted);
      case PosPermissionCodes.printReceipts:
      case PosPermissionCodes.receiptsPhysicalPrint:
        return canPrintReceipts(granted);
      case PosPermissionCodes.reprintReceipts:
      case PosPermissionCodes.receiptsHistoryReprint:
        return canReprintReceipts(granted);
      default:
        return granted.contains(canonicalPermissionKey);
    }
  }

  static void showAccessDeniedSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
