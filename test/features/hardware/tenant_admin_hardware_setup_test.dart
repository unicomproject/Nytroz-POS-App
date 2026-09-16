import 'hardware_master_wizard_test.dart' show hardwareTestAccess;
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till_monitoring.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/widgets/hardware_overview_components.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/providers/hardware_scope_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/providers/hardware_setup_controller.dart';
import 'package:dio/dio.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/providers/hardware_dashboard_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/data/models/hardware_compatibility_profile.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/providers/hardware_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/screens/add_hardware_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/presentation/providers/till_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/data/datasources/hardware_remote_datasource.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/providers/hardware_list_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/screens/hardware_list_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/domain/entities/hardware_device_list_item.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till_hardware_readiness.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';

void main() {
  test(
      'compatibility options come from the tenant API and preserve unsupported status',
      () async {
    final dio = Dio();
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      expect(
          options.path, '/api/v1/tenant-admin/hardware-devices/create-options');
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: {
        'data': {
          'compatibilityProfiles': [
            {
              'id': 'future-scale',
              'deviceType': 'SCALE',
              'connectionType': 'SERIAL',
              'protocol': 'UNSPECIFIED',
              'adapterKey': 'unavailable',
              'supportLevel': 'UNSUPPORTED',
              'notes': 'No runtime adapter',
            }
          ]
        }
      }));
    }));
    final profiles =
        await HardwareRemoteDataSourceImpl(dio).getCompatibilityProfiles();
    expect(profiles.single.canConfigure, isFalse);
  });

  testWidgets('unavailable catalog never enables device registration',
      (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      tenantAdminAccessCheckerProvider
          .overrideWith((ref) async => hardwareTestAccess()),
      hardwareOutletOptionsProvider.overrideWith((ref) async => [
            const OutletOption(
                id: 'o', name: 'Store', code: 'OUT1', status: 'ACTIVE')
          ]),
      hardwareCompatibilityProvider
          .overrideWith((ref) async => throw StateError('offline')),
      hardwareListProvider.overrideWith((ref) async => []),
      tillOutletOptionsProvider.overrideWith((ref) async => []),
    ], child: const MaterialApp(home: Scaffold(body: AddHardwareScreen()))));
    await tester.pumpAndSettle();
    expect(find.text('Cannot load device options. Retry'), findsOneWidget);
    expect(find.text('Select Device'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'tablet setup moves from category to discovery and validated configuration',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(overrides: [
      tenantAdminAccessCheckerProvider
          .overrideWith((ref) async => hardwareTestAccess()),
      hardwareOutletOptionsProvider.overrideWith((ref) async => [
            const OutletOption(
                id: 'o', name: 'Store', code: 'OUT1', status: 'ACTIVE')
          ]),
      hardwareCompatibilityProvider.overrideWith((ref) async => [
            const HardwareCompatibilityProfile(
                id: 'escpos-usb',
                deviceType: 'RECEIPT_PRINTER',
                connectionType: 'USB',
                protocol: 'ESC/POS',
                adapterKey: 'usb_receipt_printer',
                supportLevel: 'UNVERIFIED',
                notes: 'Physical verification required'),
          ]),
      hardwareAssignableTillsProvider.overrideWith((ref) async => [
            const TillMonitoringItem(
              id: 't',
              outletId: 'o',
              outletName: 'Store',
              name: 'Front Till',
              code: 'FRONT',
              lifecycleStatus: TillLifecycleStatus.active,
              operationalStatus: TillOperationalStatus.online,
              displayStatus: TillDisplayStatus.online,
              needsAttention: false,
              attentionReasonCount: 0,
            ),
          ]),
      hardwareListProvider.overrideWith((ref) async => []),
      tillOutletOptionsProvider.overrideWith((ref) async => [
            const OutletOption(
                id: 'o', name: 'Store', code: 'OUT1', status: 'ACTIVE'),
          ]),
    ], child: const MaterialApp(home: Scaffold(body: AddHardwareScreen()))));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
        tester.element(find.byType(AddHardwareScreen)));
    container.read(hardwareSetupControllerProvider.notifier).outlet('o');
    container.read(hardwareSetupControllerProvider.notifier).till('t');
    await tester.pumpAndSettle();
    expect(find.text('Unavailable'), findsNWidgets(5));
    await tester.tap(find.text('Select Device').first);
    await tester.pumpAndSettle();
    expect(find.text('Discover & Connect'), findsWidgets);
    await tester.tap(find.text('Configure manually'));
    await tester.pumpAndSettle();
    expect(find.text('Configure Device'), findsWidgets);
    await tester.ensureVisible(find.text('Save & Continue'));
    await tester.tap(find.text('Save & Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Device Code is required'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('all registry requests use existing Tenant Admin API routes', () async {
    final paths = <String>[];
    final dio = Dio();
    final device = {
      'hardwareDeviceId': 'device',
      'hardwareDeviceCode': 'PRN1',
      'hardwareDeviceName': 'Printer',
      'hardwareDeviceType': 'RECEIPT_PRINTER',
      'connectionType': 'USB',
      'status': 'ACTIVE',
      'outletId': 'outlet',
      'outletName': 'Store',
      'isAssigned': false,
    };
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      paths.add(options.path);
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: {
        'data': options.queryParameters.containsKey('page')
            ? {
                'items': [device]
              }
            : device
      }));
    }));
    final source = HardwareRemoteDataSourceImpl(dio);
    await source.getHardwareDevices(page: 1, pageSize: 5);
    await source.getHardwareDevice('device');
    await source.createHardwareDevice(device);
    await source.assignHardwareToTill('till', {});
    await source.assignHardwareToPosDevice('pos', {});
    await source.releaseHardwareAssignment('assignment', {});
    expect(paths, [
      '/api/v1/tenant-admin/hardware-devices',
      '/api/v1/tenant-admin/hardware-devices/device',
      '/api/v1/tenant-admin/hardware-devices',
      '/api/v1/tenant-admin/tills/till/hardware-assignments',
      '/api/v1/tenant-admin/pos-devices/pos/hardware-assignments',
      '/api/v1/tenant-admin/hardware-assignments/assignment/release',
    ]);
  });

  TillHardwareConnection evidence(
          TillHardwareConnectionStatus status, String? test) =>
      TillHardwareConnection(
          id: 'd',
          code: 'PRN',
          name: 'Printer',
          type: 'RECEIPT_PRINTER',
          deviceStatus: 'ACTIVE',
          connectionStatus: status,
          latestTest: test == null
              ? null
              : TillHardwareTest(
                  id: 'test',
                  testType: 'PRINT',
                  testStatus: test,
                  testedAt: DateTime.utc(2026, 9, 9)));
  test('assignment and lifecycle alone never imply ready', () {
    expect(hardwareReadinessLabel(false, null), 'Not Configured');
    expect(hardwareReadinessLabel(true, null), 'Unknown');
    expect(
        hardwareReadinessLabel(
            true, evidence(TillHardwareConnectionStatus.connected, null)),
        'Not Configured');
    expect(
        hardwareReadinessLabel(true,
            evidence(TillHardwareConnectionStatus.disconnected, 'PASSED')),
        'Disconnected');
    expect(
        hardwareReadinessLabel(
            true, evidence(TillHardwareConnectionStatus.connected, 'FAILED')),
        'Issues');
    expect(
        hardwareReadinessLabel(
            true, evidence(TillHardwareConnectionStatus.connected, 'PASSED')),
        'Ready');
  });

  testWidgets('tablet dashboard uses server pagination and search',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final devices = List.generate(
        7,
        (i) => HardwareDeviceListItem(
            hardwareDeviceId: '$i',
            hardwareDeviceCode: 'PRN$i',
            hardwareDeviceName: 'Printer $i',
            hardwareDeviceType: 'RECEIPT_PRINTER',
            connectionType: 'USB',
            status: 'ACTIVE',
            outletId: 'outlet',
            outletName: 'Store',
            isAssigned: false));
    await tester.pumpWidget(ProviderScope(overrides: [
      hardwareOutletOptionsProvider.overrideWith((ref) async => []),
      hardwareDashboardProvider.overrideWith((ref, query) async {
        final filtered = devices
            .where((d) => d.hardwareDeviceName.contains(query.search))
            .toList();
        return HardwareDashboard(
            filtered.skip((query.page - 1) * 5).take(5).toList(),
            {for (final d in filtered) d.hardwareDeviceId: 'Not Configured'},
            {'Not Configured': filtered.length},
            filtered.length);
      }),
      tenantAdminAccessCheckerProvider
          .overrideWith((ref) => throw StateError('no manage permission')),
    ], child: const MaterialApp(home: Scaffold(body: HardwareListScreen()))));
    await tester.pumpAndSettle();
    expect(find.text('Printer 0'), findsOneWidget);
    expect(find.text('Printer 5'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'Printer 6');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(HardwareOverviewDeviceTable, 'Printer 6'),
        findsOneWidget);
    expect(find.text('Printer 0'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
