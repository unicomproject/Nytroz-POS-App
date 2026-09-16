import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/services/hardware_setup_discovery_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/entities/tenant_admin_context.dart';
import 'package:nytroz_pos/features/tenant_admin/domain/services/tenant_admin_access_checker.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/data/models/hardware_compatibility_profile.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/providers/hardware_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/providers/hardware_scope_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/providers/hardware_setup_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/screens/add_hardware_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till.dart';

TenantAdminAccessChecker hardwareTestAccess({bool manage = true}) =>
    TenantAdminAccessChecker(const TenantAdminContext(
      tenantId: 't',
      tenantName: 'Tenant',
      userId: 'u',
      userDisplayName: 'User',
      roles: [],
      roleNames: [],
      outletScope: [],
      accessibleOutletIds: ['o'],
      featureEntitlements: [
        TenantAdminFeatureEntitlement(
            featureCode: 'hardware_device_management',
            featureName: 'Hardware',
            enabled: true)
      ],
      permissions: [
        TenantAdminPermission(
            permissionCode: 'tenant.hardware.manage', permissionName: 'Manage')
      ],
      runtimeFlags: [],
    ));
const usbProfile = HardwareCompatibilityProfile(
    id: 'usb',
    deviceType: 'RECEIPT_PRINTER',
    connectionType: 'USB',
    protocol: 'ESC/POS',
    adapterKey: 'usb_receipt_printer',
    supportLevel: 'UNVERIFIED',
    notes: 'Physical test required.');

void main() {
  test('stopped discovery cannot publish late devices or scan timestamp',
      () async {
    final discovery = _DelayedDiscovery();
    final container = ProviderContainer(overrides: [
      hardwareSetupDiscoveryProvider.overrideWithValue(discovery)
    ]);
    addTearDown(container.dispose);
    final subscription =
        container.listen(hardwareSetupControllerProvider, (_, __) {});
    addTearDown(subscription.close);
    final controller = container.read(hardwareSetupControllerProvider.notifier);
    final pending = controller.discover();
    controller.stop();
    discovery.result.complete(const HardwareDiscoveryResult(
        [DiscoveredHardware('Late printer', 'USB', {})], 'Completed'));
    await pending;
    expect(container.read(hardwareSetupControllerProvider).devices, isEmpty);
    expect(
        container.read(hardwareSetupControllerProvider).lastScannedAt, isNull);
  });
  test('type/outlet changes invalidate discovery/config; back preserves fields',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription =
        container.listen(hardwareSetupControllerProvider, (_, __) {});
    addTearDown(subscription.close);
    final c = container.read(hardwareSetupControllerProvider.notifier);
    c.outlet('o');
    c.choose(usbProfile);
    c.configure();
    c.field('name', 'Front printer');
    c.back();
    expect(container.read(hardwareSetupControllerProvider).fields['name'],
        'Front printer');
    c.outlet('other');
    expect(container.read(hardwareSetupControllerProvider).step, 0);
    expect(container.read(hardwareSetupControllerProvider).fields, isEmpty);
    c.choose(usbProfile);
    c.configure();
    c.complete(true);
    expect(container.read(hardwareSetupControllerProvider).step, 2,
        reason: 'Unsaved/unassigned setup cannot complete');
  });
  test('unsupported profile cannot advance and missing state starts first step',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final c = container.read(hardwareSetupControllerProvider.notifier);
    c.choose(const HardwareCompatibilityProfile(
        id: 'future',
        deviceType: 'CARD_READER',
        connectionType: 'PROVIDER',
        protocol: 'SDK',
        adapterKey: 'unavailable',
        supportLevel: 'UNSUPPORTED',
        notes: 'No provider'));
    expect(container.read(hardwareSetupControllerProvider).step, 0);
  });
  for (final size in [
    const Size(1024, 768),
    const Size(1280, 800),
    const Size(1366, 768),
    const Size(1440, 900)
  ]) {
    testWidgets('choose/discover/configure fits $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(overrides: [
        tenantAdminAccessCheckerProvider
            .overrideWith((ref) async => hardwareTestAccess()),
        hardwareCompatibilityProvider.overrideWith((ref) async => [usbProfile]),
        hardwareOutletOptionsProvider.overrideWith((ref) async => [
              const OutletOption(
                  id: 'o', name: 'Main Store', code: 'O1', status: 'ACTIVE')
            ]),
      ]);
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: AddHardwareScreen()))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final c = container.read(hardwareSetupControllerProvider.notifier);
      c.outlet('o');
      c.choose(usbProfile);
      await tester.pumpAndSettle();
      expect(find.text('Discover & Connect'), findsWidgets);
      expect(tester.takeException(), isNull);
      c.configure();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save & Continue'));
      await tester.tap(find.text('Save & Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Device Code is required'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('unavailable permission never shows setup mutations',
      (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      tenantAdminAccessCheckerProvider
          .overrideWith((ref) async => throw StateError('403'))
    ], child: const MaterialApp(home: Scaffold(body: AddHardwareScreen()))));
    await tester.pumpAndSettle();
    expect(
        find.text('Hardware management access is required.'), findsOneWidget);
    expect(find.text('Save & Continue'), findsNothing);
  });
}

class _DelayedDiscovery extends HardwareSetupDiscoveryService {
  final result = Completer<HardwareDiscoveryResult>();
  @override
  Future<HardwareDiscoveryResult> discover(String type, String connection) =>
      result.future;
}
