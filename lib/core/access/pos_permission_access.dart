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
    PosPermissionCodes.startSale,
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
    PosPermissionCodes.processRefund,
  ];

  static const cashDrawerViewAccessCodes = [
    PosPermissionCodes.viewCashDrawer,
    PosPermissionCodes.viewTill,
    PosPermissionCodes.cashMovement,
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
    return granted.contains(PosPermissionCodes.addCartItem);
  }

  static bool canAddCartItemSession(AuthSession? session) {
    if (session == null) {
      return false;
    }

    return canAddCartItem(session.permissionCodes.toSet());
  }

  static bool canUpdateCartItem(Set<String> granted) {
    return granted.contains(PosPermissionCodes.updateCartItem);
  }

  static bool canUpdateCartItemSession(AuthSession? session) {
    if (session == null) {
      return false;
    }

    return canUpdateCartItem(session.permissionCodes.toSet());
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

  static bool canAcceptPaymentPermission(Set<String> granted, String code) {
    return granted.contains(code);
  }

  /// Payment Method screen access and billing/sale summary inherit checkout.
  static bool canAccessPaymentMethodScreenSession(AuthSession? session) {
    return canCheckoutSession(session);
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
      case PosPermissionCodes.viewNewSale:
        return canAccessNewSale(granted);
      case PosPermissionCodes.viewNewSaleCustomers:
        return hasAny(granted, customerViewAccessCodes);
      case PosPermissionCodes.createNewSaleCustomer:
        return hasAny(granted, customerCreateAccessCodes);
      case PosPermissionCodes.viewReturns:
      case PosPermissionCodes.viewRefunds:
        return canViewReturnsOrRefunds(granted);
      case PosPermissionCodes.viewCashDrawer:
        return canViewCashDrawer(granted);
      case PosPermissionCodes.createParkedSale:
        return canParkOrViewParkedSales(granted);
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
