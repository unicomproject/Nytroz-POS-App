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
    PosPermissionCodes.startSale,
    'pos.sale.create',
  ];

  static const homeAccessCodes = [
    PosPermissionCodes.viewHome,
    PosPermissionCodes.viewDashboard,
    'pos.sale.create',
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

  static const customerViewOrCreateAccessCodes = [
    ...customerViewAccessCodes,
    ...customerCreateAccessCodes,
  ];

  static const returnsViewAccessCodes = [
    PosPermissionCodes.viewReturns,
    PosPermissionCodes.viewRefunds,
    PosPermissionCodes.createRefund,
    PosPermissionCodes.processRefund,
  ];

  static const cashDrawerViewAccessCodes = [
    PosPermissionCodes.viewCashDrawer,
    PosPermissionCodes.manageCashDrawer,
    PosPermissionCodes.viewTill,
    PosPermissionCodes.cashMovement,
    PosPermissionCodes.openTill,
    PosPermissionCodes.closeTill,
    'pos.till.open',
    'pos.till.close',
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
    return hasAny(granted, customerViewOrCreateAccessCodes);
  }

  static bool canViewReturnsOrRefunds(Set<String> granted) {
    return hasAny(granted, returnsViewAccessCodes);
  }

  static bool canViewCashDrawer(Set<String> granted) {
    return hasAny(granted, cashDrawerViewAccessCodes);
  }

  static bool canCreateCashDrawerMovement(Set<String> granted) {
    return granted.contains(PosPermissionCodes.createCashDrawerMovement) ||
        granted.contains(PosPermissionCodes.cashMovement) ||
        granted.contains(PosPermissionCodes.manageCashDrawer);
  }

  static bool canManageCashDrawerActions(Set<String> granted) {
    return granted.contains(PosPermissionCodes.manageCashDrawer) ||
        canCreateCashDrawerMovement(granted);
  }

  static bool canCloseTill(Set<String> granted) {
    return granted.contains(PosPermissionCodes.closeTill) ||
        granted.contains(PosPermissionCodes.manageCashDrawer);
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
      case PosPermissionCodes.viewReturns:
      case PosPermissionCodes.viewRefunds:
      case PosPermissionCodes.createRefund:
        return canViewReturnsOrRefunds(granted);
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
