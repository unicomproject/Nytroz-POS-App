import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:nytroz_pos/core/network/dio_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/providers/hardware_dashboard_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/providers/hardware_overview_query_provider.dart';
import 'package:nytroz_pos/features/tenant_admin/hardware/presentation/widgets/hardware_overview_help.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/providers/tenant_admin_context_provider.dart';
import 'hardware_master_wizard_test.dart' show hardwareTestAccess;

void main() {
  testWidgets('dashboard refreshes observed data and stops after disposal',
      (tester) async {
    var requests = 0;
    final dio = Dio(BaseOptions(baseUrl: 'http://hardware.test'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests++;
      handler.resolve(Response(requestOptions: options, data: {
        'data': {
          'items': [],
          'summary': {'Unknown': requests},
          'totalCount': 0,
          'checkedAt': '2026-09-13T08:00:00Z',
        }
      }));
    }));
    final container = ProviderContainer(overrides: [
      appDioProvider.overrideWithValue(dio),
      tenantAdminContextProvider
          .overrideWith((ref) async => hardwareTestAccess().context),
    ]);
    addTearDown(container.dispose);
    const query =
        (page: 1, outletId: 'o', search: '', type: '', status: '', sort: '');
    final provider = hardwareDashboardProvider(query);
    final subscription = container.listen(provider, (_, __) {});
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(requests, 1);
    expect(container.read(provider).requireValue.checkedAt,
        DateTime.utc(2026, 9, 13, 8));
    await tester.pump(const Duration(seconds: 30));
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));
    expect(requests, 2);
    expect(container.read(provider).requireValue.summary['Unknown'], 2);
    subscription.close();
    container.dispose();
    dio.close();
    await tester.pump(const Duration(seconds: 60));
    expect(requests, 2);
  });
  test(
      'filters persist between listeners and reset when access context refreshes',
      () async {
    final container = ProviderContainer(overrides: [
      tenantAdminContextProvider
          .overrideWith((ref) async => hardwareTestAccess().context),
    ]);
    addTearDown(container.dispose);
    await container.read(tenantAdminContextProvider.future);
    final subscription =
        container.listen(hardwareOverviewQueryProvider, (_, __) {});
    const query = (
      page: 2,
      outletId: 'o',
      search: 'Printer',
      type: 'RECEIPT_PRINTER',
      status: 'Ready',
      sort: 'last_seen'
    );
    container.read(hardwareOverviewQueryProvider.notifier).state = query;
    subscription.close();
    expect(container.read(hardwareOverviewQueryProvider), query);
    container.invalidate(tenantAdminContextProvider);
    await container.read(tenantAdminContextProvider.future);
    expect(container.read(hardwareOverviewQueryProvider).outletId, isNull);
    expect(container.read(hardwareOverviewQueryProvider).search, isEmpty);
  });
  for (final size in [
    const Size(1024, 768),
    const Size(1280, 800),
    const Size(1366, 768),
    const Size(1440, 900)
  ]) {
    testWidgets(
        'health and interactive troubleshooting fit $size without invented status',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var refreshes = 0;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SingleChildScrollView(
        child: HardwareOverviewHelp(
            dashboard: const HardwareDashboard([], {}, {'Ready': 3}, 3),
            onRefresh: () => refreshes++),
      ))));
      expect(find.text('Ready: 3'), findsOneWidget);
      expect(find.text('Disconnected: Not reported'), findsOneWidget);
      await tester.tap(find.byTooltip('Refresh hardware health'));
      expect(refreshes, 1);
      await tester.tap(find.text('USB device does not appear'));
      await tester.pumpAndSettle();
      expect(
          find.textContaining(
              'not automatically available inside its emulator'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
