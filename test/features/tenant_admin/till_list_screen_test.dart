import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_menu_item.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/providers/till_visibility_provider.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/screens/add_till_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/screens/till_list_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/widgets/till_action_menu.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/widgets/till_sales_display.dart';

void main() {
  group('Till list screen', () {
    testWidgets('shows unauthorized state when till.view is missing',
        (tester) async {
      await _pumpTillList(
        tester,
        permissions: [TenantAdminPermissionCodes.tenantAdminDashboardView],
        features: [TenantAdminFeatureCodes.dashboard],
      );

      expect(find.text('No access to Tills'), findsOneWidget);
      expect(find.text('Front Counter Till'), findsNothing);
    });

    testWidgets('AddTillButton_Hidden_WhenTillCreatePermissionMissing',
        (tester) async {
      await _pumpTillList(
        tester,
        permissions: [TenantAdminPermissionCodes.tillView],
        features: [TenantAdminFeatureCodes.tillManagement],
        width: 1200,
      );

      expect(find.text('Add till'), findsNothing);
      expect(find.text('Front Counter Till'), findsOneWidget);
    });

    testWidgets('AddTillButton_Visible_WhenTillCreatePermissionExists',
        (tester) async {
      await _pumpTillList(
        tester,
        permissions: [
          TenantAdminPermissionCodes.tillView,
          TenantAdminPermissionCodes.tillCreate,
        ],
        features: [TenantAdminFeatureCodes.tillManagement],
        width: 1200,
      );

      expect(find.text('Add New Till'), findsOneWidget);
    });

    testWidgets('Header_RemainsAligned_WhenAddTillButtonHidden',
        (tester) async {
      await _pumpTillList(
        tester,
        permissions: [TenantAdminPermissionCodes.tillView],
        features: [TenantAdminFeatureCodes.tillManagement],
        width: 1200,
      );

      expect(find.text('Search tills by name, code or outlet'), findsOneWidget);
      expect(find.text('Add till'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('EditButton_Hidden_WhenTillUpdatePermissionMissing',
        (tester) async {
      await _pumpTillList(
        tester,
        permissions: [TenantAdminPermissionCodes.tillView],
        features: [TenantAdminFeatureCodes.tillManagement],
        width: 1200,
      );

      expect(find.text('Edit'), findsNothing);
      expect(find.byTooltip('View details'), findsOneWidget);
    });

    testWidgets('EditButton_Visible_WhenTillUpdatePermissionExists',
        (tester) async {
      await _pumpTillList(
        tester,
        permissions: [
          TenantAdminPermissionCodes.tillView,
          TenantAdminPermissionCodes.tillUpdate,
        ],
        features: [TenantAdminFeatureCodes.tillManagement],
        width: 1200,
      );

      expect(find.byTooltip('Edit'), findsOneWidget);
    });

    testWidgets('RowActions_RemainAligned_WhenEditPermissionMissing',
        (tester) async {
      await _pumpTillList(
        tester,
        permissions: [TenantAdminPermissionCodes.tillView],
        features: [TenantAdminFeatureCodes.tillManagement],
        width: 1200,
      );

      expect(find.byTooltip('View details'), findsOneWidget);
      expect(find.byType(TillActionMenu), findsNothing);
    });

    testWidgets('MoreMenu_DoesNotReserveSpace_WhenNoActionsAvailable',
        (tester) async {
      await _pumpTillList(
        tester,
        permissions: [TenantAdminPermissionCodes.tillView],
        features: [TenantAdminFeatureCodes.tillManagement],
        width: 1200,
      );

      expect(find.byType(TillActionMenu), findsNothing);
      expect(find.byIcon(Icons.more_vert), findsNothing);
    });

    testWidgets('TodaySales_Hidden_WhenSalesPermissionMissing', (tester) async {
      await _pumpTillList(
        tester,
        permissions: [TenantAdminPermissionCodes.tillView],
        features: [TenantAdminFeatureCodes.tillManagement],
        width: 1200,
      );

      expect(find.text("Today's sales"), findsNothing);
      expect(find.byType(TillSalesDisplay), findsNothing);
    });

    testWidgets('TodaySales_Visible_WhenSalesPermissionExists', (tester) async {
      await _pumpTillList(
        tester,
        permissions: [
          TenantAdminPermissionCodes.tillView,
          'sales.summary.view',
        ],
        features: [TenantAdminFeatureCodes.tillManagement],
        width: 390,
        height: 1200,
        includeSales: true,
      );

      expect(find.text("Today's sales"), findsOneWidget);
    });

    testWidgets('SalesColumn_Removed_WhenSalesPermissionMissing',
        (tester) async {
      await _pumpTillList(
        tester,
        permissions: [TenantAdminPermissionCodes.tillView],
        features: [TenantAdminFeatureCodes.tillManagement],
        width: 1200,
      );

      expect(find.text('Rs 1245.60'), findsNothing);
    });

    testWidgets('TillsMenu_Hidden_WhenTillManagementFeatureMissing',
        (tester) async {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tillView],
        features: [TenantAdminFeatureCodes.dashboard],
      );
      const menuItem = TenantAdminMenuItem(
        key: 'tills',
        label: 'Tills',
        route: '/tenant-admin/tills',
        iconKey: 'till',
        featureCode: TenantAdminFeatureCodes.tillManagement,
        permissionCode: TenantAdminPermissionCodes.tillView,
        visible: true,
        order: 3,
      );

      expect(access.canAccessMenuItem(menuItem), isFalse);
    });

    testWidgets('TillsMenu_Visible_WhenFeatureAndTillViewExist',
        (tester) async {
      final access = _checker(
        permissions: [TenantAdminPermissionCodes.tillView],
        features: [TenantAdminFeatureCodes.tillManagement],
      );
      const menuItem = TenantAdminMenuItem(
        key: 'tills',
        label: 'Tills',
        route: '/tenant-admin/tills',
        iconKey: 'till',
        featureCode: TenantAdminFeatureCodes.tillManagement,
        permissionCode: TenantAdminPermissionCodes.tillView,
        visible: true,
        order: 3,
      );

      expect(access.canAccessMenuItem(menuItem), isTrue);
    });
  });

  group('Add till screen', () {
    testWidgets('CreateTill_DoesNotRenderForm_WhenTillCreatePermissionMissing',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDioProvider.overrideWithValue(Dio()),
            tenantAdminAccessCheckerProvider.overrideWith(
              (ref) async => _checker(
                permissions: [TenantAdminPermissionCodes.tillView],
                features: [TenantAdminFeatureCodes.tillManagement],
              ),
            ),
            tillOutletOptionsProvider.overrideWith(
              (ref) async => const [],
            ),
          ],
          child: const MaterialApp(home: AddTillScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No access'), findsWidgets);
      expect(find.text('Till name'), findsNothing);
    });
  });
}

Future<void> _pumpTillList(
  WidgetTester tester, {
  required List<String> permissions,
  required List<String> features,
  double width = 800,
  double height = 900,
  bool includeSales = false,
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
        tillListProvider.overrideWith(
          (ref) async => TillListResult(
            summary: const TillListSummary(
              totalTills: 1,
              onlineCount: 1,
              offlineCount: 0,
              needsAttentionCount: 0,
            ),
            items: [
              Till(
                id: 'till-1',
                outletId: 'outlet-1',
                outletName: 'High Street Store',
                name: 'Front Counter Till',
                code: 'TILL-001',
                status: 'active',
                operationalStatus: 'online',
                todaySalesAmount: includeSales ? 1245.60 : null,
                currency: includeSales ? 'LKR' : null,
                lastSyncAt: includeSales ? DateTime(2026, 6, 22, 10, 0) : null,
              ),
            ],
            page: 1,
            pageSize: 10,
            totalCount: 1,
          ),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: width,
            height: height,
            child: const TillListScreen(),
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
      roles: const [
        TenantAdminRoleScope(roleId: 'role-1', roleName: 'Owner'),
      ],
      roleNames: const ['Owner'],
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
