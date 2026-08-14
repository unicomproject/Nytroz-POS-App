import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/pos_shell/application/state/pos_home_dashboard_state.dart';
import 'package:nytroz_pos/features/pos_shell/data/datasources/pos_home_remote_datasource.dart';
import 'package:nytroz_pos/features/pos_shell/presentation/providers/pos_home_dashboard_provider.dart';

void main() {
  group('POS home till authority', () {
    test('home NO_OPEN_TILL_SESSION error reports till closed', () {
      final homeAsync = AsyncValue<PosHomeDashboardState>.error(
        const PosHomeException(
          'No open till session found for the assigned till.',
          reasonCode: 'NO_OPEN_TILL_SESSION',
        ),
        StackTrace.empty,
      );

      expect(
        resolveAuthoritativeTillOpen(
          homeAsync: homeAsync,
          localTillOpen: true,
        ),
        isFalse,
      );
    });

    test('successful home payload is authoritative for till open state', () {
      final homeAsync = AsyncValue.data(
        PosHomeDashboardState(
          actions: const [],
          fallbackUserDisplayName: 'Cashier',
          tillLabel: 'Front Till',
          tillStatusLabel: 'Open',
          tillDisplayLabel: 'Front Till / Open',
          isTillOpen: true,
          statusMessage: 'Ready for sales',
          notificationCount: 0,
          dateDisplay: 'Fri, Aug 14',
          timeDisplay: '1:00 PM',
          startSaleTitle: 'Start a Sale',
          startSaleDescription: 'Create a new transaction.',
          startSaleButtonLabel: 'Start New Sale',
          isPosEnabled: true,
          isTrustedDevice: true,
          hasOpenTillSession: true,
          enabledFeatureKeys: const {},
          grantedPermissionKeys: const {},
        ),
      );

      expect(
        resolveAuthoritativeTillOpen(
          homeAsync: homeAsync,
          localTillOpen: false,
        ),
        isTrue,
      );
    });

    test('blocking home reason requests stale till clear', () {
      expect(
        shouldClearStaleTillSessionForHomeReason('NO_OPEN_TILL_SESSION'),
        isTrue,
      );
      expect(
        const PosHomeException(
          'No open till session found for the assigned till.',
          reasonCode: 'NO_OPEN_TILL_SESSION',
        ).shouldClearStaleTillSession,
        isTrue,
      );
      expect(shouldClearStaleTillSessionForHomeReason('PERMISSION_DENIED'), isFalse);
    });
  });
}
