import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/reports/data/constants/report_api_paths.dart';
import 'package:nytroz_pos/features/tenant_admin/reports/domain/entities/report_models.dart';
import 'package:nytroz_pos/features/tenant_admin/reports/domain/entities/report_query.dart';
import 'package:nytroz_pos/features/tenant_admin/reports/presentation/providers/report_providers.dart';
import 'package:nytroz_pos/features/tenant_admin/reports/presentation/utils/report_catalog.dart';
import 'package:nytroz_pos/features/tenant_admin/reports/presentation/widgets/common/report_data_components.dart';
import 'package:nytroz_pos/features/tenant_admin/reports/presentation/widgets/common/report_filter_components.dart';
import 'package:nytroz_pos/features/tenant_admin/reports/presentation/widgets/common/report_states.dart';

void main() {
  testWidgets('shows explicit API unavailable state without fake values', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ReportApiUnavailableState()),
      ),
    );

    expect(
      find.text('Reports service is not available yet'),
      findsOneWidget,
    );
    expect(find.textContaining('frontend is ready'), findsOneWidget);
  });

  testWidgets('shows default dates without counting mandatory filters', (
    tester,
  ) async {
    final query = ReportQuery(
      from: DateTime(2026, 7),
      to: DateTime(2026, 7, 15),
      outletId: 'outlet-1',
      section: ReportSections.dashboard,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReportFilterBar(
            scope: ReportScope.dashboard,
            query: query,
            notifier: ReportQueryNotifier(query),
            outlets: const [
              ReportFilterOption(
                id: 'outlet-1',
                name: 'Main Outlet',
                code: 'OUT-001',
                status: 'ACTIVE',
                isActive: true,
              ),
            ],
            onApply: () {},
            onClear: () {},
          ),
        ),
      ),
    );

    expect(find.text('More Filters'), findsOneWidget);
    expect(find.textContaining('More Filters ('), findsNothing);
    expect(find.text('Clear all'), findsNothing);
    expect(find.text('Choose a valid report period'), findsNothing);
    expect(find.textContaining('From date and to date'), findsNothing);
  });

  testWidgets('uses mobile record cards below 600 pixels', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReportDataView(
            records: [
              ReportRecord({
                'orderNumber': 'ORDER-1',
                'outletName': 'Outlet',
                'orderStatus': 'COMPLETED',
              }),
            ],
            columns: [
              ReportColumnSpec(
                key: 'orderNumber',
                label: 'Order',
                primary: true,
              ),
              ReportColumnSpec(key: 'outletName', label: 'Outlet'),
              ReportColumnSpec(
                key: 'orderStatus',
                label: 'Status',
                status: true,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(ReportMobileRecordCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
