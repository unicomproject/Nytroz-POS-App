import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/core/access/effective_permission_set.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/features/pos/presentation/widgets/new_sale/navigation/pos_cashier_bottom_navigation.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/common/pos_notifications_dialog.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/common/pos_shell_bottom_nav_destinations.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/common/pos_shell_top_bar_visibility.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/common/pos_top_bar.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/common/pos_top_bar_notification_button.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/home/pos_branding.dart';
import 'package:nytroz_pos/features/pos_shell/data/datasources/pos_notifications_remote_datasource.dart';
import 'package:go_router/go_router.dart';

ProviderContainer _container(List<String> codes) {
  return ProviderContainer(
    overrides: [
      effectivePermissionSetProvider.overrideWithValue(
        EffectivePermissionSet.fromIterable(codes),
      ),
    ],
  );
}

void main() {
  group('PosShellTopBarVisibility', () {
    test('container alone does not authorize children', () {
      final set = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.shellTopbarContainer,
      ]);
      expect(PosShellTopBarVisibility.canShowContainer(set), isTrue);
      expect(PosShellTopBarVisibility.canShowAnyChild(set), isFalse);
      expect(PosShellTopBarVisibility.shouldRenderTopBar(set), isFalse);
    });

    test('container + one child renders', () {
      final set = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.shellTopbarContainer,
        PosPermissionCodes.shellTopbarClock,
      ]);
      expect(PosShellTopBarVisibility.shouldRenderTopBar(set), isTrue);
      expect(PosShellTopBarVisibility.canShowClock(set), isTrue);
      expect(PosShellTopBarVisibility.canShowBrand(set), isFalse);
    });

    test('bell and panel are independent', () {
      final bellOnly = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.shellTopbarNotificationBell,
      ]);
      expect(PosShellTopBarVisibility.canShowNotificationBell(bellOnly), isTrue);
      expect(
        PosShellTopBarVisibility.canShowNotificationPanel(bellOnly),
        isFalse,
      );

      final panelOnly = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.notificationsPanelView,
      ]);
      expect(
        PosShellTopBarVisibility.canShowNotificationBell(panelOnly),
        isFalse,
      );
      expect(
        PosShellTopBarVisibility.canShowNotificationPanel(panelOnly),
        isTrue,
      );
    });
  });

  group('Bottom nav filtering', () {
    test('container denied → hide nav', () {
      final set = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.salesDashboardView,
      ]);
      expect(shouldShowPosCashierBottomNav(set), isFalse);
    });

    test('container + zero destinations → hide nav', () {
      final set = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.shellBottomNavContainer,
      ]);
      expect(shouldShowPosCashierBottomNav(set), isFalse);
      expect(filterPosCashierNavDestinations(set), isEmpty);
    });

    test('Home only → one destination, stable id', () {
      final set = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.shellBottomNavContainer,
        PosPermissionCodes.salesDashboardView,
      ]);
      final visible = filterPosCashierNavDestinations(set);
      expect(visible.length, 1);
      expect(visible.single.id, PosCashierNavDestinationId.home);
      expect(visible.single.route, '/pos/home');
    });

    test('Customers only → original static index not assumed', () {
      final set = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.shellBottomNavContainer,
        PosPermissionCodes.viewCustomers,
      ]);
      final visible = filterPosCashierNavDestinations(set);
      expect(visible.length, 1);
      expect(visible.single.id, PosCashierNavDestinationId.customers);
      expect(visible.first.matches('/pos/customers'), isTrue);
    });

    test('Home + Orders + Customers → exactly 3, no gaps', () {
      final set = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.shellBottomNavContainer,
        PosPermissionCodes.salesDashboardView,
        PosPermissionCodes.receiptsDigitalView,
        PosPermissionCodes.viewCustomers,
      ]);
      final visible = filterPosCashierNavDestinations(set);
      expect(visible.map((d) => d.id).toList(), [
        PosCashierNavDestinationId.home,
        PosCashierNavDestinationId.orders,
        PosCashierNavDestinationId.customers,
      ]);
    });

    test('Settings requires shellNavigationSettings', () {
      final denied = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.shellBottomNavContainer,
        PosPermissionCodes.salesDashboardView,
      ]);
      expect(
        filterPosCashierNavDestinations(denied)
            .any((d) => d.id == PosCashierNavDestinationId.settings),
        isFalse,
      );

      final granted = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.shellBottomNavContainer,
        PosPermissionCodes.shellNavigationSettings,
      ]);
      expect(
        filterPosCashierNavDestinations(granted)
            .single.id,
        PosCashierNavDestinationId.settings,
      );
    });

    test('refresh removes middle destination without index crash', () {
      var set = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.shellBottomNavContainer,
        PosPermissionCodes.salesDashboardView,
        PosPermissionCodes.salesNewSaleView,
        PosPermissionCodes.viewCustomers,
      ]);
      expect(filterPosCashierNavDestinations(set).length, 3);

      set = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.shellBottomNavContainer,
        PosPermissionCodes.salesDashboardView,
        PosPermissionCodes.viewCustomers,
      ]);
      final visible = filterPosCashierNavDestinations(set);
      expect(visible.length, 2);
      expect(visible[0].id, PosCashierNavDestinationId.home);
      expect(visible[1].id, PosCashierNavDestinationId.customers);
      expect(visible[1].matches('/pos/customers'), isTrue);
    });
  });

  group('Notification row visibility', () {
    test('partial fields — title only', () {
      final item = PosNotificationItem(
        id: '1',
        title: 'Hello',
        body: 'Secret body',
        isRead: false,
        createdAt: DateTime(2026, 1, 1),
      );
      final set = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.notificationsMessagesTitle,
      ]);
      expect(notificationRowHasVisibleContent(item, set), isTrue);
    });

    test('all fields denied → no empty row', () {
      final item = PosNotificationItem(
        id: '1',
        title: 'Hello',
        body: 'Body',
        isRead: false,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(
        notificationRowHasVisibleContent(item, EffectivePermissionSet.empty),
        isFalse,
      );
    });
  });

  group('Widget permission gates', () {
    testWidgets('brand denied → PosBranding absent', (tester) async {
      final container = _container([
        PosPermissionCodes.shellTopbarContainer,
        PosPermissionCodes.shellTopbarNotificationBell,
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: PosTopBar(
                content: SizedBox.shrink(),
                brandName: 'OneVerz POS',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(PosBranding), findsNothing);
      expect(find.text('OneVerz POS'), findsNothing);
    });

    testWidgets('bell denied → notification button shrinks', (tester) async {
      final container = _container([
        PosPermissionCodes.shellTopbarContainer,
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: PosTopBarNotificationButton(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
    });

    testWidgets('unread denied → no badge text even when count > 0',
        (tester) async {
      final container = _container([
        PosPermissionCodes.shellTopbarNotificationBell,
        // panel unread intentionally absent
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: PosTopBarNotificationButton(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
      // Badge numeric text absent (not "0").
      expect(find.text('0'), findsNothing);
    });

    testWidgets('bell granted + panel denied → tap does not open dialog',
        (tester) async {
      final container = _container([
        PosPermissionCodes.shellTopbarNotificationBell,
      ]);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: PosTopBarNotificationButton(),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.notifications_none_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Notifications'), findsNothing);
    });

    testWidgets('bottom nav reflows to permitted destinations only',
        (tester) async {
      final container = _container([
        PosPermissionCodes.shellBottomNavContainer,
        PosPermissionCodes.salesDashboardView,
        PosPermissionCodes.viewCustomers,
      ]);
      addTearDown(container.dispose);

      final router = GoRouter(
        initialLocation: '/pos/home',
        routes: [
          GoRoute(
            path: '/pos/home',
            builder: (_, __) => UncontrolledProviderScope(
              container: container,
              child: const Scaffold(
                body: SizedBox.shrink(),
                bottomNavigationBar: PosCashierBottomNavigation(),
              ),
            ),
          ),
          GoRoute(
            path: '/pos/customers',
            builder: (_, __) => const SizedBox.shrink(),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Customers'), findsOneWidget);
      expect(find.text('New Sale'), findsNothing);
      expect(find.text('Orders'), findsNothing);
      expect(find.text('Settings'), findsNothing);
    });

    testWidgets('permission refresh removes destination without restart',
        (tester) async {
      Future<void> pumpNav(List<String> codes) async {
        final container = _container(codes);
        addTearDown(container.dispose);
        final router = GoRouter(
          initialLocation: '/pos/home',
          routes: [
            GoRoute(
              path: '/pos/home',
              builder: (_, __) => UncontrolledProviderScope(
                container: container,
                child: const Scaffold(
                  bottomNavigationBar: PosCashierBottomNavigation(),
                ),
              ),
            ),
          ],
        );
        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();
      }

      await pumpNav([
        PosPermissionCodes.shellBottomNavContainer,
        PosPermissionCodes.salesDashboardView,
        PosPermissionCodes.salesNewSaleView,
        PosPermissionCodes.viewCustomers,
      ]);
      expect(find.text('New Sale'), findsOneWidget);

      await pumpNav([
        PosPermissionCodes.shellBottomNavContainer,
        PosPermissionCodes.salesDashboardView,
        PosPermissionCodes.viewCustomers,
      ]);
      expect(find.text('New Sale'), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Customers'), findsOneWidget);
    });
  });

  group('Multi-device logical consistency', () {
    test('same permission set → same visibility helpers', () {
      final set = EffectivePermissionSet.fromIterable([
        PosPermissionCodes.shellTopbarContainer,
        PosPermissionCodes.shellTopbarClock,
        PosPermissionCodes.shellBottomNavContainer,
        PosPermissionCodes.viewCustomers,
      ]);
      // Phone / tablet / desktop must share these helpers — no device forks.
      expect(PosShellTopBarVisibility.canShowClock(set), isTrue);
      expect(PosShellTopBarVisibility.canShowBrand(set), isFalse);
      expect(filterPosCashierNavDestinations(set).single.id,
          PosCashierNavDestinationId.customers);
    });
  });
}
