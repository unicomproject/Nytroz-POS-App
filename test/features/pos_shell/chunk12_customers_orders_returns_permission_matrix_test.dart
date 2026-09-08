import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/effective_permission_set.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_customers_orders_returns_visibility.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';

void main() {
  group('Chunk 12 — Customer independence', () {
    test('View alone does not authorize Attach', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.viewNewSaleCustomers,
        PosPermissionCodes.customersListName,
      ]);
      expect(PosCustomersOrdersReturnsVisibility.canViewCustomers(p), isTrue);
      expect(
        PosCustomersOrdersReturnsVisibility.canAttachCustomerToSale(p),
        isFalse,
      );
      expect(
        PosPermissionAccess.canAttachCustomerToSale(p.codes.toSet()),
        isFalse,
      );
    });

    test('Attach requires exact attach_sale code', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.customersAttachSale,
      ]);
      expect(
        PosCustomersOrdersReturnsVisibility.canAttachCustomerToSale(p),
        isTrue,
      );
    });

    test('View alone does not authorize Update', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.viewNewSaleCustomers,
      ]);
      expect(PosCustomersOrdersReturnsVisibility.canUpdateCustomer(p), isFalse);
    });

    test('PII fields independent of view', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.customersListName,
      ]);
      expect(PosCustomersOrdersReturnsVisibility.canShowCustomerName(p), isTrue);
      expect(
        PosCustomersOrdersReturnsVisibility.canShowCustomerPhone(p),
        isFalse,
      );
      expect(
        PosCustomersOrdersReturnsVisibility.canShowCustomerEmail(p),
        isFalse,
      );
      expect(
        PosCustomersOrdersReturnsVisibility.canShowCustomerTotalSpend(p),
        isFalse,
      );
    });

    test('Phone only among PII', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.customersListPhone,
      ]);
      expect(
        PosCustomersOrdersReturnsVisibility.canShowCustomerPhone(p),
        isTrue,
      );
      expect(
        PosCustomersOrdersReturnsVisibility.canShowCustomerEmail(p),
        isFalse,
      );
    });

    test('Purchase history independent of amounts', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.customersHistoryPurchaseHistory,
      ]);
      expect(
        PosCustomersOrdersReturnsVisibility.canShowPurchaseHistory(p),
        isTrue,
      );
      expect(
        PosCustomersOrdersReturnsVisibility.canShowPurchaseAmounts(p),
        isFalse,
      );
    });

    test('Deactivate uses exact deactivate code', () {
      expect(
        PosPermissionAccess.canDeactivateCustomer({
          PosPermissionCodes.updateNewSaleCustomer,
        }),
        isFalse,
      );
      expect(
        PosPermissionAccess.canDeactivateCustomer({
          PosPermissionCodes.customersDeactivate,
        }),
        isTrue,
      );
    });
  });

  group('Chunk 12 — Receipt history vs Online Orders', () {
    test('Receipt history uses digital.view family', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.receiptsDigitalView,
      ]);
      expect(
        PosCustomersOrdersReturnsVisibility.canViewReceiptHistory(p),
        isTrue,
      );
      expect(
        PosCustomersOrdersReturnsVisibility.canAccessOnlineOrders(p),
        isFalse,
      );
    });

    test('Online access does not unlock receipt history alone', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.accessOnlineOrders,
      ]);
      expect(
        PosCustomersOrdersReturnsVisibility.canViewReceiptHistory(p),
        isFalse,
      );
    });

    test('Print does not authorize Reprint', () {
      final printOnly = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.receiptsPhysicalPrint,
      ]);
      expect(
        PosCustomersOrdersReturnsVisibility.canPrintReceipt(printOnly),
        isTrue,
      );
      expect(
        PosCustomersOrdersReturnsVisibility.canReprintReceipt(printOnly),
        isFalse,
      );
    });

    test('History field independence', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.receiptsDetailsReceiptNumber,
        PosPermissionCodes.receiptsHistoryReprint,
      ]);
      expect(
        PosCustomersOrdersReturnsVisibility.canShowHistoryReceiptNumber(p),
        isTrue,
      );
      expect(
        PosCustomersOrdersReturnsVisibility.canShowHistoryTotal(p),
        isFalse,
      );
      expect(
        PosCustomersOrdersReturnsVisibility.canShowHistoryCustomer(p),
        isFalse,
      );
      expect(
        PosCustomersOrdersReturnsVisibility.canReprintReceipt(p),
        isTrue,
      );
    });
  });

  group('Chunk 12 — Online Orders / Returns', () {
    test('Online access alone does not grant fulfilment start', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.accessOnlineOrders,
        PosPermissionCodes.viewOnlineOrders,
      ]);
      expect(
        PosCustomersOrdersReturnsVisibility.canAccessOnlineOrders(p),
        isTrue,
      );
      expect(
        PosCustomersOrdersReturnsVisibility.canStartOnlineFulfilment(p),
        isFalse,
      );
    });

    test('Returns search does not auto-grant workflow create', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.returnsSearchSaleView,
      ]);
      expect(
        PosCustomersOrdersReturnsVisibility.canViewReturnsSearch(p),
        isTrue,
      );
      expect(
        PosCustomersOrdersReturnsVisibility.canCreateReturnWorkflow(p),
        isFalse,
      );
    });

    test('pos.refund.approve helper exists without inventing UI', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.approveRefund,
      ]);
      expect(PosCustomersOrdersReturnsVisibility.canApproveRefund(p), isTrue);
    });
  });

  group('Chunk 12 — multi-device fixture logical parity', () {
    test('FIXTURE A customer partial', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.viewNewSaleCustomers,
        PosPermissionCodes.customersListName,
        PosPermissionCodes.customersAttachSale,
      ]);
      expect(PosCustomersOrdersReturnsVisibility.canShowCustomerName(p), isTrue);
      expect(
        PosCustomersOrdersReturnsVisibility.canShowCustomerPhone(p),
        isFalse,
      );
      expect(
        PosCustomersOrdersReturnsVisibility.canShowCustomerEmail(p),
        isFalse,
      );
      expect(
        PosCustomersOrdersReturnsVisibility.canAttachCustomerToSale(p),
        isTrue,
      );
    });

    test('FIXTURE B receipt history partial', () {
      final p = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.receiptsDigitalView,
        PosPermissionCodes.receiptsDetailsReceiptNumber,
        PosPermissionCodes.receiptsHistoryReprint,
      ]);
      expect(
        PosCustomersOrdersReturnsVisibility.canViewReceiptHistory(p),
        isTrue,
      );
      expect(
        PosCustomersOrdersReturnsVisibility.canShowHistoryReceiptNumber(p),
        isTrue,
      );
      expect(
        PosCustomersOrdersReturnsVisibility.canShowHistoryCustomer(p),
        isFalse,
      );
      expect(
        PosCustomersOrdersReturnsVisibility.canShowHistoryTotal(p),
        isFalse,
      );
      expect(
        PosCustomersOrdersReturnsVisibility.canReprintReceipt(p),
        isTrue,
      );
    });
  });
}
