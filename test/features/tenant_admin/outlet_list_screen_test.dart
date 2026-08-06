import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_menu_item.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/domain/entities/outlet.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/presentation/providers/outlet_visibility_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/presentation/screens/outlet_list_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/layout/tenant_admin_bottom_nav.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/presentation/providers/outlet_providers.dart';

void main() {
  group('Outlet list screen', () {
    testWidgets('shows unauthorized state when outlet.view is missing',
        (tester) async {
      await _pumpOutletList(
        tester,
        permissions: [TenantAdminPermissionCodes.tenantAdminDashboardView],
        features: [TenantAdminFeatureCodes.dashboard],
      );

      expect(find.text('No access to Outlets'), findsOneWidget);
      expect(find.text('High Street Store'), findsNothing);
    });

    testWidgets('renders outlet list when outlet.view exists', (tester) async {
      await _pumpOutletList(
        tester,
        permissions: [TenantAdminPermissionCodes.outletView],
        features: [TenantAdminFeatureCodes.outletManagement],
        width: 1400,
        height: 1200,
      );

      expect(find.text('Outlets'), findsWidgets);
      expect(find.text('High Street Store'), findsOneWidget);
      expect(find.text('Add Outlet'), findsNothing);
    });

    testWidgets('shows Add outlet button only with outlet.create',
        (tester) async {
      await _pumpOutletList(
        tester,
        permissions: [
          TenantAdminPermissionCodes.outletView,
          TenantAdminPermissionCodes.outletCreate,
        ],
        features: [TenantAdminFeatureCodes.outletManagement],
        width: 1400,
        height: 1200,
      );

      expect(find.text('Add Outlet'), findsOneWidget);
    });

    testWidgets('shows summary cards only with outlet.summary.view',
        (tester) async {
      await _pumpOutletList(
        tester,
        permissions: [
          TenantAdminPermissionCodes.outletView,
          TenantAdminPermissionCodes.outletSummaryView,
        ],
        features: [TenantAdminFeatureCodes.outletManagement],
        width: 1400,
        height: 1200,
      );

      expect(find.text('Total Outlets'), findsOneWidget);
    });

    testWidgets('hides City column without location permission',
        (tester) async {
      await _pumpOutletList(
        tester,
        permissions: [TenantAdminPermissionCodes.outletView],
        features: [TenantAdminFeatureCodes.outletManagement],
        width: 1400,
        height: 1200,
      );

      expect(find.text('City'), findsNothing);
    });

    testWidgets('does not crash when user has only outlet.view',
        (tester) async {
      await _pumpOutletList(
        tester,
        permissions: [TenantAdminPermissionCodes.outletView],
        features: [TenantAdminFeatureCodes.outletManagement],
        width: 1400,
        height: 1200,
      );

      expect(find.text('Outlets'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('Outlet bottom navigation', () {
    testWidgets('filters bottom nav items by permission', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: TenantAdminBottomNav(
              items: _menuItems
                  .where(
                    (item) => _checker(
                      permissions: [
                        TenantAdminPermissionCodes.outletView,
                      ],
                      features: [
                        TenantAdminFeatureCodes.outletManagement,
                      ],
                    ).canAccessMenuItem(item),
                  )
                  .toList(growable: false),
              currentPath: '/tenant-admin/outlets',
            ),
          ),
        ),
      );

      expect(find.text('Outlets'), findsOneWidget);
      expect(find.text('Dashboard'), findsNothing);
      expect(find.text('Tills'), findsNothing);
    });
  });
}

Future<void> _pumpOutletList(
  WidgetTester tester, {
  required List<String> permissions,
  required List<String> features,
  double width = 800,
  double height = 900,
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
        tenantAdminAccessCheckerProvider.overrideWith(
          (ref) async => accessChecker,
        ),
        outletListProvider.overrideWith(
          (ref) async => const OutletListResult(
            summary: OutletListSummary(
              totalOutlets: 1,
              activeOutlets: 1,
              inactiveOutlets: 0,
              totalLocations: 1,
            ),
            items: [
              Outlet(
                id: 'outlet-1',
                name: 'High Street Store',
                code: 'OUT-001',
                location: '12 High Street, London',
                status: 'Active',
                tillCount: 2,
                onlineTillCount: 2,
                staffCount: 4,
                todaysSales: '£1,245.50',
              ),
            ],
            page: 1,
            pageSize: 10,
            totalCount: 1,
          ),
        ),
        outletSummaryDashboardProvider.overrideWith(
          (ref) async => const OutletSummaryDashboard(
            totalOutlets: 1,
            activeOutlets: 1,
            warehouseOutlets: 0,
            needsAttention: null,
          ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            child: const OutletListScreen(),
          ),
        ),
      ),
    ),
  );

  await tester.pump();
  await tester.pump(Duration.zero);
  await tester.pump(Duration.zero);
  await tester.pump(Duration.zero);
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
      roleNames: ['Owner'],
      roles: const [
        TenantAdminRoleScope(roleId: 'role-1', roleName: 'Owner'),
      ],
      outletScope: const [
        TenantAdminOutletScope(
          outletId: 'outlet-1',
          outletName: 'High Street Store',
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

const _menuItems = [
  TenantAdminMenuItem(
    key: 'dashboard',
    label: 'Dashboard',
    route: '/tenant-admin/dashboard',
    iconKey: 'dashboard',
    featureCode: TenantAdminFeatureCodes.dashboard,
    permissionCode: TenantAdminPermissionCodes.tenantAdminDashboardView,
    visible: true,
    order: 1,
  ),
  TenantAdminMenuItem(
    key: 'outlets',
    label: 'Outlets',
    route: '/tenant-admin/outlets',
    iconKey: 'store',
    featureCode: TenantAdminFeatureCodes.outletManagement,
    permissionCode: TenantAdminPermissionCodes.outletView,
    visible: true,
    order: 2,
  ),
  TenantAdminMenuItem(
    key: 'tills',
    label: 'Tills',
    route: '/tenant-admin/tills',
    iconKey: 'till',
    featureCode: TenantAdminFeatureCodes.tillManagement,
    permissionCode: TenantAdminPermissionCodes.tillView,
    visible: true,
    order: 3,
  ),
  TenantAdminMenuItem(
    key: 'staff',
    label: 'Staff',
    route: '/tenant-admin/staff',
    iconKey: 'users',
    featureCode: TenantAdminFeatureCodes.staffManagement,
    permissionCode: TenantAdminPermissionCodes.userView,
    visible: true,
    order: 4,
  ),
];
