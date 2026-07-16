import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';

void main() {
  test('uses seeded broad permissions without granting proposed permissions',
      () {
    const access = TenantAdminAccessChecker(
      TenantAdminContext(
        tenantId: 'tenant-1',
        tenantName: 'Tenant',
        userId: 'user-1',
        userDisplayName: 'User',
        roles: [],
        roleNames: [],
        outletScope: [
          TenantAdminOutletScope(
            outletId: 'outlet-1',
            outletName: 'Outlet',
            isDefault: true,
          ),
        ],
        featureEntitlements: [
          TenantAdminFeatureEntitlement(
            featureCode: 'reports',
            featureName: 'Reports',
            enabled: true,
          ),
        ],
        permissions: [
          TenantAdminPermission(
            permissionCode: 'tenant.reports.sales.view',
            permissionName: 'Sales reports',
          ),
          TenantAdminPermission(
            permissionCode: 'tenant.reports.products.view',
            permissionName: 'Product reports',
          ),
          TenantAdminPermission(
            permissionCode: 'tenant.stock.view',
            permissionName: 'Stock',
          ),
          TenantAdminPermission(
            permissionCode: 'tenant.outlets.revenue.view',
            permissionName: 'Outlet revenue',
          ),
        ],
        runtimeFlags: [],
      ),
    );

    expect(access.canAccessReportsModule(), isTrue);
    expect(access.canViewSalesReport(), isTrue);
    expect(access.canViewProductSalesReport(), isTrue);
    expect(access.canViewStockReport(), isTrue);
    expect(access.canViewOutletReport(), isTrue);
    expect(access.canViewPaymentReport(), isFalse);
    expect(access.canViewTaxReport(), isFalse);
    expect(access.canViewCashierPerformance(), isFalse);
    expect(access.canViewDailySalesReport(), isFalse);
    expect(access.canExportReports(), isFalse);
    expect(access.canViewCustomerPii(), isFalse);
  });
}
