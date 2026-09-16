import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/screens/hardware_list_screen.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/providers/hardware_dashboard_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/providers/hardware_scope_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/domain/entities/hardware_device_list_item.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_access_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_context_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/tills/domain/entities/till.dart';
import 'hardware_master_wizard_test.dart' show hardwareTestAccess;

void main() {
  for (final width in [390.0, 1100.0, 1400.0, 1672.0]) {
    testWidgets(
        'hardware overview fits $width and selects sole authorized outlet',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? requestedOutlet;
      await tester.pumpWidget(ProviderScope(overrides: [
        tenantAdminContextProvider
            .overrideWith((ref) async => hardwareTestAccess().context),
        tenantAdminAccessCheckerProvider
            .overrideWith((ref) async => hardwareTestAccess()),
        hardwareOutletOptionsProvider.overrideWith((ref) async => [
              const OutletOption(
                  id: 'o',
                  name: 'Development Main Store',
                  code: 'MAIN',
                  status: 'ACTIVE')
            ]),
        hardwareDashboardProvider.overrideWith((ref, query) async {
          requestedOutlet = query.outletId;
          return const HardwareDashboard([
            HardwareDeviceListItem(
                hardwareDeviceId: 'printer',
                hardwareDeviceCode: 'P1',
                hardwareDeviceName: 'Receipt Printer',
                hardwareDeviceType: 'RECEIPT_PRINTER',
                connectionType: 'USB',
                status: 'ACTIVE',
                outletId: 'o',
                outletName: 'Development Main Store',
                isAssigned: true,
                model: 'XP-80T',
                assignedTillId: 't')
          ], {
            'printer': 'Unknown'
          }, {
            'Unknown': 1
          }, 1);
        }),
      ], child: const MaterialApp(home: Scaffold(body: HardwareListScreen()))));
      await tester.pumpAndSettle();
      expect(requestedOutlet, 'o');
      expect(find.text('Hardware Overview'), findsOneWidget);
      expect(find.text('Devices (1)'), findsOneWidget);
      expect(find.text('Hardware Health'), findsOneWidget);
      expect(find.text('Quick Tips'), findsOneWidget);
      expect(find.text('XP-80T'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
