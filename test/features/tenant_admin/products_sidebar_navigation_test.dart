import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/data/catalog/tenant_admin_menu_catalog.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/navigation/products_route_guard.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/navigation/products_sidebar_menu.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/navigation/products_sidebar_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/navigation/products_sidebar_routes.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/navigation/products_sidebar_visibility.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';

TenantAdminAccessChecker _accessFor(Iterable<String> permissionCodes) {
  return TenantAdminAccessChecker(
    TenantAdminContext(
      tenantId: 'tenant-1',
      tenantName: 'SCS-TIX',
      userId: 'user-1',
      userDisplayName: 'Tenant Admin',
      roles: const [],
      roleNames: const ['Tenant Admin'],
      outletScope: const [],
      featureEntitlements: const [],
      permissions: [
        for (final code in permissionCodes)
          TenantAdminPermission(
            permissionCode: code,
            permissionName: code,
          ),
      ],
      runtimeFlags: const [],
    ),
  );
}

void main() {
  group('ProductsSidebarVisibility', () {
    test('hides parent when no permissions', () {
      final visibility = ProductsSidebarVisibility.resolve(
        access: _accessFor(const []),
      );

      expect(visibility.showParent, isFalse);
      expect(visibility.hasVisibleChildren, isFalse);
    });

    test('shows only Product List with view permission', () {
      final visibility = ProductsSidebarVisibility.resolve(
        access: _accessFor([TenantAdminPermissionCodes.tenantProductsView]),
      );

      expect(visibility.visibleChildren.map((item) => item.label), [
        'Product List',
      ]);
    });

    test('shows only Add Product with create permission', () {
      final visibility = ProductsSidebarVisibility.resolve(
        access: _accessFor([TenantAdminPermissionCodes.tenantProductsCreate]),
      );

      expect(visibility.visibleChildren.map((item) => item.label), [
        'Add Product',
      ]);
    });

    test('shows only Categories with categories permission', () {
      final visibility = ProductsSidebarVisibility.resolve(
        access: _accessFor([TenantAdminPermissionCodes.tenantCategoriesView]),
      );

      expect(visibility.visibleChildren.map((item) => item.label), [
        'Categories',
      ]);
    });

    test('shows only Brands with brands permission', () {
      final visibility = ProductsSidebarVisibility.resolve(
        access: _accessFor([TenantAdminPermissionCodes.tenantBrandsView]),
      );

      expect(visibility.visibleChildren.map((item) => item.label), ['Brands']);
    });

    test('shows Inventory child as unavailable with stock permission', () {
      final visibility = ProductsSidebarVisibility.resolve(
        access: _accessFor([TenantAdminPermissionCodes.tenantStockView]),
      );

      expect(visibility.visibleChildren.map((item) => item.label), [
        'Inventory',
      ]);
      expect(visibility.visibleChildren.single.isRouteAvailable, isFalse);
    });

    test('shows Import with import permission', () {
      final visibility = ProductsSidebarVisibility.resolve(
        access: _accessFor([TenantAdminPermissionCodes.tenantProductImport]),
      );

      expect(visibility.visibleChildren.map((item) => item.label), ['Import']);
    });

    test('approved child order when all visible', () {
      final visibility = ProductsSidebarVisibility.resolve(
        access: _accessFor([
          TenantAdminPermissionCodes.tenantProductsView,
          TenantAdminPermissionCodes.tenantProductsCreate,
          TenantAdminPermissionCodes.tenantCategoriesView,
          TenantAdminPermissionCodes.tenantBrandsView,
          TenantAdminPermissionCodes.tenantStockView,
          TenantAdminPermissionCodes.tenantProductImport,
        ]),
      );

      expect(
        visibility.visibleChildren.map((item) => item.label).toList(),
        [
          'Product List',
          'Add Product',
          'Categories',
          'Brands',
          'Inventory',
          'Import',
        ],
      );
    });
  });

  group('ProductsRouteGuard', () {
    test('allows only matching route permissions', () {
      final access =
          _accessFor([TenantAdminPermissionCodes.tenantProductsView]);

      expect(
        ProductsRouteGuard.canAccessPath(
          access,
          ProductsSidebarRoutes.list,
        ),
        isTrue,
      );
      expect(
        ProductsRouteGuard.canAccessPath(
          access,
          ProductsSidebarRoutes.add,
        ),
        isFalse,
      );
    });
  });

  group('Products menu catalog access', () {
    test('products menu hidden without child permissions', () {
      const access = TenantAdminAccessChecker(
        TenantAdminContext(
          tenantId: 'tenant-1',
          tenantName: 'SCS-TIX',
          userId: 'user-1',
          userDisplayName: 'Tenant Admin',
          roles: [],
          roleNames: ['Tenant Admin'],
          outletScope: [],
          featureEntitlements: [],
          permissions: [],
          runtimeFlags: [],
        ),
      );

      final productsMenu = tenantAdminMenuCatalog.firstWhere(
        (item) => item.key == 'products',
      );

      expect(access.canAccessMenuItem(productsMenu), isFalse);
    });

    test('products menu visible with any child permission', () {
      final access =
          _accessFor([TenantAdminPermissionCodes.tenantProductsView]);
      final productsMenu = tenantAdminMenuCatalog.firstWhere(
        (item) => item.key == 'products',
      );

      expect(access.canAccessProductsSidebar(), isTrue);
      expect(access.canAccessMenuItem(productsMenu), isTrue);
    });
  });

  group('ProductsSidebarRoutes', () {
    test('detects active products area routes', () {
      expect(
        ProductsSidebarRoutes.isProductsArea('/tenant-admin/products'),
        isTrue,
      );

      expect(
        ProductsSidebarRoutes.isProductsArea(
          '/tenant-admin/products/dashboard',
        ),
        isTrue,
      );

      expect(
        ProductsSidebarRoutes.isProductsArea(
          '/tenant-admin/products/import',
        ),
        isTrue,
      );

      expect(
        ProductsSidebarRoutes.isProductsArea('/tenant-admin/categories'),
        isTrue,
      );

      expect(
        ProductsSidebarRoutes.isProductsArea('/tenant-admin/brands'),
        isTrue,
      );

      expect(
        ProductsSidebarRoutes.isProductsArea(
          '/tenant-admin/variant-templates',
        ),
        isTrue,
      );

      expect(
        ProductsSidebarRoutes.isProductsArea('/tenant-admin/dashboard'),
        isFalse,
      );
    });

    test('highlights product list for detail routes', () {
      expect(
        ProductsSidebarRoutes.isChildActive(
          currentPath: '/tenant-admin/products/prod-1',
          route: ProductsSidebarRoutes.list,
        ),
        isTrue,
      );

      expect(
        ProductsSidebarRoutes.isChildActive(
          currentPath: '/tenant-admin/products/add',
          route: ProductsSidebarRoutes.list,
        ),
        isFalse,
      );

      expect(
        ProductsSidebarRoutes.isChildActive(
          currentPath: '/tenant-admin/products/import',
          route: ProductsSidebarRoutes.list,
        ),
        isFalse,
      );
    });
  });

  group('ProductsSidebarMenu widget', () {
    testWidgets('expands and collapses submenu on parent tap', (tester) async {
      final access = _accessFor([
        TenantAdminPermissionCodes.tenantProductsView,
        TenantAdminPermissionCodes.tenantProductsCreate,
      ]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tenantAdminAccessCheckerProvider.overrideWith(
              (ref) async => access,
            ),
            productsSidebarManualExpandedProvider.overrideWith((ref) => null),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ProductsSidebarMenu(
                currentPath: '/tenant-admin/dashboard',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Product List'), findsNothing);

      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();

      expect(find.text('Product List'), findsOneWidget);
      expect(find.text('Add Product'), findsOneWidget);

      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();

      expect(find.text('Product List'), findsNothing);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Product List'), findsNothing);
    });

    testWidgets('renders without overflow on narrow width', (tester) async {
      final access = _accessFor([
        TenantAdminPermissionCodes.tenantProductsView,
        TenantAdminPermissionCodes.tenantProductImport,
      ]);

      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tenantAdminAccessCheckerProvider.overrideWith(
              (ref) async => access,
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 280,
                child: ProductsSidebarMenu(
                  currentPath: '/tenant-admin/products',
                  compact: true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
