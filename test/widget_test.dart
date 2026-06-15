import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nytroz_pos/app/app.dart';
import 'package:nytroz_pos/features/pos_shell/application/state/pos_home_dashboard_state.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/providers/pos_home_dashboard_provider.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/screens/pos_home_screen.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/pos_mobile_top_bar.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/pos_shell_nav_item.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/pos_sidebar.dart';

void main() {
  group('POS Home', () {
    testWidgets('/pos/home renders the dashboard and Start Sale hero', (
      tester,
    ) async {
      await _pumpPosHome(tester, size: const Size(1200, 900));

      expect(find.byType(PosHomeScreen), findsOneWidget);
      expect(find.text('Hello, Cashier 👋'), findsOneWidget);
      expect(find.text('Start a Sale'), findsOneWidget);
      expect(find.text('Start New Sale'), findsOneWidget);
    });

    testWidgets('renders the complete reference dashboard cards', (
      tester,
    ) async {
      await _pumpPosHome(tester, size: const Size(1200, 900));

      expect(find.text('Manage Online Orders'), findsOneWidget);
      expect(find.text('Returns & Refunds'), findsOneWidget);
      expect(find.text('Add Customer'), findsWidgets);
      expect(find.text('Parked Sales'), findsOneWidget);
      expect(find.text('Cash Drawer'), findsWidgets);
      expect(find.text('Orders'), findsOneWidget);
    });

    testWidgets('tablet width shows the sidebar', (tester) async {
      await _pumpPosHome(tester, size: const Size(1024, 768));

      expect(find.byType(PosSidebar), findsOneWidget);
      expect(find.byType(PosMobileTopBar), findsNothing);
      final homeItem = tester.widget<PosShellNavItem>(
        find.widgetWithText(PosShellNavItem, 'Home'),
      );
      expect(homeItem.selected, isTrue);
    });

    testWidgets('Home remains on /pos/home when tapped', (tester) async {
      await _pumpPosHome(tester, size: const Size(1024, 768));

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.byType(PosHomeScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('missing sidebar destination shows a safe SnackBar', (
      tester,
    ) async {
      await _pumpPosHome(tester, size: const Size(1024, 768));

      await tester.tap(find.text('New Sale'));
      await tester.pump();

      expect(
        find.text('New Sale screen is not available yet.'),
        findsOneWidget,
      );
      expect(find.byType(PosHomeScreen), findsOneWidget);
    });

    testWidgets('phone width shows the mobile top bar', (tester) async {
      await _pumpPosHome(tester, size: const Size(390, 844));

      expect(find.byType(PosMobileTopBar), findsOneWidget);
      expect(find.byType(PosSidebar), findsNothing);
    });
  });
}

Future<void> _pumpPosHome(
  WidgetTester tester, {
  required Size size,
  PosHomeDashboardState? dashboardState,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (dashboardState != null)
          posHomeDashboardProvider.overrideWithValue(dashboardState),
      ],
      child: const NytrozPosApp(),
    ),
  );
  await tester.pumpAndSettle();
}
