import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/tenant_admin_access_codes.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till_hardware_readiness.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till_monitoring.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/providers/till_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/screens/till_monitoring_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/widgets/till_monitoring_list.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/widgets/till_monitoring_side_panel.dart';

void main() {
  group('Till responsive layout polish', () {
    for (final viewport in _viewportCases) {
      testWidgets('keeps ${viewport.label} viewport overflow-free',
          (tester) async {
        await _pumpTillScreen(
          tester,
          size: viewport.size,
          itemCount: viewport.desktop ? 14 : 5,
        );

        expect(find.text('Tills'), findsOneWidget);
        expect(find.text('Front Till 01'), findsWidgets);
        expect(_hasFlutterOverflow(tester), isFalse);
      });
    }

    testWidgets('renders compact desktop KPI row and orange Add Till',
        (tester) async {
      await _pumpTillScreen(tester, size: const Size(1600, 900));

      expect(find.text('TOTAL TILLS'), findsOneWidget);
      expect(find.text('ONLINE'), findsOneWidget);
      expect(find.text('OFFLINE'), findsOneWidget);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(
        button.style?.backgroundColor?.resolve({}),
        TenantAdminColors.posHomeAccentOrange,
      );
      expect(_hasFlutterOverflow(tester), isFalse);
    });

    testWidgets('desktop master detail renders list and side panel',
        (tester) async {
      await _pumpTillScreen(
        tester,
        size: const Size(1366, 768),
        itemCount: 12,
      );

      expect(find.byType(TillMonitoringList), findsOneWidget);
      await tester.tap(find.text('Front Till 01').first);
      await tester.pumpAndSettle();
      
      expect(find.byType(TillMonitoringSidePanel), findsOneWidget);
      expect(find.text('Cashier'), findsOneWidget);
      expect(find.text('Hardware Connections'), findsOneWidget);
      expect(find.text('Back POS Device 03'), findsOneWidget);
      expect(_hasFlutterOverflow(tester), isFalse);
    });

    testWidgets('left till list owns scrolling in bounded desktop workspace',
        (tester) async {
      await _pumpTillScreen(
        tester,
        size: const Size(1280, 800),
        itemCount: 18,
      );

      final scrollableList = tester
          .widgetList<ListView>(find.byType(ListView))
          .firstWhere((listView) => listView.physics is ClampingScrollPhysics);

      expect(scrollableList.shrinkWrap, isFalse);
      expect(_hasFlutterOverflow(tester), isFalse);
    });

    testWidgets('selected till row uses orange visual state', (tester) async {
      await _pumpTillScreen(tester, size: const Size(1280, 800));

      await tester.tap(find.text('Front Till 01').first);
      await tester.pumpAndSettle();

      final hasOrangeSelectedBorder = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .any((widget) {
        final decoration = widget.decoration;
        if (decoration is! BoxDecoration) {
          return false;
        }

        final border = decoration.border;
        return border is Border &&
            border.left.color == TenantAdminColors.posHomeAccentOrange;
      });

      expect(hasOrangeSelectedBorder, isTrue);
    });

    testWidgets('filters wrap and preserve till row data on narrow widths',
        (tester) async {
      await _pumpTillScreen(tester, size: const Size(390, 844));

      expect(find.text('All'), findsWidgets);
      expect(find.text('Online'), findsWidgets);
      expect(find.text('Offline'), findsWidgets);
      expect(find.text('Needs attention'), findsOneWidget);
      expect(find.text('Front Till 01'), findsWidgets);
      expect(find.text('Development Main Store'), findsWidgets);
      expect(_hasFlutterOverflow(tester), isFalse);
    });
  });
}

