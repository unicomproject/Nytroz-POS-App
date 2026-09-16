import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/screens/add_hardware_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/providers/hardware_scope_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/providers/hardware_setup_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/providers/hardware_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till.dart';
import 'hardware_master_wizard_test.dart' show hardwareTestAccess, usbProfile;
import 'hardware_scope_test.dart' show till;

void main() {
  testWidgets(
      'wizard requires an eligible till, preserves it, and rejects stale outlet',
      (tester) async {
    final container = ProviderContainer(overrides: [
      tenantAdminAccessCheckerProvider
          .overrideWith((ref) async => hardwareTestAccess()),
      hardwareOutletOptionsProvider.overrideWith((ref) async => [
            const OutletOption(
                id: 'o', name: 'Main', code: 'O', status: 'ACTIVE')
          ]),
      hardwareAssignableTillsProvider.overrideWith(
          (ref) async => [till('allowed', 'o'), till('other', 'outside')]),
      hardwareCompatibilityProvider
          .overrideWith((ref) async => [usbProfile, usbProfile]),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: AddHardwareScreen()))));
    await tester.pumpAndSettle();
    final c = container.read(hardwareSetupControllerProvider.notifier);
    c.outlet('o');
    await tester.pumpAndSettle();
    final select = find.widgetWithText(FilledButton, 'Select Device').first;
    expect(tester.widget<FilledButton>(select).onPressed, isNull);
    c.till('allowed');
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(select).onPressed, isNotNull);
    await tester.ensureVisible(select);
    await tester.tap(select);
    await tester.pumpAndSettle();
    expect(container.read(hardwareSetupControllerProvider).till, 'allowed');
    expect(find.widgetWithText(ChoiceChip, 'USB'), findsOneWidget);
    c.outlet('outside');
    await tester.pumpAndSettle();
    expect(container.read(hardwareSetupControllerProvider).till, isNull);
    expect(
        tester
            .widget<FilledButton>(
                find.widgetWithText(FilledButton, 'Select Device').first)
            .onPressed,
        isNull);
    expect(tester.takeException(), isNull);
  });
}
