import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_menu_item.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till_monitoring.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/providers/till_providers.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till_hardware_readiness.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/widgets/till_monitoring_list.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/widgets/till_monitoring_side_panel.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/widgets/till_monitoring_row.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/widgets/tenant_admin_states.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/screens/add_till_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/screens/till_monitoring_screen.dart';

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

    testWidgets('Shows Tills Monitoring elements when permitted',
        (tester) async {
      await _pumpTillList(
        tester,
        permissions: [
          TenantAdminPermissionCodes.tillView,
          TenantAdminPermissionCodes.tenantHardwareView,
        ],
        features: [TenantAdminFeatureCodes.tillManagement],
        width: 1200,
      );

      expect(find.byType(TextField), findsWidgets);
      expect(find.byType(TenantAdminLoadingSkeleton), findsNothing);
      expect(find.byType(TillMonitoringRow), findsWidgets);
      expect(find.text('Front Counter Till'), findsWidgets);
      expect(find.byType(TillMonitoringSidePanel), findsOneWidget);
      expect(find.text('Hardware Connections'), findsOneWidget);
      expect(find.text('Cashier'), findsOneWidget);
      expect(find.text('Last Activity'), findsOneWidget);
      expect(find.text('POS Device'), findsOneWidget);
      expect(
        find.text('Monitor till status and hardware readiness.'),
        findsOneWidget,
      );
    });

    testWidgets('Desktop split keeps list and detail panes visible',
        (tester) async {
      await _pumpTillList(
        tester,
        permissions: [
          TenantAdminPermissionCodes.tillView,
          TenantAdminPermissionCodes.tenantHardwareView,
        ],
        features: [TenantAdminFeatureCodes.tillManagement],
        width: 1280,
      );

      expect(find.byType(TillMonitoringList), findsOneWidget);
      expect(find.byType(TillMonitoringSidePanel), findsOneWidget);
      expect(find.text('TOTAL TILLS'), findsOneWidget);
      expect(find.textContaining('Showing 1 to 1 of 1 tills'), findsOneWidget);
    });

    testWidgets('shows hardware permission state without hardware.view',
        (tester) async {
      await _pumpTillList(
        tester,
        permissions: [TenantAdminPermissionCodes.tillView],
        features: [TenantAdminFeatureCodes.tillManagement],
        width: 1200,
        includeHardwareReadiness: false,
      );

      expect(find.text('Front Counter Till'), findsWidgets);
      expect(
        find.text('You do not have permission to view hardware.'),
        findsOneWidget,
      );
      expect(find.text('Connected'), findsNothing);
    });

    testWidgets('renders real alert count and unassigned cashier fallback',
        (tester) async {
      await _pumpTillList(
        tester,
        permissions: [
          TenantAdminPermissionCodes.tillView,
          TenantAdminPermissionCodes.tenantHardwareView,
        ],
        features: [TenantAdminFeatureCodes.tillManagement],
        width: 1200,
        readiness: const TillHardwareReadiness(
          tillId: 'till-1',
          tillName: 'Front Counter Till',
          tillCode: 'TILL-001',
          outletId: 'outlet-1',
          outletName: 'High Street Store',
          lifecycleStatus: TillLifecycleStatus.active,
          operationalStatus: TillOperationalStatus.online,
          displayStatus: TillDisplayStatus.needsAttention,
          currentCashier: null,
          lastActivityAt: null,
          hardwareConnections: [
            TillHardwareConnection(
              id: 'hw-1',
              code: 'PRT-1',
              name: 'Store Printer',
              type: 'RECEIPT_PRINTER',
              deviceStatus: 'ACTIVE',
              connectionStatus: TillHardwareConnectionStatus.needsAttention,
              warningMessage: 'Latest hardware test reported a warning.',
            ),
          ],
          alertCount: 2,
          attentionReasons: [
            TillAttentionReason(
              code: 'HARDWARE_TEST_WARNING',
              severity: TillAlertSeverity.warning,
              message: 'Latest hardware test reported a warning.',
            ),
            TillAttentionReason(
              code: 'HARDWARE_HEARTBEAT_EXPIRED',
              severity: TillAlertSeverity.error,
              message: 'Hardware heartbeat expired.',
            ),
          ],
        ),
      );

      expect(find.text('Unassigned'), findsOneWidget);
      expect(find.text('No recent activity'), findsOneWidget);
      expect(find.text('View Alerts (2)'), findsOneWidget);
      expect(find.text('Needs Attention'), findsWidgets);
      expect(find.text('Receipt Printer'), findsOneWidget);
    });

    testWidgets('shows Add Till when create permission exists', (tester) async {
      await _pumpTillList(
        tester,
        permissions: [
          TenantAdminPermissionCodes.tillView,
          TenantAdminPermissionCodes.tillCreate,
          TenantAdminPermissionCodes.tenantHardwareView,
        ],
        features: [TenantAdminFeatureCodes.tillManagement],
        width: 1200,
      );

      expect(find.text('Add Till'), findsOneWidget);
    });

    testWidgets('hides Add Till when create permission is missing',
        (tester) async {
      await _pumpTillList(
        tester,
        permissions: [
          TenantAdminPermissionCodes.tillView,
          TenantAdminPermissionCodes.tenantHardwareView,
        ],
        features: [TenantAdminFeatureCodes.tillManagement],
        width: 1200,
      );

      expect(find.text('Add Till'), findsNothing);
    });

    testWidgets('mobile hides side panel', (tester) async {
      await _pumpTillList(
        tester,
        permissions: [
          TenantAdminPermissionCodes.tillView,
          TenantAdminPermissionCodes.tenantHardwareView,
        ],
        features: [TenantAdminFeatureCodes.tillManagement],
        width: 390,
      );

      expect(find.byType(TillMonitoringList), findsOneWidget);
      expect(find.byType(TillMonitoringSidePanel), findsNothing);
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
  bool includeHardwareReadiness = true,
  TillHardwareReadiness? readiness,
}) async {
  final accessChecker = _checker(
    permissions: permissions,
    features: features,
  );

  await tester.binding.setSurfaceSize(Size(width, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final overrides = <Override>[
    tenantAdminAccessCheckerProvider.overrideWith(
      (ref) async => accessChecker,
    ),
    tillListResultFutureProvider.overrideWith(
      (ref) async => const TillMonitoringResult(
        items: [
          TillMonitoringItem(
            id: 'till-1',
            outletId: 'outlet-1',
            outletName: 'High Street Store',
            name: 'Front Counter Till',
            code: 'TILL-001',
            lifecycleStatus: TillLifecycleStatus.active,
            operationalStatus: TillOperationalStatus.online,
            displayStatus: TillDisplayStatus.online,
            needsAttention: false,
            attentionReasonCount: 0,
          ),
        ],
        page: 1,
        pageSize: 10,
        totalCount: 1,
      ),
    ),
    tillSummaryFutureProvider.overrideWith(
      (ref) async => const TillMonitoringSummary(
        totalTills: 1,
        onlineCount: 1,
        offlineCount: 0,
        inactiveCount: 0,
        needsAttentionCount: 0,
      ),
    ),
  ];

  if (includeHardwareReadiness) {
    overrides.add(
      tillHardwareReadinessFutureProvider('till-1').overrideWith(
        (ref) async =>
            readiness ??
            const TillHardwareReadiness(
              tillId: 'till-1',
              tillName: 'Front Counter Till',
              tillCode: 'TILL-001',
              outletId: 'outlet-1',
              outletName: 'High Street Store',
              lifecycleStatus: TillLifecycleStatus.active,
              operationalStatus: TillOperationalStatus.online,
              displayStatus: TillDisplayStatus.online,
              currentCashier: TillCurrentCashier(
                id: 'cashier-1',
                displayName: 'Test Cashier',
              ),
              lastActivityAt: null,
              assignedPosDevice: TillAssignedPosDevice(
                id: 'pos-1',
                deviceCode: 'POS-1',
                deviceName: 'Counter Tablet',
                status: 'ACTIVE',
                isTrusted: true,
              ),
              hardwareConnections: [
                TillHardwareConnection(
                  id: 'hw-1',
                  code: 'SCAN-1',
                  name: 'Counter Scanner',
                  type: 'BARCODE_SCANNER',
                  deviceStatus: 'ACTIVE',
                  connectionStatus: TillHardwareConnectionStatus.connected,
                ),
              ],
              alertCount: 0,
              attentionReasons: [],
            ),
      ),
    );
  }

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MediaQuery(
        data: MediaQueryData(size: Size(width, height)),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: width,
              height: height,
              child: const TillMonitoringScreen(),
            ),
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
      roleNames: const ['Owner'],
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
