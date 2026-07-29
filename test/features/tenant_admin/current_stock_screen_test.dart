import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/domain/entities/inventory_entities.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/presentation/providers/inventory_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/presentation/screens/current_stock_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_context_provider.dart';

void main() {
  group('Current stock screen', () {
    testWidgets('shows unauthorized state without tenant.stock.view',
        (tester) async {
      await _pumpCurrentStock(
        tester,
        permissions: [TenantAdminPermissionCodes.tenantAdminDashboardView],
        features: [TenantAdminFeatureCodes.inventoryManagement],
      );

      expect(find.text('No access to Current Stock'), findsOneWidget);
      expect(find.text('Espresso Beans'), findsNothing);
    });

    testWidgets('shows stock in button when tenant.stock.in is granted',
        (tester) async {
      await _pumpCurrentStock(
        tester,
        permissions: [
          TenantAdminPermissionCodes.tenantStockView,
          TenantAdminPermissionCodes.tenantStockIn,
        ],
        features: [TenantAdminFeatureCodes.inventoryManagement],
        width: 1400,
      );

      expect(find.text('Stock In'), findsWidgets);
    });

    testWidgets('hides stock in button without tenant.stock.in',
        (tester) async {
      await _pumpCurrentStock(
        tester,
        permissions: [TenantAdminPermissionCodes.tenantStockView],
        features: [TenantAdminFeatureCodes.inventoryManagement],
        width: 1400,
      );

      expect(find.text('Current Stock'), findsOneWidget);
      expect(find.text('Stock In'), findsNothing);
    });

    testWidgets('renders mobile cards without overflow', (tester) async {
      await _pumpCurrentStock(
        tester,
        permissions: [TenantAdminPermissionCodes.tenantStockView],
        features: [TenantAdminFeatureCodes.inventoryManagement],
        width: 390,
        height: 900,
      );

      expect(find.text('Espresso Beans'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows filtered empty state', (tester) async {
      await _pumpCurrentStock(
        tester,
        permissions: [TenantAdminPermissionCodes.tenantStockView],
        features: [TenantAdminFeatureCodes.inventoryManagement],
        emptyResult: true,
        hasFilters: true,
        width: 390,
      );

      expect(find.text('No matching stock found'), findsOneWidget);
      expect(find.text('Clear filters'), findsOneWidget);
    });
  });
}

Future<void> _pumpCurrentStock(
  WidgetTester tester, {
  required List<String> permissions,
  required List<String> features,
  double width = 1200,
  double height = 900,
  bool emptyResult = false,
  bool hasFilters = false,
}) async {
  final accessChecker = _checker(
    permissions: permissions,
    features: features,
  );

  await tester.binding.setSurfaceSize(Size(width, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tenantAdminContextProvider.overrideWith(
          (ref) async => accessChecker.context,
        ),
        tenantAdminAccessCheckerProvider.overrideWith(
          (ref) async => accessChecker,
        ),
        currentStockListProvider.overrideWith(
          (ref) async => CurrentStockPage(
            items: emptyResult
                ? const []
                : [
                    const CurrentStockItem(
                      inventoryBalanceId: 'balance-1',
                      inventoryLocationId: 'location-1',
                      outletId: 'outlet-1',
                      outletName: 'Dev Outlet',
                      productId: 'product-1',
                      productName: 'Espresso Beans',
                      variantOptions: [],
                      onHandQuantity: 10,
                      reservedQuantity: 0,
                      damagedQuantity: 0,
                      quarantineQuantity: 0,
                      availableQuantity: 10,
                      stockStatus: 'IN_STOCK',
                      expiryStatus: 'VALID',
                      rowVersion: 1,
                    ),
                  ],
            page: 1,
            pageSize: 50,
            totalCount: emptyResult ? 0 : 1,
          ),
        ),
        currentStockSummaryProvider.overrideWith(
          (ref) async => const CurrentStockSummary(
            totalProducts: 1,
            totalVariants: 1,
            totalUnits: 10,
            lowStockCount: 0,
            outOfStockCount: 0,
            expiringSoonCount: 0,
          ),
        ),
        currentStockSearchProvider
            .overrideWith((ref) => hasFilters ? 'none' : ''),
        currentStockStatusFilterProvider
            .overrideWith((ref) => hasFilters ? 'LOW_STOCK' : null),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            height: height,
            child: const CurrentStockScreen(),
          ),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

TenantAdminAccessChecker _checker({
  required List<String> permissions,
  required List<String> features,
}) {
  return TenantAdminAccessChecker(
    TenantAdminContext(
      tenantId: 'tenant-test',
      tenantName: 'Coffee Corner Ltd',
      userId: 'user-test',
      userDisplayName: 'Sarah Ahmed',
      roleNames: const ['Owner'],
      roles: const [
        TenantAdminRoleScope(roleId: 'role-1', roleName: 'Owner'),
      ],
      outletScope: const [
        TenantAdminOutletScope(
          outletId: 'outlet-1',
          outletName: 'Dev Outlet',
          isDefault: true,
        ),
      ],
      featureEntitlements: [
        for (final featureCode in features)
          TenantAdminFeatureEntitlement(
            featureCode: featureCode,
            featureName: featureCode,
            enabled: true,
          ),
      ],
      permissions: [
        for (final permissionCode in permissions)
          TenantAdminPermission(
            permissionCode: permissionCode,
            permissionName: permissionCode,
          ),
      ],
      runtimeFlags: [
        for (final featureCode in features)
          TenantAdminRuntimeFlag(featureCode: featureCode, enabled: true),
      ],
    ),
  );
}