Future<void> _pumpTillScreen(
  WidgetTester tester, {
  required Size size,
  int itemCount = 6,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final accessChecker = _checker(
    permissions: [
      TenantAdminPermissionCodes.tillView,
      TenantAdminPermissionCodes.tillCreate,
      TenantAdminPermissionCodes.tenantHardwareView,
    ],
    features: [TenantAdminFeatureCodes.tillManagement],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tenantAdminAccessCheckerProvider.overrideWith(
          (ref) async => accessChecker,
        ),
        tillListResultFutureProvider.overrideWith(
          (ref) async => TillMonitoringResult(
            items: _tillItems(itemCount),
            page: 1,
            pageSize: 10,
            totalCount: itemCount,
          ),
        ),
        tillSummaryFutureProvider.overrideWith(
          (ref) async => TillMonitoringSummary(
            totalTills: itemCount,
            onlineCount: 3,
            offlineCount: itemCount - 3,
            inactiveCount: 0,
            needsAttentionCount: 2,
          ),
        ),
        tillHardwareReadinessFutureProvider('till-0').overrideWith(
          (ref) async => _readiness,
        ),
        tillDetailProvider('till-0').overrideWith((ref) async => null),
      ],
      child: MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: size.width,
              height: size.height,
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

bool _hasFlutterOverflow(WidgetTester tester) {
  final exception = tester.takeException();
  if (exception == null) {
    return false;
  }

  return exception.toString().contains('RenderFlex overflowed');
}

List<TillMonitoringItem> _tillItems(int count) {
  return [
    for (var index = 0; index < count; index++)
      TillMonitoringItem(
        id: 'till-$index',
        outletId: 'outlet-1',
        outletName: index.isEven ? 'Development Main Store' : 'Main Outlet',
        name: index == 0 ? 'Front Till 01' : 'Back Till ${index + 1}',
        code: index == 0 ? 'FRONT-01' : 'BACK-${index + 1}',
        lifecycleStatus: TillLifecycleStatus.active,
        operationalStatus: index.isEven
            ? TillOperationalStatus.online
            : TillOperationalStatus.offline,
        displayStatus: switch (index % 3) {
          0 => TillDisplayStatus.needsAttention,
          1 => TillDisplayStatus.online,
          _ => TillDisplayStatus.offline,
        },
        needsAttention: index % 3 == 0,
        attentionReasonCount: index % 3 == 0 ? 1 : 0,
        currentCashierId: index.isEven ? 'cashier-$index' : null,
        currentCashierName: index.isEven ? 'Kavin' : null,
        assignedPosDeviceId: 'pos-$index',
        assignedPosDeviceName: 'Back POS Device ${index + 1}',
        isPosDeviceTrusted: true,
        lastActiveAt: DateTime(2026, 8, 10, 11, index),
        lastDeviceSeenAt: DateTime(2026, 8, 10, 11, index),
      ),
  ];
}

const _readiness = TillHardwareReadiness(
  tillId: 'till-0',
  tillName: 'Front Till 01',
  tillCode: 'FRONT-01',
  outletId: 'outlet-1',
  outletName: 'Development Main Store',
  lifecycleStatus: TillLifecycleStatus.active,
  operationalStatus: TillOperationalStatus.online,
  displayStatus: TillDisplayStatus.needsAttention,
  currentCashier: TillCurrentCashier(
    id: 'cashier-1',
    displayName: 'Kavin',
  ),
  assignedPosDevice: TillAssignedPosDevice(
    id: 'pos-3',
    deviceCode: 'POS-03',
    deviceName: 'Back POS Device 03',
    status: 'ACTIVE',
    isTrusted: true,
  ),
  lastActivityAt: null,
  hardwareConnections: [
    TillHardwareConnection(
      id: 'hw-1',
      code: 'PRT-1',
      name: 'Receipt Printer 01',
      type: 'RECEIPT_PRINTER',
      deviceStatus: 'ACTIVE',
      connectionStatus: TillHardwareConnectionStatus.connected,
    ),
  ],
  alertCount: 0,
  attentionReasons: [],
);

const _viewportCases = [
  _ViewportCase(label: '1920x1080 desktop', size: Size(1920, 1080)),
  _ViewportCase(label: '1600x900 desktop', size: Size(1600, 900)),
  _ViewportCase(label: '1366x768 laptop', size: Size(1366, 768)),
  _ViewportCase(label: '1280x800 desktop', size: Size(1280, 800)),
  _ViewportCase(label: '1024x768 tablet landscape', size: Size(1024, 768)),
  _ViewportCase(label: '820x1180 tablet portrait', size: Size(820, 1180)),
  _ViewportCase(label: '768x1024 tablet portrait', size: Size(768, 1024)),
  _ViewportCase(
    label: '390x844 mobile',
    size: Size(390, 844),
    desktop: false,
  ),
];

class _ViewportCase {
  const _ViewportCase({
    required this.label,
    required this.size,
    this.desktop = true,
  });

  final String label;
  final Size size;
  final bool desktop;
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
          outletName: 'Development Main Store',
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
