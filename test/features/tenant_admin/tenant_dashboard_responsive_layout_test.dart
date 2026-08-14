import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/dashboard/domain/entities/tenant_dashboard.dart';
import 'package:nytroz_pos/features/tenant_admin/dashboard/presentation/widgets/attention_and_exceptions_row.dart';
import 'package:nytroz_pos/features/tenant_admin/dashboard/presentation/widgets/dashboard_metric_grid.dart';
import 'package:nytroz_pos/features/tenant_admin/dashboard/presentation/widgets/operational_risks_card.dart';
import 'package:nytroz_pos/features/tenant_admin/dashboard/presentation/widgets/sales_this_week_card.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/theme/tenant_admin_theme.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/widgets/tenant_admin_page_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tenant Admin dashboard responsive layout', () {
    testWidgets('1920 desktop uses four KPI cards in one row', (tester) async {
      await _pumpKpiGrid(tester, const Size(1600, 220), compact: false);

      expect(find.text("TODAY'S SALES"), findsOneWidget);
      expect(find.text('ORDERS'), findsOneWidget);
      expect(find.text('ACTIVE OUTLETS'), findsOneWidget);
      expect(find.text('STOCK ALERTS'), findsOneWidget);

      final firstTop = tester.getTopLeft(find.text("TODAY'S SALES")).dy;
      final fourthTop = tester.getTopLeft(find.text('STOCK ALERTS')).dy;
      expect((firstTop - fourthTop).abs(), lessThan(1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('KPI grid wraps to two columns on tablet width',
        (tester) async {
      await _pumpKpiGrid(tester, const Size(720, 360), compact: false);

      final firstTop = tester.getTopLeft(find.text("TODAY'S SALES")).dy;
      final thirdTop = tester.getTopLeft(find.text('ACTIVE OUTLETS')).dy;
      expect(thirdTop, greaterThan(firstTop));
      expect(tester.takeException(), isNull);
    });

    testWidgets('desktop dashboard surface fills bounded viewport',
        (tester) async {
      await _pumpDesktopDashboard(tester, const Size(1600, 900));

      final scaffoldSize = tester.getSize(find.byType(TenantAdminPageScaffold));
      expect(scaffoldSize.height, 900);
      expect(find.text('Needs Attention Today'), findsOneWidget);
      expect(find.text('Store Exceptions'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1366 by 768 desktop layout has no overflow', (tester) async {
      await _pumpTabletDashboard(tester, const Size(1366, 768));

      expect(find.text('Sales Trend'), findsOneWidget);
      expect(find.text('Operational Risks & Escalations'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('1024 tablet landscape keeps primary panels visible',
        (tester) async {
      await _pumpTabletDashboard(tester, const Size(1024, 768));

      expect(find.text('Sales Trend'), findsOneWidget);
      expect(find.text('View All (7)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('mobile dashboard remains vertically scrollable',
        (tester) async {
      await _pumpMobileDashboard(tester, const Size(390, 844));

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('Sales Trend'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('primary orange token is used by dashboard CTAs',
        (tester) async {
      await _pumpKpiGrid(tester, const Size(1600, 220), compact: false);

      final cta = tester.widget<Text>(find.text("View Today's Sales >"));
      expect(cta.style?.color, TenantAdminColors.posHomeAccentOrange);
      expect(TenantAdminColors.posHomeAccentOrange, const Color(0xFFFF6A00));
    });
  });
}

const _metrics = [
  TenantDashboardMetric(
    key: 'sales',
    title: "Today's Sales",
    value: '--',
    subtitle: 'Data pending from backend',
  ),
  TenantDashboardMetric(
    key: 'orders',
    title: 'Orders',
    value: '--',
    subtitle: 'Data pending from backend',
  ),
  TenantDashboardMetric(
    key: 'outlets',
    title: 'Active Outlets',
    value: '--',
    subtitle: 'Data pending from backend',
  ),
  TenantDashboardMetric(
    key: 'stock',
    title: 'Stock Alerts',
    value: '--',
    subtitle: 'Data pending from backend',
  ),
];

Future<void> _pumpKpiGrid(
  WidgetTester tester,
  Size size, {
  required bool compact,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: DashboardMetricGrid(
            metrics: _metrics,
            compact: compact,
            cardHeight: compact ? 150 : 146,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpDesktopDashboard(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: TenantAdminPageScaffold(
            title: 'Dashboard',
            subtitle: 'See how your business is doing today.',
            backgroundColor: TenantAdminColors.background,
            fillHeight: true,
            scrollable: false,
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DashboardMetricGrid(
                  metrics: _metrics,
                  compact: false,
                  cardHeight: 138,
                  spacing: 14,
                ),
                SizedBox(height: 14),
                Expanded(
                  flex: 4,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 62,
                        child: SalesThisWeekCard(
                          salesSummary: null,
                          expandChart: true,
                          compact: true,
                        ),
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        flex: 38,
                        child: OperationalRisksCard(
                          compact: true,
                          scrollableWhenConstrained: true,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 14),
                Expanded(
                  flex: 3,
                  child: AttentionAndExceptionsRow(
                    stretch: true,
                    compact: true,
                    scrollableWhenConstrained: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpTabletDashboard(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: const TenantAdminPageScaffold(
            title: 'Dashboard',
            subtitle: 'See how your business is doing today.',
            backgroundColor: TenantAdminColors.background,
            fillHeight: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DashboardMetricGrid(
                  metrics: _metrics,
                  compact: false,
                  cardHeight: 138,
                ),
                SizedBox(height: 24),
                SalesThisWeekCard(salesSummary: null, compact: true),
                SizedBox(height: 24),
                OperationalRisksCard(compact: true),
                SizedBox(height: 24),
                AttentionAndExceptionsRow(compact: true),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpMobileDashboard(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: const TenantAdminPageScaffold(
            title: 'Dashboard',
            subtitle: 'See how your business is doing today.',
            backgroundColor: TenantAdminColors.background,
            fillHeight: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DashboardMetricGrid(
                  metrics: _metrics,
                  compact: true,
                  cardHeight: 150,
                ),
                SizedBox(height: 16),
                SalesThisWeekCard(salesSummary: null, compact: true),
                SizedBox(height: 16),
                OperationalRisksCard(compact: true),
                SizedBox(height: 16),
                AttentionAndExceptionsRow(compact: true),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
