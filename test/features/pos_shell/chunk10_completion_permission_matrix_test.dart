import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/effective_permission_set.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/core/access/pos_sales_permission_visibility.dart';

void main() {
  group('Chunk 10 completion — Product Detail matrix helpers', () {
    test('container denied blocks view', () {
      final empty = EffectivePermissionSet.fromIterable(const []);
      expect(PosSalesPermissionVisibility.canViewProductDetail(empty), isFalse);
    });

    test('field gates are independent exact membership', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.catalogProductDetailName,
        PosPermissionCodes.catalogProductDetailImage,
      ]);
      expect(PosSalesPermissionVisibility.canShowDetailName(p), isTrue);
      expect(PosSalesPermissionVisibility.canShowDetailImage(p), isTrue);
      expect(PosSalesPermissionVisibility.canShowDetailPrice(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowDetailSku(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowDetailStock(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowDetailDescription(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowDetailVariants(p), isFalse);
      expect(PosSalesPermissionVisibility.canSelectDetailVariant(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowDetailQuantity(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowDetailAvailableQty(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowDetailNoteView(p), isFalse);
      expect(PosSalesPermissionVisibility.canEditDetailNote(p), isFalse);
      expect(
        PosSalesPermissionVisibility.canShowDetailRecommendations(p),
        isFalse,
      );
      expect(PosSalesPermissionVisibility.canShowDetailCancel(p), isFalse);
    });

    test('variant view without select', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.catalogProductDetailVariants,
      ]);
      expect(PosSalesPermissionVisibility.canShowDetailVariants(p), isTrue);
      expect(PosSalesPermissionVisibility.canSelectDetailVariant(p), isFalse);
    });

    test('quantity display without independent increase/decrease codes', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.catalogProductDetailQuantityDisplay,
      ]);
      expect(PosSalesPermissionVisibility.canShowDetailQuantity(p), isTrue);
      expect(PosSalesPermissionVisibility.canMutateDetailQuantity(p), isTrue);
    });

    test('add-to-cart uses cart add capability not detail view', () {
      expect(
        PosPermissionAccess.canAddCartItem({
          PosPermissionCodes.catalogProductDetailView,
        }),
        isFalse,
      );
      expect(
        PosPermissionAccess.canAddCartItem({
          PosPermissionCodes.salesCartAddItem,
        }),
        isTrue,
      );
    });
  });

  group('Chunk 10 completion — Cart matrix helpers', () {
    test('summary children independent', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.cartSummaryView,
        PosPermissionCodes.cartSummarySubtotal,
      ]);
      expect(PosSalesPermissionVisibility.canShowCartSummary(p), isTrue);
      expect(PosSalesPermissionVisibility.canShowCartSubtotal(p), isTrue);
      expect(PosSalesPermissionVisibility.canShowCartDiscount(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowCartTax(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowCartTotal(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowCartItemCount(p), isFalse);
    });

    test('line fields independent', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.cartLinesList,
        PosPermissionCodes.cartLinesName,
        PosPermissionCodes.cartLinesQuantity,
      ]);
      expect(PosSalesPermissionVisibility.canShowCartLines(p), isTrue);
      expect(PosSalesPermissionVisibility.canShowCartLineName(p), isTrue);
      expect(PosSalesPermissionVisibility.canShowCartLineQuantity(p), isTrue);
      expect(PosSalesPermissionVisibility.canShowCartLineUnitPrice(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowCartLineTotal(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowCartLineNote(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowCartLineImage(p), isFalse);
    });

    test('checkout action independent of clear', () {
      final clearOnly = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.newSaleChromeClearCartAction,
        PosPermissionCodes.salesCartClear,
      ]);
      expect(
        PosPermissionAccess.canClearCart(clearOnly.codes.toSet()),
        isTrue,
      );
      expect(
        PosSalesPermissionVisibility.canShowCheckoutAction(clearOnly),
        isFalse,
      );

      final checkoutOnly = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.newSaleChromeCheckoutAction,
      ]);
      expect(
        PosSalesPermissionVisibility.canShowCheckoutAction(checkoutOnly),
        isTrue,
      );
      expect(
        PosPermissionAccess.canClearCart(checkoutOnly.codes.toSet()),
        isFalse,
      );
    });
  });

  group('Chunk 10 completion — Park popup helpers', () {
    test('popup fields independent; confirm requires create', () {
      final fields = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.heldSalesPopupView,
        PosPermissionCodes.heldSalesPopupReference,
        PosPermissionCodes.heldSalesPopupNote,
        PosPermissionCodes.heldSalesPopupExpiry,
      ]);
      expect(PosSalesPermissionVisibility.canShowParkPopup(fields), isTrue);
      expect(PosSalesPermissionVisibility.canShowParkReference(fields), isTrue);
      expect(PosSalesPermissionVisibility.canShowParkNote(fields), isTrue);
      expect(PosSalesPermissionVisibility.canShowParkExpiry(fields), isTrue);
      expect(PosSalesPermissionVisibility.canConfirmPark(fields), isFalse);

      final create = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.heldSalesCreate,
      ]);
      expect(PosSalesPermissionVisibility.canConfirmPark(create), isTrue);
    });
  });

  group('Chunk 10 completion — Held Sales helpers', () {
    test('list fields independent', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.heldSalesListCustomer,
        PosPermissionCodes.heldSalesListItemCount,
        PosPermissionCodes.heldSalesListParkedTime,
      ]);
      expect(PosSalesPermissionVisibility.canShowHeldCustomer(p), isTrue);
      expect(PosSalesPermissionVisibility.canShowHeldItemCount(p), isTrue);
      expect(PosSalesPermissionVisibility.canShowHeldParkedTime(p), isTrue);
      expect(PosSalesPermissionVisibility.canShowHeldValue(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowHeldExpiryTime(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowHeldItems(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowHeldFilters(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowHeldPagination(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowHeldSummary(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowHeldActiveCount(p), isFalse);
    });

    test('filters and pagination are single shared codes', () {
      final filters = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.heldSalesListFilters,
      ]);
      expect(PosSalesPermissionVisibility.canShowHeldFilters(filters), isTrue);

      final pagination = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.heldSalesListPagination,
      ]);
      expect(
        PosSalesPermissionVisibility.canShowHeldPagination(pagination),
        isTrue,
      );
    });

    test('details and refresh REUSE held view', () {
      final viewOnly = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.heldSalesView,
      ]);
      expect(PosSalesPermissionVisibility.canShowHeldDetails(viewOnly), isTrue);
      expect(PosSalesPermissionVisibility.canRefreshHeldList(viewOnly), isTrue);

      final empty = EffectivePermissionSet.fromIterable(const []);
      expect(PosSalesPermissionVisibility.canShowHeldDetails(empty), isFalse);
      expect(PosSalesPermissionVisibility.canRefreshHeldList(empty), isFalse);
    });

    test('create alone does not grant cancel; view alone does not grant recall',
        () {
      expect(
        PosPermissionAccess.grantsCanonicalPermission(
          {PosPermissionCodes.heldSalesCreate},
          PosPermissionCodes.heldSalesCancel,
        ),
        isFalse,
      );
      expect(
        PosPermissionAccess.grantsCanonicalPermission(
          {PosPermissionCodes.heldSalesView},
          PosPermissionCodes.heldSalesRecall,
        ),
        isFalse,
      );
    });

    test('held sort has no independent catalog code', () {
      // Documented NO_CANONICAL_MAPPING — no PosPermissionCodes.heldSalesListSort.
      expect(
        PosPermissionCodes.catalogSectionsSort,
        'pos.catalog.sections.sort',
      );
    });
  });

  group('Chunk 10 completion — multi-device fixture logical parity', () {
    test('FIXTURE A product partial identical checks', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.catalogProductDetailImage,
        PosPermissionCodes.catalogProductDetailName,
        PosPermissionCodes.salesCartAddItem,
      ]);
      expect(PosSalesPermissionVisibility.canShowDetailImage(p), isTrue);
      expect(PosSalesPermissionVisibility.canShowDetailName(p), isTrue);
      expect(PosSalesPermissionVisibility.canShowDetailPrice(p), isFalse);
      expect(PosPermissionAccess.canAddCartItem(p.codes.toSet()), isTrue);
    });

    test('FIXTURE B cart partial identical checks', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.cartLinesList,
        PosPermissionCodes.cartLinesName,
        PosPermissionCodes.cartLinesQuantity,
        PosPermissionCodes.newSaleChromeClearCartAction,
        PosPermissionCodes.salesCartClear,
      ]);
      expect(PosSalesPermissionVisibility.canShowCartLineName(p), isTrue);
      expect(PosSalesPermissionVisibility.canShowCartLineQuantity(p), isTrue);
      expect(PosSalesPermissionVisibility.canShowCartLineUnitPrice(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowCartTotal(p), isFalse);
      expect(PosPermissionAccess.canClearCart(p.codes.toSet()), isTrue);
      expect(PosSalesPermissionVisibility.canShowCheckoutAction(p), isFalse);
    });

    test('FIXTURE C held partial identical checks', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.heldSalesView,
        PosPermissionCodes.heldSalesRecall,
      ]);
      expect(PosSalesPermissionVisibility.canShowHeldCustomer(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowHeldValue(p), isFalse);
      expect(
        PosPermissionAccess.grantsCanonicalPermission(
          p.codes.toSet(),
          PosPermissionCodes.heldSalesRecall,
        ),
        isTrue,
      );
      expect(
        PosPermissionAccess.grantsCanonicalPermission(
          p.codes.toSet(),
          PosPermissionCodes.heldSalesCancel,
        ),
        isFalse,
      );
    });

    test('FIXTURE D extreme deny — container only does not auto-grant children',
        () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.catalogProductDetailView,
        PosPermissionCodes.cartSummaryView,
        PosPermissionCodes.heldSalesPopupView,
        PosPermissionCodes.heldSalesListSummary,
      ]);
      expect(PosSalesPermissionVisibility.canShowDetailPrice(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowCartTotal(p), isFalse);
      expect(PosSalesPermissionVisibility.canShowParkReference(p), isFalse);
      // summary container/values share one code — granted here intentionally
      expect(PosSalesPermissionVisibility.canShowHeldSummary(p), isTrue);
      expect(PosSalesPermissionVisibility.canShowHeldCustomer(p), isFalse);
    });
  });
}
