import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/widgets/hardware_test_history.dart';

void main() {
  testWidgets('device activity shows saved event and no fabricated tests', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      hardwareActivityProvider('device').overrideWith((ref) async => [
        {'action':'ASSIGNED','occurredAt':'2026-09-13T00:00:00Z'},
      ]),
    ], child: const MaterialApp(home: Scaffold(body: HardwareActivityHistory(hardwareId:'device')))));
    await tester.pumpAndSettle();
    expect(find.text('ASSIGNED'), findsOneWidget);
    expect(find.textContaining('Passed'), findsNothing);
  });
  testWidgets('empty history does not imply physical success', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      hardwareTestHistoryProvider('device').overrideWith((ref) async => []),
    ], child: const MaterialApp(home: Scaffold(body: HardwareTestHistory(hardwareId: 'device', name: 'Printer')))));
    await tester.pumpAndSettle();
    expect(find.text('No test results recorded.'), findsOneWidget);
    expect(find.textContaining('Confirmed'), findsNothing);
  });
  testWidgets('recorded result keeps missing physical confirmation explicit', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      hardwareTestHistoryProvider('device').overrideWith((ref) async => [{
        'testType': 'PRINT', 'testStatus': 'PASSED', 'configurationVersion': 2,
        'testedAt': '2026-09-13T00:00:00Z', 'physicalConfirmation': null,
      }]),
    ], child: const MaterialApp(home: Scaffold(body: HardwareTestHistory(hardwareId: 'device', name: 'Printer')))));
    await tester.pumpAndSettle();
    expect(find.textContaining('Physical confirmation: Not reported'), findsOneWidget);
    expect(find.textContaining('Configuration version: 2'), findsOneWidget);
  });
}
