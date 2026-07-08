import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/domain/entities/outlet_detail_entities.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/presentation/providers/outlet_detail_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/presentation/screens/outlet_details_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';

void main() {
  group('Outlet details screen', () {
    testWidgets('renders outlet detail tabs for full permissions',
        (tester) async {
      await _pumpOutletDetails(
        tester,
        permissions: _fullOutletPermissions,
        width: 1200,
      );

      expect(find.text('High Street Store'), findsWidgets);
      expect(find.text('Revenue'), findsOneWidget);
      expect(find.text('Assigned Users'), findsOneWidget);
      expect(find.text('Tills'), findsOneWidget);
      expect(find.text('Outlet Information'), findsOneWidget);
    });

    testWidgets('hides revenue tab without sales permission', (tester) async {
      await _pumpOutletDetails(
        tester,
        permissions: [
          TenantAdminPermissionCodes.outletView,
          TenantAdminPermissionCodes.outletDetailView,
          TenantAdminPermissionCodes.tillView,
          TenantAdminPermissionCodes.userView,
        ],
        width: 1200,
      );

      expect(find.text('High Street Store'), findsWidgets);
      expect(find.text('Revenue'), findsNothing);
      expect(find.text('Assigned Users'), findsOneWidget);
      expect(find.text('Tills'), findsOneWidget);
      expect(find.text('Outlet Information'), findsOneWidget);
    });
  });
}

const _fullOutletPermissions = [
  TenantAdminPermissionCodes.outletView,
  TenantAdminPermissionCodes.outletDetailView,
  TenantAdminPermissionCodes.tenantOutletsRevenueView,
  TenantAdminPermissionCodes.tenantOutletsUsersView,
  TenantAdminPermissionCodes.tenantOutletsTillsView,
  TenantAdminPermissionCodes.tenantOutletsUpdate,
  TenantAdminPermissionCodes.tillView,
  TenantAdminPermissionCodes.userView,
];

const _sampleOutletDetail = OutletDetail(
  outletId: 'outlet-1',
  outletName: 'High Street Store',
  outletCode: 'OUT-001',
  outletType: 'STORE',
  status: 'Active',
  addressLine1: '12 High Street',
  city: 'London',
  phoneNumber: '+44 7700 900123',
  emailAddress: 'outlet@coffeecorner.test',
  managerName: 'Aisha Khan',
  operatingHours: '08:00 – 20:00',
);

const _emptyRevenueSummary = OutletRevenueSummary(
  totalRevenue: 0,
  averageOrderValue: 0,
  totalOrders: 0,
  refunds: 0,
  revenueOverTime: [],
  revenueByPaymentMethod: [],
  revenueSummary: OutletRevenueBreakdown(
    grossRevenue: 0,
    discounts: 0,
    returns: 0,
    netRevenue: 0,
    taxCollected: 0,
  ),
);

const _emptyAssignedUsers = OutletAssignedUsersResult(
  summary: OutletAssignedUsersSummary(
    totalAssignedUsers: 0,
    activeUsers: 0,
    pendingInvites: 0,
    managers: 0,
  ),
  items: [],
);

const _emptyTills = OutletTillsDetailResult(
  summary: OutletTillsSummary(
    totalTills: 0,
    activeTills: 0,
    currentlyOpenTills: 0,
    tillsNeedingAttention: 0,
  ),
  items: [],
);

Future<void> _pumpOutletDetails(
  WidgetTester tester, {
  required List<String> permissions,
  double width = 900,
  double height = 1000,
}) async {
  final accessChecker = TenantAdminAccessChecker(
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
      featureEntitlements: const [
        TenantAdminFeatureEntitlement(
          featureCode: TenantAdminFeatureCodes.outletManagement,
          featureName: TenantAdminFeatureCodes.outletManagement,
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
      runtimeFlags: const [
        TenantAdminRuntimeFlag(
          featureCode: TenantAdminFeatureCodes.outletManagement,
          enabled: true,
        ),
      ],
    ),
  );

  await tester.binding.setSurfaceSize(Size(width, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tenantAdminAccessCheckerProvider.overrideWith(
          (ref) async => accessChecker,
        ),
        outletDetailProvider('outlet-1').overrideWith(
          (ref) async => _sampleOutletDetail,
        ),
        outletRevenueSummaryProvider('outlet-1').overrideWith(
          (ref) async => _emptyRevenueSummary,
        ),
        outletAssignedUsersProvider('outlet-1').overrideWith(
          (ref) async => _emptyAssignedUsers,
        ),
        outletTillsDetailProvider('outlet-1').overrideWith(
          (ref) async => _emptyTills,
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            child: const OutletDetailsScreen(outletId: 'outlet-1'),
          ),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}
