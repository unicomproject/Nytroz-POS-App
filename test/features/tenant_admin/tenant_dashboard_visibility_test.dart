import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/dashboard/domain/entities/tenant_dashboard.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_menu_item.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/layout/tenant_admin_bottom_nav.dart';

void main() {
  group('TenantDashboardVisibility', () {
    test('blocks dashboard page without tenant_admin.dashboard.view', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.outletView],
        features: [TenantAdminFeatureCodes.outletManagement],
      );

      final visibility = TenantDashboardVisibility.resolve(access: access);

      expect(visibility.showTitle, isFalse);
    });

    test('shows Today\'s Sales when dashboard.sales_summary.view is granted', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.tenantAdminDashboardView,
          TenantAdminPermissionCodes.dashboardSalesSummaryView,
        ],
        features: [
          TenantAdminFeatureCodes.dashboard,
          TenantAdminFeatureCodes.sales,
        ],
      );

      final visibility = TenantDashboardVisibility.resolve(
        access: access,
        dashboard: _sampleDashboard(),
      );

      expect(
        visibility.visibleMetrics.any((metric) => metric.key == 'sales'),
        isTrue,
      );
    });

    test('accepts legacy sales.summary.view for Today\'s Sales metric', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.tenantAdminDashboardView,
          'sales.summary.view',
        ],
        features: [TenantAdminFeatureCodes.dashboard],
      );

      final visibility = TenantDashboardVisibility.resolve(
        access: access,
        dashboard: _sampleDashboard(),
      );

      expect(
        visibility.visibleMetrics.any((metric) => metric.key == 'sales'),
        isTrue,
      );
    });

    test('hides Today\'s Sales without sales summary permissions', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tenantAdminDashboardView],
        features: [TenantAdminFeatureCodes.dashboard],
      );

      final visibility = TenantDashboardVisibility.resolve(
        access: access,
        dashboard: _sampleDashboard(),
      );

      expect(
        visibility.visibleMetrics.any((metric) => metric.key == 'sales'),
        isFalse,
      );
    });

    test('shows Add outlet quick action when outlet.create is granted', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.tenantAdminDashboardView,
          TenantAdminPermissionCodes.outletCreate,
        ],
        features: [
          TenantAdminFeatureCodes.dashboard,
          TenantAdminFeatureCodes.outletManagement,
        ],
      );

      final visibility = TenantDashboardVisibility.resolve(
        access: access,
        dashboard: _sampleDashboard(),
      );

      expect(
        visibility.visibleQuickActions.any((action) => action.key == 'add-outlet'),
        isTrue,
      );
    });

    test('shows only Add Product when product.create is granted', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.tenantAdminDashboardView,
          TenantAdminPermissionCodes.productCreate,
        ],
        features: [
          TenantAdminFeatureCodes.dashboard,
          TenantAdminFeatureCodes.productManagement,
        ],
      );

      final visibility = TenantDashboardVisibility.resolve(
        access: access,
        dashboard: _sampleDashboard(),
      );

      expect(visibility.visibleQuickActions.length, 1);
      expect(visibility.visibleQuickActions.first.key, 'add-product');
    });

    test('hides Needs Attention without dashboard.attention.view', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.tenantAdminDashboardView,
          TenantAdminPermissionCodes.tillStatusView,
        ],
        features: [TenantAdminFeatureCodes.dashboard],
      );

      final visibility = TenantDashboardVisibility.resolve(
        access: access,
        dashboard: _sampleDashboard(),
      );

      expect(visibility.showNeedsAttentionSection, isFalse);
      expect(visibility.visibleAttentionItems, isEmpty);
    });

    test('filters Needs Attention items by item permissions', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.tenantAdminDashboardView,
          TenantAdminPermissionCodes.dashboardAttentionView,
          TenantAdminPermissionCodes.inventoryAlertView,
        ],
        features: [
          TenantAdminFeatureCodes.dashboard,
          TenantAdminFeatureCodes.inventoryManagement,
        ],
      );

      final visibility = TenantDashboardVisibility.resolve(
        access: access,
        dashboard: _sampleDashboard(),
      );

      expect(visibility.showNeedsAttentionSection, isTrue);
      expect(visibility.visibleAttentionItems.length, 1);
      expect(visibility.visibleAttentionItems.first.key, 'low_stock');
    });

    test('shows stock metric and low stock alert with partial permissions', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.tenantAdminDashboardView,
          TenantAdminPermissionCodes.dashboardStockAlertsView,
          TenantAdminPermissionCodes.dashboardAttentionView,
          TenantAdminPermissionCodes.inventoryAlertView,
        ],
        features: [
          TenantAdminFeatureCodes.dashboard,
          TenantAdminFeatureCodes.inventoryManagement,
        ],
      );

      final visibility = TenantDashboardVisibility.resolve(
        access: access,
        dashboard: _sampleDashboard(),
      );

      expect(
        visibility.visibleMetrics.any((metric) => metric.key == 'stock'),
        isTrue,
      );
      expect(
        visibility.visibleAttentionItems.any((item) => item.key == 'low_stock'),
        isTrue,
      );
    });

    test('shows Recent Activity section with activity_log.view even when empty',
        () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.tenantAdminDashboardView,
          TenantAdminPermissionCodes.activityLogView,
        ],
        features: [TenantAdminFeatureCodes.dashboard],
      );

      final visibility = TenantDashboardVisibility.resolve(
        access: access,
        dashboard: _sampleDashboard(recentActivity: const []),
      );

      expect(visibility.showRecentActivitySection, isTrue);
      expect(visibility.visibleActivities, isEmpty);
    });

    test('KPI section reflows to visible cards only', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.tenantAdminDashboardView,
          TenantAdminPermissionCodes.dashboardOutletSummaryView,
        ],
        features: [
          TenantAdminFeatureCodes.dashboard,
          TenantAdminFeatureCodes.outletManagement,
        ],
      );

      final visibility = TenantDashboardVisibility.resolve(
        access: access,
        dashboard: _sampleDashboard(),
      );

      expect(visibility.visibleMetrics.length, 1);
      expect(visibility.visibleMetrics.first.key, 'outlets');
      expect(visibility.showKpiSection, isTrue);
    });

    test('hides notification count without notification.view', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tenantAdminDashboardView],
        features: [TenantAdminFeatureCodes.dashboard],
      );

      final visibility = TenantDashboardVisibility.resolve(
        access: access,
        dashboard: _sampleDashboard(notificationCount: 7),
      );

      expect(visibility.showNotifications, isFalse);
      expect(visibility.notificationCount, isNull);
    });

    test('uses notification count from dashboard payload when allowed', () {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.tenantAdminDashboardView,
          TenantAdminPermissionCodes.notificationView,
        ],
        features: [TenantAdminFeatureCodes.dashboard],
      );

      final visibility = TenantDashboardVisibility.resolve(
        access: access,
        dashboard: _sampleDashboard(notificationCount: 7),
      );

      expect(visibility.notificationCount, 7);
    });
  });

  group('TenantAdminAccessChecker navigation', () {
    test('dashboard route requires tenant_admin.dashboard.view', () {
      final allowed = _checker(
        permissions: [TenantAdminPermissionCodes.tenantAdminDashboardView],
        features: [TenantAdminFeatureCodes.dashboard],
      );
      final denied = _checker(
        permissions: [],
        features: [TenantAdminFeatureCodes.dashboard],
      );

      expect(allowed.canAccessDashboardRoute(), isTrue);
      expect(denied.canAccessDashboardRoute(), isFalse);
    });

    test('dashboard data fetch requires at least one widget permission', () {
      final allowed = _checker(
        permissions: [TenantAdminPermissionCodes.dashboardSalesSummaryView],
        features: [TenantAdminFeatureCodes.dashboard],
      );
      final denied = _checker(
        permissions: [TenantAdminPermissionCodes.tenantAdminDashboardView],
        features: [TenantAdminFeatureCodes.dashboard],
      );

      expect(allowed.canLoadDashboardData(), isTrue);
      expect(denied.canLoadDashboardData(), isFalse);
    });

    test('sidebar hides dashboard without tenant_admin.dashboard.view', () {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.outletView],
        features: [TenantAdminFeatureCodes.outletManagement],
      );

      final visibleItems =
          _menuItems.where(access.canAccessMenuItem).toList(growable: false);

      expect(visibleItems.any((item) => item.key == 'dashboard'), isFalse);
      expect(visibleItems.any((item) => item.key == 'outlets'), isTrue);
    });

    test('roles menu visible with role.view or permission.view', () {
      final roleOnly = _checker(
        permissions: [TenantAdminPermissionCodes.roleView],
        features: [TenantAdminFeatureCodes.rolePermission],
      );
      final permissionOnly = _checker(
        permissions: [TenantAdminPermissionCodes.permissionView],
        features: [TenantAdminFeatureCodes.rolePermission],
      );
      final denied = _checker(
        permissions: [TenantAdminPermissionCodes.outletView],
        features: [TenantAdminFeatureCodes.rolePermission],
      );

      expect(
        _rolesMenuItem.visible && roleOnly.canAccessMenuItem(_rolesMenuItem),
        isTrue,
      );
      expect(
        permissionOnly.canAccessMenuItem(_rolesMenuItem),
        isTrue,
      );
      expect(denied.canAccessMenuItem(_rolesMenuItem), isFalse);
    });

    test('billing menu visible with billing.view or subscription.view', () {
      final billing = _checker(
        permissions: [TenantAdminPermissionCodes.billingView],
        features: [TenantAdminFeatureCodes.billingSubscription],
      );
      final subscription = _checker(
        permissions: [TenantAdminPermissionCodes.subscriptionView],
        features: [TenantAdminFeatureCodes.billingSubscription],
      );

      expect(billing.canAccessMenuItem(_billingMenuItem), isTrue);
      expect(subscription.canAccessMenuItem(_billingMenuItem), isTrue);
    });
  });

  group('Tenant admin bottom navigation', () {
    testWidgets('filters restricted bottom nav items', (tester) async {
      final access = _checker(
        permissions: [
          TenantAdminPermissionCodes.tenantAdminDashboardView,
          TenantAdminPermissionCodes.outletView,
        ],
        features: [
          TenantAdminFeatureCodes.dashboard,
          TenantAdminFeatureCodes.outletManagement,
        ],
      );

      final visibleItems = _menuItems
          .where(access.canAccessMenuItem)
          .toList(growable: false)
        ..sort((first, second) => first.order.compareTo(second.order));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: TenantAdminBottomNav(
              items: visibleItems,
              currentPath: '/tenant-admin/dashboard',
            ),
          ),
        ),
      );

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Outlets'), findsOneWidget);
      expect(find.text('Tills'), findsNothing);
      expect(find.text('Staff'), findsNothing);
    });

    testWidgets('does not crash when permission list is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: TenantAdminBottomNav(
              items: const [],
              currentPath: '/tenant-admin/dashboard',
            ),
          ),
        ),
      );

      expect(find.byType(BottomNavigationBar), findsNothing);
    });
  });
}

