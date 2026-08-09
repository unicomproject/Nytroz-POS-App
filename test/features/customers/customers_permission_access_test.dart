import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/access/pos_permission_access.dart';
import 'package:nytroz_pos/features/customers/presentation/providers/customers_provider.dart';
import 'package:nytroz_pos/features/sale/domain/entities/pos_customer.dart';

void main() {
  group('Customers permission access', () {
    test('route requires customers.view (or legacy alias)', () {
      expect(
        PosPermissionAccess.canViewCustomers({
          PosPermissionCodes.viewNewSaleCustomers,
        }),
        isTrue,
      );
      expect(
        PosPermissionAccess.canViewCustomers({
          PosPermissionCodes.viewCustomers,
        }),
        isTrue,
      );
      expect(
        PosPermissionAccess.canViewCustomers({
          PosPermissionCodes.createNewSaleCustomer,
        }),
        isFalse,
      );
    });

    test('create requires customers.create', () {
      expect(
        PosPermissionAccess.canCreateCustomer({
          PosPermissionCodes.createNewSaleCustomer,
        }),
        isTrue,
      );
      expect(
        PosPermissionAccess.canCreateCustomer({
          PosPermissionCodes.viewNewSaleCustomers,
        }),
        isFalse,
      );
    });

    test('edit requires customers.update', () {
      expect(
        PosPermissionAccess.canEditCustomer({
          PosPermissionCodes.updateNewSaleCustomer,
        }),
        isTrue,
      );
      expect(
        PosPermissionAccess.canEditCustomer({
          PosPermissionCodes.updateCustomer,
        }),
        isTrue,
      );
      expect(
        PosPermissionAccess.canEditCustomer({
          PosPermissionCodes.viewNewSaleCustomers,
          PosPermissionCodes.createNewSaleCustomer,
        }),
        isFalse,
      );
    });

    test('attach requires view and cart manage only', () {
      expect(
        PosPermissionAccess.canAttachCustomerToSale({
          PosPermissionCodes.viewNewSaleCustomers,
          PosPermissionCodes.manageCart,
        }),
        isTrue,
      );
      expect(
        PosPermissionAccess.canAttachCustomerToSale({
          PosPermissionCodes.viewNewSaleCustomers,
        }),
        isFalse,
      );
      expect(
        PosPermissionAccess.canAttachCustomerToSale({
          PosPermissionCodes.manageCart,
        }),
        isFalse,
      );
      expect(
        PosPermissionAccess.canAttachCustomerToSale({
          PosPermissionCodes.viewNewSaleCustomers,
          PosPermissionCodes.createSale,
        }),
        isFalse,
      );
    });
  });

  group('Customer source filter mapping', () {
    test('maps UI filters to backend source codes', () {
      expect(
        const CustomersState(sourceFilter: CustomerSourceFilter.all).apiSource,
        'ALL',
      );
      expect(
        const CustomersState(sourceFilter: CustomerSourceFilter.pos).apiSource,
        'POS',
      );
      expect(
        const CustomersState(sourceFilter: CustomerSourceFilter.manual)
            .apiSource,
        'MANUAL',
      );
      expect(
        const CustomersState(sourceFilter: CustomerSourceFilter.ecommerce)
            .apiSource,
        'ECOMMERCE',
      );
      expect(
        const CustomersState(
          sourceFilter: CustomerSourceFilter.clickAndCollect,
        ).apiSource,
        'CLICK_AND_COLLECT',
      );
      expect(
        const CustomersState(sourceFilter: CustomerSourceFilter.import)
            .apiSource,
        'IMPORT',
      );
    });

    test('maps blocked status to canonical backend code', () {
      expect(
        const CustomersState(statusFilter: CustomerStatusFilter.blocked)
            .apiStatus,
        'BLOCKED',
      );
    });
  });

  group('PosCustomer parsing and display', () {
    test('maps backend summary and order fields without hardcoded values', () {
      final customer = PosCustomer.fromJson({
        'customerId': 'c1',
        'fullName': 'Backend Name',
        'phone': '+100',
        'email': 'a@b.c',
        'status': 'ACTIVE',
        'customerCode': 'CUS1',
        'sourceType': 'POS',
        'totalOrderCount': 3,
        'totalSpentAmount': 42.5,
        'currencyCode': 'LKR',
        'isMixedCurrencySpend': false,
      });

      expect(customer.displayName, 'Backend Name');
      expect(customer.customerCode, 'CUS1');
      expect(customer.sourceType, 'POS');
      expect(customer.totalOrderCount, 3);
      expect(customer.totalSpentAmount, 42.5);
      expect(customer.currencyCode, 'LKR');
      expect(customer.isMixedCurrencySpend, isFalse);
      expect(customer.ordersDisplay, '3');
      expect(customer.spentDisplay, 'LKR 42.50');
    });

    test('spentDisplay handles mixed currency and zero amounts', () {
      const mixed = PosCustomer(
        customerId: 'c1',
        fullName: 'Mixed',
        totalSpentAmount: 100,
        currencyCode: 'LKR',
        isMixedCurrencySpend: true,
      );
      expect(mixed.spentDisplay, '—');

      const zeroWithCurrency = PosCustomer(
        customerId: 'c2',
        fullName: 'Zero',
        currencyCode: 'USD',
      );
      expect(zeroWithCurrency.ordersDisplay, '0');
      expect(zeroWithCurrency.spentDisplay, 'USD 0.00');

      const zeroWithoutCurrency = PosCustomer(
        customerId: 'c3',
        fullName: 'No Currency',
      );
      expect(zeroWithoutCurrency.spentDisplay, '0.00');
    });

    test('summary parses backend counts', () {
      final summary = PosCustomerSummary.fromJson({
        'totalCustomers': 10,
        'activeCustomers': 8,
        'customersWithOrders': 5,
        'newCustomersThisMonth': 2,
        'timeZoneId': 'UTC',
      });

      expect(summary.totalCustomers, 10);
      expect(summary.activeCustomers, 8);
      expect(summary.customersWithOrders, 5);
      expect(summary.newCustomersThisMonth, 2);
    });

    test('order maps tillName and average order value handles edge cases', () {
      final order = PosCustomerOrder.fromJson({
        'orderId': 'o1',
        'orderNumber': 'SO-1',
        'orderDate': '2026-08-08T10:00:00Z',
        'totalAmount': 2800,
        'currencyCode': 'LKR',
        'status': 'COMPLETED',
        'outletDisplayName': 'Development Main Store',
        'tillName': 'Front Till 01',
      });
      expect(order.tillName, 'Front Till 01');

      const normal = PosCustomer(
        customerId: 'c1',
        fullName: 'Normal',
        totalOrderCount: 2,
        totalSpentAmount: 5000,
        currencyCode: 'LKR',
      );
      expect(normal.averageOrderValueDisplay, 'LKR 2500.00');
      expect(
        const PosCustomer(customerId: 'c2', fullName: 'Zero')
            .averageOrderValueDisplay,
        '—',
      );
    });
  });
}
