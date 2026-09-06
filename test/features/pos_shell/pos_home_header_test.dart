import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:nytroz_pos/core/access/effective_permission_set.dart';
import 'package:nytroz_pos/core/access/permission_access_providers.dart';
import 'package:nytroz_pos/core/access/pos_access_codes.dart';
import 'package:nytroz_pos/core/utils/timezone_resolver.dart';
import 'package:nytroz_pos/features/pos_shell/application/state/pos_home_dashboard_state.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/home/pos_home_header.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/widgets/home/pos_status_chip.dart';

/// Shell header chrome used by fixture tests (Chunk 14 exact membership).
final _fullHeaderPermissions = EffectivePermissionSet.fromIterable({
  PosPermissionCodes.shellTopbarNotificationBell,
  PosPermissionCodes.notificationsPanelView,
  PosPermissionCodes.notificationsPanelUnreadCount,
  PosPermissionCodes.viewTillSession,
});

void main() {
  setUpAll(() {
    TimezoneResolver.ensureInitialized();
  });

  PosHomeDashboardState createTestState({
    String userDisplayName = 'John Cashier',
    String statusMessage = 'Ready for sales',
    String tillLabel = 'Front Till',
    String tillStatusLabel = 'Open',
    String tillDisplayLabel = 'Main Till 01 / Open',
    bool isTillOpen = true,
    int notificationCount = 5,
    DateTime? serverNowUtc,
    DateTime? serverTimeReceivedAt,
    String? outletTimezone,
  }) {
    return PosHomeDashboardState(
      actions: const [],
      fallbackUserDisplayName: userDisplayName,
      statusMessage: statusMessage,
      tillLabel: tillLabel,
      tillStatusLabel: tillStatusLabel,
      tillDisplayLabel: tillDisplayLabel,
      isTillOpen: isTillOpen,
      notificationCount: notificationCount,
      serverNowUtc: serverNowUtc,
      serverTimeReceivedAt: serverTimeReceivedAt,
      outletTimezone: outletTimezone,
    );
  }

  Future<void> pumpHeader(
    WidgetTester tester, {
    required PosHomeDashboardState state,
    EffectivePermissionSet? permissions,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          effectivePermissionSetProvider.overrideWithValue(
            permissions ?? _fullHeaderPermissions,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: PosHomeHeader(dashboard: state),
          ),
        ),
      ),
    );
  }

  group('PosHomeHeader Widget Tests', () {
    testWidgets('renders user greeting and status message', (tester) async {
      final state = createTestState(
        userDisplayName: 'Alice',
        statusMessage: 'Ready for sales',
      );

      await pumpHeader(tester, state: state);

      expect(find.text('Hello, Alice 👋'), findsOneWidget);
      expect(find.text('Ready for sales'), findsOneWidget);
    });

    testWidgets(
        'notification badge shows actual count for <= 99 and 99+ for > 99',
        (tester) async {
      // Test count <= 99
      final state5 = createTestState(notificationCount: 5);
      await pumpHeader(tester, state: state5);
      expect(find.text('5'), findsOneWidget);

      // Test count > 99 -> displays 99+
      final state120 = createTestState(notificationCount: 120);
      await pumpHeader(tester, state: state120);
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets(
        'hides notification button when notification bell permission is missing',
        (tester) async {
      final stateWithoutNotifs = createTestState();

      await pumpHeader(
        tester,
        state: stateWithoutNotifs,
        permissions: EffectivePermissionSet.fromIterable({
          PosPermissionCodes.viewTillSession,
        }),
      );

      expect(find.byIcon(Icons.notifications_none_rounded), findsNothing);
    });

    testWidgets(
        'shows till status chip when till is open',
        (tester) async {
      final state = createTestState(
        tillDisplayLabel: 'Main Till 01 / Open',
        isTillOpen: true,
      );

      await pumpHeader(tester, state: state);

      expect(find.byType(PosStatusChip), findsOneWidget);
      expect(find.text('Main Till 01 / Open'), findsOneWidget);
    });

    testWidgets(
        'hides till status chip when till context is absent',
        (tester) async {
      final state = createTestState(
        isTillOpen: false,
        tillDisplayLabel: '',
      );

      await pumpHeader(
        tester,
        state: state,
        permissions: EffectivePermissionSet.fromIterable({
          PosPermissionCodes.shellTopbarNotificationBell,
          PosPermissionCodes.notificationsPanelUnreadCount,
        }),
      );

      expect(find.byType(PosStatusChip), findsNothing);
    });

    testWidgets(
        'resolves and formats dynamic outlet timezone date and time correctly',
        (tester) async {
      final nowUtc = DateTime.now().toUtc();
      final serverNowUtc = DateTime.utc(2026, 8, 8, 5, 20, 0);

      final stateColombo = createTestState(
        serverNowUtc: serverNowUtc,
        serverTimeReceivedAt: nowUtc,
        outletTimezone: 'Asia/Colombo', // +05:30 -> 10:50 AM
      );

      await pumpHeader(tester, state: stateColombo);

      final expectedDate =
          DateFormat('EEE, MMM d').format(DateTime(2026, 8, 8));
      expect(find.textContaining('10:50 AM'), findsOneWidget);
      expect(find.textContaining(expectedDate), findsOneWidget);
    });

    testWidgets(
        'renders compact column on screen width < TenantAdminBreakpoints.smallTablet',
        (tester) async {
      tester.view.physicalSize = const Size(650, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = createTestState();

      await pumpHeader(tester, state: state);

      expect(find.byType(PosHomeHeader), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'renders wide row on screen width >= TenantAdminBreakpoints.smallTablet',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = createTestState();

      await pumpHeader(tester, state: state);

      expect(find.byType(PosHomeHeader), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
