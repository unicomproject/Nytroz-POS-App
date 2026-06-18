import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/dashboard/domain/entities/tenant_dashboard.dart';
import 'package:nytroz_pos/features/tenant_admin/dashboard/presentation/providers/tenant_dashboard_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/dashboard/presentation/screens/tenant_dashboard_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/dashboard/presentation/widgets/dashboard_metric_grid.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_menu_item.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/layout/tenant_admin_sidebar.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_context_provider.dart';

void main() {
  group('Tenant dashboard screen', () {
    testWidgets('shows unauthorized state without tenant_admin.dashboard.view',
        (tester) async {
      await _pumpDashboard(
        tester,
        permissions: [TenantAdminPermissionCodes.outletView],
        features: [TenantAdminFeatureCodes.outletManagement],
      );

      expect(find.text('No access to Dashboard'), findsOneWidget);
      expect(find.text("Today's Sales"), findsNothing);
    });

    testWidgets('renders Today\'s Sales card when dashboard.sales_summary.view is granted',
        (tester) async {
      await _pumpDashboard(
        tester,
        permissions: [
          TenantAdminPermissionCodes.tenantAdminDashboardView,
          TenantAdminPermissionCodes.dashboardSalesSummaryView,
        ],
        features: [
          TenantAdminFeatureCodes.dashboard,
          TenantAdminFeatureCodes.sales,
        ],
      );

      expect(find.text("Today's Sales"), findsOneWidget);
    });

    testWidgets('hides Today\'s Sales without sales summary permissions',
        (tester) async {
      await _pumpDashboard(
        tester,
        permissions: [
          TenantAdminPermissionCodes.tenantAdminDashboardView,
          TenantAdminPermissionCodes.dashboardOutletSummaryView,
        ],
        features: [
          TenantAdminFeatureCodes.dashboard,
          TenantAdminFeatureCodes.outletManagement,
        ],
      );

      expect(find.text("Today's Sales"), findsNothing);
      expect(find.text('Active Outlets'), findsOneWidget);
    });

    testWidgets('shows Add outlet quick action when outlet.create is granted',
        (tester) async {
      await _pumpDashboard(
        tester,
        permissions: [
          TenantAdminPermissionCodes.tenantAdminDashboardView,
          TenantAdminPermissionCodes.outletCreate,
        ],
        features: [
          TenantAdminFeatureCodes.dashboard,
          TenantAdminFeatureCodes.outletManagement,
        ],
      );

      expect(find.text('Add outlet'), findsOneWidget);
    });

    testWidgets('shows empty widgets message when dashboard opens with no widgets',
        (tester) async {
      await _pumpDashboard(
        tester,
        permissions: [TenantAdminPermissionCodes.tenantAdminDashboardView],
        features: [TenantAdminFeatureCodes.dashboard],
      );

      expect(
        find.text('No dashboard widgets available for your access.'),
        findsOneWidget,
      );
    });

    testWidgets('mobile layout reflows without blank KPI placeholders',
        (tester) async {
      await _pumpDashboard(
        tester,
        size: const Size(390, 1200),
        permissions: [
          TenantAdminPermissionCodes.tenantAdminDashboardView,
          TenantAdminPermissionCodes.dashboardOutletSummaryView,
          TenantAdminPermissionCodes.dashboardSalesSummaryView,
        ],
        features: [
          TenantAdminFeatureCodes.dashboard,
          TenantAdminFeatureCodes.outletManagement,
          TenantAdminFeatureCodes.sales,
        ],
      );

      final grid = tester.widget<DashboardMetricGrid>(
        find.byType(DashboardMetricGrid),
      );

      expect(grid.metrics.length, 2);
      expect(find.text("Today's Sales"), findsOneWidget);
      expect(find.text('Active Outlets'), findsOneWidget);
    });

    testWidgets('notification badge uses API count only when notification.view is granted',
        (tester) async {
      await _pumpDashboard(
        tester,
        permissions: [
          TenantAdminPermissionCodes.tenantAdminDashboardView,
          TenantAdminPermissionCodes.notificationView,
        ],
        features: [TenantAdminFeatureCodes.dashboard],
        notificationCount: 9,
      );

      expect(find.text('9'), findsOneWidget);
      expect(find.text('3'), findsNothing);
    });

    testWidgets('hides notification badge without notification.view', (tester) async {
      await _pumpDashboard(
        tester,
        permissions: [TenantAdminPermissionCodes.tenantAdminDashboardView],
        features: [TenantAdminFeatureCodes.dashboard],
        notificationCount: 9,
      );

      expect(find.text('9'), findsNothing);
    });
  });

  group('Tenant admin sidebar', () {
    testWidgets('renders only allowed sidebar items', (tester) async {
      final access = _buildAccess(
        permissions: [
          TenantAdminPermissionCodes.tenantAdminDashboardView,
          TenantAdminPermissionCodes.outletView,
        ],
        features: [
          TenantAdminFeatureCodes.dashboard,
          TenantAdminFeatureCodes.outletManagement,
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tenantAdminAccessCheckerProvider.overrideWith(
              (ref) async => access,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TenantAdminSidebar(
                items: _allMenuItems
                    .where(access.canAccessMenuItem)
                    .toList(growable: false),
                currentPath: '/tenant-admin/dashboard',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Outlets'), findsOneWidget);
      expect(find.text('Tills'), findsNothing);
      expect(find.text('Staff'), findsNothing);
    });

    testWidgets('hides Dashboard sidebar item without tenant_admin.dashboard.view',
        (tester) async {
      final access = _buildAccess(
        permissions: [TenantAdminPermissionCodes.outletView],
        features: [TenantAdminFeatureCodes.outletManagement],
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TenantAdminSidebar(
                items: _allMenuItems
                    .where(access.canAccessMenuItem)
                    .toList(growable: false),
                currentPath: '/tenant-admin/outlets',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Dashboard'), findsNothing);
      expect(find.text('Outlets'), findsOneWidget);
    });
  });
}

Future<void> _pumpDashboard(
  WidgetTester tester, {
  required List<String> permissions,
  required List<String> features,
  Size size = const Size(1200, 900),
  int notificationCount = 3,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);

  final context = _buildContext(
    permissions: permissions,
    features: features,
  );
  final access = TenantAdminAccessChecker(context);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tenantAdminContextProvider.overrideWith(
          (ref) async => context,
        ),
        tenantAdminAccessCheckerProvider.overrideWith(
          (ref) async => access,
        ),
        tenantDashboardProvider.overrideWith(
          (ref) async => _dashboard(notificationCount: notificationCount),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: TenantDashboardScreen(),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

TenantAdminAccessChecker _buildAccess({
  required List<String> permissions,
  required List<String> features,
  int outletCount = 3,
}) {
  return TenantAdminAccessChecker(
    _buildContext(
      permissions: permissions,
      features: features,
      outletCount: outletCount,
    ),
  );
}

TenantAdminContext _buildContext({
  required List<String> permissions,
  required List<String> features,
  int outletCount = 3,
}) {
  return TenantAdminContext(
    tenantId: 'tenant-test',
    tenantName: 'Coffee Corner Ltd',
    userId: 'user-test',
    userDisplayName: 'Sarah Ahmed',
    roleNames: ['Owner'],
    outletScope: [
      for (var index = 0; index < outletCount; index++)
        TenantAdminOutletScope(
          outletId: 'outlet-$index',
          outletName: 'Outlet $index',
          isDefault: index == 0,
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
  );
}

TenantDashboard _dashboard({required int notificationCount}) {
  return TenantDashboard(
    notificationCount: notificationCount,
    metrics: const [
      TenantDashboardMetric(
        key: 'sales',
        title: "Today's Sales",
        value: '£100',
      ),
      TenantDashboardMetric(
        key: 'outlets',
        title: 'Active Outlets',
        value: '5',
      ),
    ],
    salesThisWeek: null,
    needsAttention: const [],
    quickActions: const [
      TenantDashboardQuickAction(
        key: 'add-outlet',
        title: 'Add outlet',
        route: '/tenant-admin/outlets/add',
        featureCode: TenantAdminFeatureCodes.outletManagement,
        permissionCode: TenantAdminPermissionCodes.outletCreate,
      ),
    ],
    recentActivity: const [],
  );
}

const _allMenuItems = [
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
