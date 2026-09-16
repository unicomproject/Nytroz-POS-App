import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/domain/entities/hardware_device.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/providers/hardware_setup_controller.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/providers/hardware_dashboard_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/widgets/hardware_setup_review.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/widgets/hardware_setup_widgets.dart';

const device = HardwareDevice(hardwareDeviceId: 'd', hardwareDeviceCode: 'SC1', hardwareDeviceName: 'Front scanner', hardwareDeviceType: 'BARCODE_SCANNER', connectionType: 'USB', status: 'ACTIVE', outletId: 'o', outletName: 'Store', isAssigned: true);
class ReviewController extends HardwareSetupController {
  ReviewController(super.ref, int step) { state = HardwareSetupState(step: step, device: device); }
}
void main() {
  for (final size in [const Size(1024,768), const Size(1280,800), const Size(1366,768), const Size(1440,900)]) {
    for (final step in [3,4,5]) {
      testWidgets('review stage $step fits $size', (tester) async {
        tester.view.physicalSize = size; tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(ProviderScope(overrides: [
          hardwareSetupControllerProvider.overrideWith((ref) => ReviewController(ref,step)),
          hardwareDashboardProvider.overrideWith((ref, query) async => const HardwareDashboard([], {'d':'Ready'}, {'Ready':1}, 1)),
        ], child: const MaterialApp(home: Scaffold(body: HardwareSetupPage(title:'Hardware setup', child:HardwareSetupReview())))));
        await tester.pumpAndSettle();
        expect(tester.takeException(),isNull);
        if(step==3) expect(find.text('Select Till / POS and Assign'),findsOneWidget);
        if(step==4) expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton,'Complete Setup')).onPressed,isNotNull);
        if(step==5) expect(find.text('This device is configured, assigned and Ready according to the backend.'),findsOneWidget);
      });
    }
  }
  testWidgets('missing readiness never enables completion', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      hardwareSetupControllerProvider.overrideWith((ref) => ReviewController(ref,4)),
      hardwareDashboardProvider.overrideWith((ref, query) async => const HardwareDashboard([], {'d':'Unknown'}, {}, 1)),
    ], child: const MaterialApp(home: Scaffold(body: HardwareSetupPage(title:'Hardware setup', child:HardwareSetupReview())))));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton,'Complete Setup')).onPressed,isNull);
    expect(find.text('Test on POS required'),findsOneWidget);
  });
}
