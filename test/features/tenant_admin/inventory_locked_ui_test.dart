import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/data/mock/inventory_frontend_mock.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/presentation/adjustment/adjustment_flow.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/presentation/channel_allocation/channel_allocation_flow.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/presentation/current_stock/screens/current_stock_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/presentation/current_stock/screens/product_stock_detail_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/presentation/dashboard/pages/inventory_dashboard_page.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/presentation/navigation/inventory_routes.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/presentation/opening_stock/screens/opening_stock_wizard_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/presentation/receiving/receiving_flow.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/presentation/serials/serial_registry_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_context_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Inventory routes', () {
    test('canonical inventory paths alias stock paths', () {
      expect(
        InventoryRoutes.matches(
          InventoryRoutes.inventoryDashboard,
          InventoryRoutes.dashboard,
        ),
        isTrue,
      );
      expect(
        InventoryRoutes.matches(
          InventoryRoutes.inventoryReceivingNew,
          InventoryRoutes.receivingNew,
        ),
        isTrue,
      );
    });
  });

  group('TA-UJ-045 Inventory overview', () {
    testWidgets('dashboard route renders locked workspace', (tester) async {
      await _pump(tester, const InventoryDashboardPage());
      expect(find.text('Inventory Dashboard'), findsOneWidget);
      expect(find.text('Low Stock Items'), findsOneWidget);
      expect(find.text('Current Stock'), findsWidgets);
      expect(find.text('Opening Stock'), findsWidgets);
      expect(find.text('Stock Adjustment'), findsWidgets);
      expect(find.text('Stock Count'), findsWidgets);
      expect(find.text('Priority Alerts'), findsOneWidget);
    });

    testWidgets('current stock renders mock catalog', (tester) async {
      await _pump(tester, const CurrentStockScreen());
      expect(find.text('Current Stock'), findsWidgets);
      expect(find.text('Home Jersey (Red, L)'), findsOneWidget);
      expect(find.text('OneVerz Mug'), findsOneWidget);
    });

    testWidgets('product detail navigation preserves quantity labels',
        (tester) async {
      final router = GoRouter(
        initialLocation: InventoryRoutes.currentStock,
        routes: [
          GoRoute(
            path: InventoryRoutes.currentStock,
            builder: (_, __) => const CurrentStockScreen(),
          ),
          GoRoute(
            path: InventoryRoutes.currentStockDetail,
            builder: (context, state) => ProductStockDetailScreen(
              variantId: state.pathParameters['variantId'] ?? '',
            ),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      await tester.tap(find.text('Home Jersey (Red, L)'));
      await tester.pumpAndSettle();
      expect(find.text('Product Stock Detail'), findsOneWidget);
      expect(find.text('On Hand'), findsWidgets);
      expect(find.text('Reserved'), findsWidgets);
      expect(find.text('Available'), findsWidgets);
    });
  });

  group('TA-UJ-063 Opening Stock', () {
    testWidgets('completes select → enter → review → success', (tester) async {
      await _pump(tester, const OpeningStockWizardScreen(), width: 1400);
      await tester.tap(find.text('Home Jersey (Red, L)'));
      await tester.pump();
      await tester.tap(find.text('Main Outlet'));
      await tester.pump();
      await tester.tap(find.text('Continue to Enter Opening Details'));
      await tester.pumpAndSettle();
      expect(find.text('Enter Opening Stock Details'), findsOneWidget);
      await tester.tap(find.text('Continue to Review'));
      await tester.pumpAndSettle();
      expect(
        find.text(
            'Review does not change physical stock. Verify details before posting.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Confirm & Submit Stock'));
      await tester.pumpAndSettle();
      expect(find.text('Opening Stock Added Successfully!'), findsOneWidget);
    });
  });

  group('TA-UJ-046 Stock Receiving', () {
    testWidgets('dashboard search empty and pagination', (tester) async {
      await _pump(tester, const ReceivingDashboardScreen());
      expect(find.text('Stock Receiving'), findsWidgets);
      expect(find.text('RCV-10018'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.text('RCV-10013'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'no-such-receipt');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('No receipts found'), findsOneWidget);
    });

    testWidgets('hides new receipt without receiving permission',
        (tester) async {
      await _pump(
        tester,
        const ReceivingDashboardScreen(),
        permissions: [TenantAdminPermissionCodes.tenantStockView],
      );
      expect(find.text('New Stock Receipt'), findsNothing);
    });

    testWidgets('completes select → enter → review → confirm → success',
        (tester) async {
      final router = GoRouter(
        initialLocation: InventoryRoutes.receivingNew,
        routes: [
          GoRoute(
            path: InventoryRoutes.receiving,
            builder: (_, __) => const ReceivingDashboardScreen(),
          ),
          GoRoute(
            path: InventoryRoutes.receivingNew,
            builder: (_, __) => const ReceivingWizardScreen(),
          ),
          GoRoute(
            path: InventoryRoutes.currentStock,
            builder: (_, __) => const CurrentStockScreen(),
          ),
          GoRoute(
            path: InventoryRoutes.serials,
            builder: (_, __) => const SerialRegistryScreen(),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      await tester.tap(find.text('Main Outlet'));
      await tester.pump();
      await tester.tap(find.text('OneVerz Water Bottle 750ml'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      await tester.enterText(_field(tester, 'Quantity'), '4');
      await tester.enterText(_field(tester, 'Supplier name'), 'Acme Supply');
      await tester.enterText(_field(tester, 'Invoice number'), 'INV-88');
      await tester.tap(find.text('Continue to Review'));
      await tester.pumpAndSettle();
      expect(find.text('Review does not change physical stock.'), findsOneWidget);

      await tester.tap(find.text('Continue to Confirm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Receive'));
      await tester.pumpAndSettle();
      expect(find.text('Stock Received Successfully'), findsOneWidget);
      expect(find.text('RCV-10021'), findsOneWidget);
    });

    testWidgets('back from details keeps selection', (tester) async {
      await _pump(tester, const ReceivingWizardScreen());
      await tester.tap(find.text('Warehouse'));
      await tester.pump();
      await tester.tap(find.text('OneVerz Water Bottle 750ml'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Select Product'), findsWidgets);
      expect(find.text('OneVerz Water Bottle 750ml'), findsOneWidget);
    });

    testWidgets('serial count validation', (tester) async {
      await _pump(tester, const ReceivingWizardScreen());
      await tester.tap(find.text('Warehouse'));
      await tester.pump();
      await tester.tap(find.text('OneVerz Display TV 55"'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(_field(tester, 'Quantity'), '2');
      await tester.enterText(_field(tester, 'Supplier name'), 'Acme Supply');
      await tester.enterText(_field(tester, 'Invoice number'), 'INV-88');
      await tester.enterText(
        _field(tester, 'Serial numbers (one per unit)'),
        'TV-ONLY-ONE',
      );
      await tester.tap(find.text('Continue to Review'));
      await tester.pump();
      expect(
        find.text('Serial count must equal received quantity.'),
        findsOneWidget,
      );
    });
  });

  group('Serial registry', () {
    testWidgets('renders and flags duplicate serials', (tester) async {
      await _pump(tester, const SerialRegistryScreen());
      expect(find.text('Serial Number Registry'), findsOneWidget);
      expect(find.text('TV-55-10021'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(1), 'TV-55-10021');
      await tester.pump();
      await tester.tap(find.text('Validate Serial'));
      await tester.pump();
      expect(find.textContaining('Duplicate serial'), findsOneWidget);
    });
  });

  group('TA-UJ-047 Stock Adjustment', () {
    testWidgets('completes select → enter → review → success', (tester) async {
      final router = GoRouter(
        initialLocation: InventoryRoutes.adjustmentNew,
        routes: [
          GoRoute(
            path: InventoryRoutes.adjustment,
            builder: (_, __) => const AdjustmentDashboardScreen(),
          ),
          GoRoute(
            path: InventoryRoutes.adjustmentNew,
            builder: (_, __) => const AdjustmentWizardScreen(),
          ),
          GoRoute(
            path: InventoryRoutes.currentStock,
            builder: (_, __) => const CurrentStockScreen(),
          ),
        ],
      );
      await _pumpRouter(tester, router);
      await tester.tap(find.text('OneVerz Water Bottle 750ml'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('INCREASE'));
      await tester.pump();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Found Stock').last);
      await tester.pumpAndSettle();
      await tester.enterText(_field(tester, 'Quantity'), '2');
      await tester.tap(find.text('Continue to Review'));
      await tester.pumpAndSettle();
      expect(find.text('Review does not change physical stock.'), findsOneWidget);
      await tester.tap(find.text('Post Adjustment'));
      await tester.pumpAndSettle();
      expect(find.text('Stock Adjustment Posted'), findsOneWidget);
    });

    testWidgets('rejects negative resulting on-hand', (tester) async {
      await _pump(tester, const AdjustmentWizardScreen());
      await tester.tap(find.text('OneVerz Mug'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Damaged').last);
      await tester.pumpAndSettle();
      await tester.enterText(_field(tester, 'Quantity'), '1');
      await tester.tap(find.text('Continue to Review'));
      await tester.pump();
      expect(find.textContaining('below reserved'), findsOneWidget);
    });
  });

  group('TA-UJ-064 Channel Allocation', () {
    testWidgets('completes Model B allocation without changing on-hand copy',
        (tester) async {
      final router = GoRouter(
        initialLocation: InventoryRoutes.channelNew,
        routes: [
          GoRoute(
            path: InventoryRoutes.channel,
            builder: (_, __) => const ChannelAllocationDashboardScreen(),
          ),
          GoRoute(
            path: InventoryRoutes.channelNew,
            builder: (_, __) => const ChannelAllocationWizardScreen(),
          ),
          GoRoute(
            path: InventoryRoutes.channelDetail,
            builder: (context, state) => ChannelAllocationDetailScreen(
              id: state.pathParameters['id'] ?? '',
            ),
          ),
        ],
      );
      await _pumpRouter(
        tester,
        router,
        permissions: [
          TenantAdminPermissionCodes.inventoryStockView,
          TenantAdminPermissionCodes.inventoryChannelAllocationView,
          TenantAdminPermissionCodes.inventoryChannelAllocationManage,
        ],
      );
      await tester.tap(find.text('Main Outlet'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home Jersey (Red, L)'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(find.text('On Hand'), findsWidgets);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('POS'));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      final limitField = find.byType(TextField).last;
      await tester.enterText(limitField, '10');
      await tester.tap(find.text('Continue to Review'));
      await tester.pumpAndSettle();
      expect(find.textContaining('does not reduce On Hand'), findsOneWidget);
      await tester.tap(find.text('Continue to Confirm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm Allocation'));
      await tester.pumpAndSettle();
      expect(find.text('Allocation Completed Successfully'), findsOneWidget);
      expect(find.textContaining('Physical on-hand did not change'), findsOneWidget);
    });

    testWidgets('hides new allocation without manage permission',
        (tester) async {
      await _pump(
        tester,
        const ChannelAllocationDashboardScreen(),
        permissions: [TenantAdminPermissionCodes.inventoryStockView],
      );
      expect(find.text('New Allocation'), findsNothing);
    });
  });
}

Finder _field(WidgetTester tester, String label) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.decoration?.labelText == label,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  double width = 1400,
  double height = 1000,
  List<String>? permissions,
}) async {
  await tester.binding.setSurfaceSize(Size(width, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final accessChecker = _checker(permissions: permissions);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        inventoryFrontendMockEnabledProvider.overrideWith((ref) => true),
        tenantAdminContextProvider.overrideWith(
          (ref) async => accessChecker.context,
        ),
        tenantAdminAccessCheckerProvider.overrideWith(
          (ref) async => accessChecker,
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            height: height,
            child: Column(
              children: [Expanded(child: child)],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

Future<void> _pumpRouter(
  WidgetTester tester,
  GoRouter router, {
  double width = 1400,
  double height = 1000,
  List<String>? permissions,
}) async {
  await tester.binding.setSurfaceSize(Size(width, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final accessChecker = _checker(permissions: permissions);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tenantAdminContextProvider.overrideWith(
          (ref) async => accessChecker.context,
        ),
        tenantAdminAccessCheckerProvider.overrideWith(
          (ref) async => accessChecker,
        ),
      ],
      child: MaterialApp.router(
        builder: (context, child) {
          return Scaffold(
            body: SizedBox(
              width: width,
              height: height,
              child: Column(
                children: [Expanded(child: child ?? const SizedBox.shrink())],
              ),
            ),
          );
        },
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

TenantAdminAccessChecker _checker({List<String>? permissions}) {
  final codes = permissions ??
      [
        TenantAdminPermissionCodes.tenantStockView,
        TenantAdminPermissionCodes.tenantStockIn,
        TenantAdminPermissionCodes.tenantStockOpening,
        TenantAdminPermissionCodes.inventoryStockView,
        TenantAdminPermissionCodes.inventoryReceivingManage,
        TenantAdminPermissionCodes.inventoryOpeningStockManage,
        TenantAdminPermissionCodes.inventorySerialsView,
        TenantAdminPermissionCodes.inventoryStockAdjust,
        TenantAdminPermissionCodes.inventoryChannelAllocationView,
        TenantAdminPermissionCodes.inventoryChannelAllocationManage,
        TenantAdminPermissionCodes.inventoryAlertsView,
      ];
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
      featureEntitlements: const [
        TenantAdminFeatureEntitlement(
          featureCode: TenantAdminFeatureCodes.inventoryManagement,
          featureName: 'Inventory',
          enabled: true,
        ),
      ],
      permissions: [
        for (final permissionCode in codes)
          TenantAdminPermission(
            permissionCode: permissionCode,
            permissionName: permissionCode,
          ),
      ],
      runtimeFlags: const [
        TenantAdminRuntimeFlag(
          featureCode: TenantAdminFeatureCodes.inventoryManagement,
          enabled: true,
        ),
      ],
    ),
  );
}
