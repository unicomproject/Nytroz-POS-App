import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/domain/entities/outlet_details.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/presentation/providers/outlet_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/outlets/presentation/screens/outlet_details_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';

void main() {
  group('Outlet details screen', () {
    testWidgets('renders outlet panel sections for full permissions',
        (tester) async {
      await _pumpOutletDetails(
        tester,
        permissions: _fullOutletPermissions,
        width: 1200,
      );

      expect(find.text('High Street Store'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Tills'), findsWidgets);
      expect(find.text('Staff'), findsWidgets);
    });

    testWidgets('hides sales tab without sales permission', (tester) async {
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

      expect(find.text('High Street Store'), findsOneWidget);
      expect(find.text('Sales'), findsNothing);
    });
  });
}

const _fullOutletPermissions = [
  TenantAdminPermissionCodes.outletView,
  TenantAdminPermissionCodes.outletDetailView,
  TenantAdminPermissionCodes.outletTillSummaryView,
  TenantAdminPermissionCodes.outletStaffSummaryView,
  TenantAdminPermissionCodes.outletSalesSummaryView,
  TenantAdminPermissionCodes.outletUpdate,
  TenantAdminPermissionCodes.tillView,
  TenantAdminPermissionCodes.userView,
];

const _sampleOutletDetails = OutletDetails(
  id: 'outlet-1',
  name: 'High Street Store',
  code: 'OUT-001',
  address: '12 High Street, London',
  status: 'Active',
  phone: '+44 7700 900123',
  email: 'outlet@coffeecorner.test',
  managerName: 'Aisha Khan',
  openingHours: '08:00 – 20:00',
  todaysStatus: 'Operating as normal today',
  tillCount: 3,
  onlineTillCount: 2,
  staffCount: 4,
  todaySalesAmount: 1245.50,
  todaySalesCurrency: 'GBP',
  weekSalesAmount: 8920.30,
  weekSalesCurrency: 'GBP',
  assignedTills: [
    OutletRelatedItem(
      id: 'till-1',
      title: 'Front Counter Till',
      subtitle: 'TILL-001',
      status: 'Online',
    ),
  ],
  staff: [
    OutletRelatedItem(
      id: 'staff-1',
      title: 'Aisha Khan',
      subtitle: '+44 7700 900123',
      status: 'Manager',
    ),
  ],
  needsAttention: [
    OutletAttentionItem(
      title: '1 till offline',
      message: 'Back Office Till is offline',
      status: 'warning',
    ),
  ],
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
        TenantAdminRole(id: 'role-1', name: 'Owner'),
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
        outletDetailsProvider('outlet-1').overrideWith(
          (ref) async => _sampleOutletDetails,
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
