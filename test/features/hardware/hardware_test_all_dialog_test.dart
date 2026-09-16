import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/widgets/hardware_test_all_dialog.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/providers/hardware_scope_provider.dart';
import 'hardware_scope_test.dart' show till;

void main() {
  testWidgets('Test All submits only selected outlet till and displays server evidence', (tester) async {
    final requests = <RequestOptions>[];
    final dio = Dio(BaseOptions(baseUrl: 'http://test.invalid'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (request, handler) {
      requests.add(request);
      handler.resolve(Response(requestOptions: request, data: {'data': {
        'id': 'batch', 'status': 'PASSED', 'expiresAt': '2026-09-16T10:00:00Z',
        'items': [{'id': 'printer', 'name': 'Test printer', 'status': 'PASSED'}]
      }}));
    }));
    await tester.pumpWidget(ProviderScope(overrides: [
      appDioProvider.overrideWithValue(dio),
      hardwareAssignableTillsProvider.overrideWith((ref) async => [till('allowed','o'),till('foreign','other')]),
    ], child: const MaterialApp(home: Scaffold(body: HardwareTestAllDialog(outletId: 'o')))));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton,'Send Test All request')).onPressed,isNull);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('foreign (foreign)'),findsNothing);
    await tester.tap(find.text('allowed (allowed)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send Test All request'));
    await tester.pumpAndSettle();
    expect(requests.length,1);
    expect(requests.single.path,'/api/v1/tenant-admin/tills/allowed/hardware-test-all');
    expect(requests.single.data['requestId'],isNotEmpty);
    expect(find.text('Session: PASSED'),findsOneWidget);
    expect(find.text('Test printer'),findsOneWidget);
    expect(tester.takeException(),isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    dio.close();
  });
}