TenantAdminAccessChecker _checker({
  required List<String> permissions,
  required List<String> features,
  int outletCount = 2,
}) {
  return TenantAdminAccessChecker(
    TenantAdminContext(
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
      subscriptionStatus: 'Professional',
    ),
  );
}

TenantDashboard _sampleDashboard({
  int notificationCount = 3,
  List<TenantDashboardActivity> recentActivity = const [
    TenantDashboardActivity(
      key: 'outlet',
      title: 'New outlet added',
      timeLabel: 'Today',
    ),
  ],
}) {
  return TenantDashboard(
    notificationCount: notificationCount,
    metrics: const [
      TenantDashboardMetric(
        key: 'sales',
        title: "Today's Sales",
        value: '£100',
      ),
      TenantDashboardMetric(
        key: 'orders',
        title: 'Orders',
        value: '10',
      ),
      TenantDashboardMetric(
        key: 'outlets',
        title: 'Active Outlets',
        value: '5',
      ),
      TenantDashboardMetric(
        key: 'stock',
        title: 'Stock Alerts',
        value: '14',
      ),
    ],
    salesThisWeek: const TenantDashboardSalesSummary(
      title: 'Sales this week',
      total: '£1,000',
      points: [],
    ),
    needsAttention: const [
      TenantDashboardAttentionItem(
        key: 'offline_tills',
        title: '2 tills are offline',
        message: 'Bring them back online',
      ),
      TenantDashboardAttentionItem(
        key: 'low_stock',
        title: '14 low stock items',
        message: 'Restock soon',
      ),
    ],
    quickActions: const [
      TenantDashboardQuickAction(
        key: 'add-outlet',
        title: 'Add outlet',
        route: '/tenant-admin/outlets/add',
        featureCode: TenantAdminFeatureCodes.outletManagement,
        permissionCode: TenantAdminPermissionCodes.outletCreate,
      ),
      TenantDashboardQuickAction(
        key: 'add-till',
        title: 'Add till',
        route: '/tenant-admin/tills/add',
        featureCode: TenantAdminFeatureCodes.tillManagement,
        permissionCode: TenantAdminPermissionCodes.tillCreate,
      ),
      TenantDashboardQuickAction(
        key: 'add-product',
        title: 'Add product',
        route: '/tenant-admin/products/add',
        featureCode: TenantAdminFeatureCodes.productManagement,
        permissionCode: TenantAdminPermissionCodes.productCreate,
      ),
    ],
    recentActivity: recentActivity,
  );
}

const _rolesMenuItem = TenantAdminMenuItem(
  key: 'roles-access',
  label: 'Roles & Access',
  route: '/tenant-admin/roles',
  iconKey: 'shield',
  featureCode: TenantAdminFeatureCodes.rolePermission,
  permissionCode: TenantAdminPermissionCodes.roleView,
  visible: true,
  order: 5,
);

const _billingMenuItem = TenantAdminMenuItem(
  key: 'billing',
  label: 'Billing',
  route: '/tenant-admin/billing',
  iconKey: 'billing',
  featureCode: TenantAdminFeatureCodes.billingSubscription,
  permissionCode: TenantAdminPermissionCodes.billingView,
  visible: true,
  order: 9,
);

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
  _rolesMenuItem,
  _billingMenuItem,
];
