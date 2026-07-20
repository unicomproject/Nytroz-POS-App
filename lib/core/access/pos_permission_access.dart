import 'package:flutter/material.dart';

import '../../features/auth/domain/entities/auth_session.dart';
import 'pos_access_codes.dart';

/// Permission helpers for POS routes and UI. Canonical codes are defined in
/// [PosPermissionCodes]; legacy seeded aliases are accepted for backward compatibility.
class PosPermissionAccess {
  const PosPermissionAccess._();

  /// Canonical New Sale screen access. Legacy `pos.sale.start` is still accepted.
  static const newSaleAccessCodes = [
    PosPermissionCodes.viewNewSale,
    PosPermissionCodes.createSale,
  ];

  static const homeAccessCodes = [
    PosPermissionCodes.viewHome,
    PosPermissionCodes.viewDashboard,
  ];

  static const saleViewAccessCodes = [
    PosPermissionCodes.viewSales,
  ];

  static const receiptViewAccessCodes = [
    PosPermissionCodes.viewReceipts,
    PosPermissionCodes.printReceipts,
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
    PosPermissionCodes.viewReturns,
    PosPermissionCodes.viewRefunds,
    PosPermissionCodes.viewExchanges,
  ];

  static const returnsCreateAccessCodes = [
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
    PosPermissionCodes.viewCashDrawer,
  ];

  static const parkedSaleAccessCodes = [
    PosPermissionCodes.createParkedSale,
    PosPermissionCodes.parkSale,
    PosPermissionCodes.recallSale,
    PosPermissionCodes.viewParkedSales,
  ];

  static bool hasAny(Set<String> granted, List<String> codes) {
    return codes.any(granted.contains);
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
    return granted.contains(PosPermissionCodes.viewProducts);
  }

  static bool canViewProductsSession(AuthSession? session) {
    if (session == null) {
      return false;
    }

    return canViewProducts(session.permissionCodes.toSet());
  }

  static bool canSearchProducts(Set<String> granted) {
    return granted.contains(PosPermissionCodes.searchProducts);
  }

  static bool canAddCartItem(Set<String> granted) {
    return granted.contains(PosPermissionCodes.addCartItem) ||
        granted.contains(PosPermissionCodes.manageCart);
  }

  static bool canAddCartItemSession(AuthSession? session) {
    if (session == null) {
      return false;
    }

    return canAddCartItem(session.permissionCodes.toSet());
  }

  static bool canUpdateCartItem(Set<String> granted) {
    return granted.contains(PosPermissionCodes.updateCartItem) ||
        granted.contains(PosPermissionCodes.manageCart);
  }

  static bool canUpdateCartItemSession(AuthSession? session) {
    if (session == null) {
      return false;
    }

    return canUpdateCartItem(session.permissionCodes.toSet());
  }

  static bool canRemoveCartItem(Set<String> granted) {
    return granted.contains(PosPermissionCodes.removeCartItem) ||
        granted.contains(PosPermissionCodes.manageCart);
  }

  static bool canClearCart(Set<String> granted) {
    return granted.contains(PosPermissionCodes.clearCart) ||
        granted.contains(PosPermissionCodes.manageCart);
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
    return canViewCustomers(granted) &&
        granted.contains(PosPermissionCodes.manageCart);
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
    return granted.contains(PosPermissionCodes.viewCashDrawer);
  }

  static bool canCreateCashDrawerMovement(Set<String> granted) {
    return granted.contains(PosPermissionCodes.manageCashDrawer);
  }

  static bool canManageCashDrawerActions(Set<String> granted) {
    return granted.contains(PosPermissionCodes.manageCashDrawer);
  }

  static bool canCloseTill(Set<String> granted) {
    return granted.contains(PosPermissionCodes.closeTill);
  }

  static bool canParkOrViewParkedSales(Set<String> granted) {
    return hasAny(granted, parkedSaleAccessCodes);
  }

  static bool canCheckout(Set<String> granted) {
    return granted.contains(PosPermissionCodes.checkoutSale);
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
    return granted.contains(PosPermissionCodes.printReceipts);
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
        return canViewHome(granted);
      case PosPermissionCodes.viewNewSale:
      case PosPermissionCodes.createSale:
        return canAccessNewSale(granted);
      case PosPermissionCodes.addCartItem:
      case PosPermissionCodes.updateCartItem:
      case PosPermissionCodes.removeCartItem:
      case PosPermissionCodes.clearCart:
      case PosPermissionCodes.manageCart:
        return granted.contains(PosPermissionCodes.manageCart) ||
            granted.contains(canonicalPermissionKey);
      case PosPermissionCodes.viewNewSaleCustomers:
        return hasAny(granted, customerViewAccessCodes);
      case PosPermissionCodes.createNewSaleCustomer:
        return hasAny(granted, customerCreateAccessCodes);
      case PosPermissionCodes.updateNewSaleCustomer:
        return hasAny(granted, customerUpdateAccessCodes);
      case PosPermissionCodes.viewReturns:
        return canViewReturns(granted);
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
        return canViewCashDrawer(granted);
      case PosPermissionCodes.createParkedSale:
        return canParkOrViewParkedSales(granted);
      case PosPermissionCodes.viewSales:
        return canViewSales(granted);
      case PosPermissionCodes.viewReceipts:
        return canViewReceipts(granted);
      case PosPermissionCodes.printReceipts:
        return canPrintReceipts(granted);
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
