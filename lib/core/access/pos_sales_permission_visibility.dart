import '../../core/access/effective_permission_set.dart';
import '../../core/access/pos_access_codes.dart';
import '../../core/access/pos_permission_access.dart';

/// Shared Chunk 10 Sales visibility checks (exact membership only).
class PosSalesPermissionVisibility {
  const PosSalesPermissionVisibility._();

  // --- Product detail ---
  static bool canViewProductDetail(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.catalogProductDetailView) ||
      PosPermissionAccess.canViewProducts(p.codes.toSet());

  static bool canShowDetailClose(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.catalogProductDetailClose);

  static bool canShowDetailCancel(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.catalogProductDetailCancel);

  static bool canShowDetailImage(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.catalogProductDetailImage);

  static bool canShowDetailName(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.catalogProductDetailName);

  static bool canShowDetailPrice(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.catalogProductDetailPrice);

  static bool canShowDetailStock(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.catalogProductDetailStock);

  static bool canShowDetailSku(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.catalogProductDetailSku);

  static bool canShowDetailDescription(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.catalogProductDetailDescription);

  static bool canShowDetailVariants(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.catalogProductDetailVariants);

  static bool canSelectDetailVariant(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.catalogProductDetailVariantSelect);

  static bool canShowDetailAvailableQty(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.catalogProductDetailAvailableQty);

  static bool canShowDetailQuantity(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.catalogProductDetailQuantityDisplay);

  static bool canShowDetailNoteView(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.catalogProductDetailNoteView);

  static bool canEditDetailNote(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.catalogProductDetailNoteEntry);

  static bool canShowDetailRecommendations(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.catalogProductDetailRecommendations);

  /// Qty +/- have no independent catalog codes; visibility follows quantity_display.
  /// Mutation authority remains cart add/update on submit.
  static bool canMutateDetailQuantity(EffectivePermissionSet p) =>
      canShowDetailQuantity(p);

  // --- Cart ---
  static bool canShowCartSummary(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cartSummaryView) ||
      PosPermissionAccess.hasAny(p.codes.toSet(), [
        PosPermissionCodes.salesCartManage,
        PosPermissionCodes.manageCart,
      ]);

  static bool canShowCartItemCount(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cartSummaryItemCount);

  static bool canShowCartSubtotal(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cartSummarySubtotal);

  static bool canShowCartDiscount(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cartSummaryDiscount);

  static bool canShowCartTax(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cartSummaryTax);

  static bool canShowCartTotal(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cartSummaryTotal);

  static bool canShowCartLines(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cartLinesList) ||
      PosPermissionAccess.hasAny(p.codes.toSet(), [
        PosPermissionCodes.salesCartManage,
        PosPermissionCodes.manageCart,
      ]);

  static bool canShowCartLineName(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cartLinesName);

  static bool canShowCartLineQuantity(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cartLinesQuantity);

  static bool canShowCartLineUnitPrice(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cartLinesUnitPrice);

  static bool canShowCartLineTotal(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cartLinesLineTotal);

  static bool canShowCartLineNote(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cartLinesNote);

  static bool canShowCartLineImage(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.cartLinesImage);

  static bool canShowEmptyCartMessage(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.newSaleChromeEmptyCart);

  static bool canShowCheckoutAction(EffectivePermissionSet p) =>
      PosPermissionAccess.canCheckout(p.codes.toSet());

  static bool canShowCartHeader(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.newSaleChromeHeader) ||
      canShowCartSummary(p) ||
      canShowCartLines(p);

  // --- Park popup ---
  static bool canShowParkPopup(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.heldSalesPopupView) ||
      PosPermissionAccess.hasAny(p.codes.toSet(), [
        PosPermissionCodes.heldSalesCreate,
        PosPermissionCodes.createParkedSale,
      ]);

  static bool canShowParkReference(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.heldSalesPopupReference);

  static bool canShowParkNote(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.heldSalesPopupNote);

  static bool canShowParkExpiry(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.heldSalesPopupExpiry);

  static bool canConfirmPark(EffectivePermissionSet p) =>
      PosPermissionAccess.hasAny(p.codes.toSet(), [
        PosPermissionCodes.heldSalesCreate,
        PosPermissionCodes.createParkedSale,
      ]);

  // --- Held list ---
  static bool canShowHeldFilters(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.heldSalesListFilters);

  static bool canShowHeldActiveCount(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.heldSalesListActiveCount);

  static bool canShowHeldCustomer(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.heldSalesListCustomer);

  static bool canShowHeldValue(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.heldSalesListValue);

  static bool canShowHeldItemCount(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.heldSalesListItemCount);

  static bool canShowHeldParkedTime(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.heldSalesListParkedTime);

  static bool canShowHeldExpiryTime(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.heldSalesListExpiryTime);

  static bool canShowHeldItems(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.heldSalesListItems);

  static bool canShowHeldPagination(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.heldSalesListPagination);

  static bool canShowHeldSummary(EffectivePermissionSet p) =>
      p.hasPermission(PosPermissionCodes.heldSalesListSummary);

  /// Details has no independent child code — REUSE list view.
  static bool canShowHeldDetails(EffectivePermissionSet p) =>
      PosPermissionAccess.hasAny(p.codes.toSet(), [
        PosPermissionCodes.heldSalesView,
        PosPermissionCodes.viewBackendParkedSales,
      ]);

  /// Refresh has no independent catalog child — REUSE list view.
  static bool canRefreshHeldList(EffectivePermissionSet p) =>
      canShowHeldDetails(p);
}
