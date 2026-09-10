import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/notifications/domain/entities/realtime_notification_event.dart';
import 'package:nytroz_pos/features/notifications/presentation/providers/realtime_cashier_refresh_policy.dart';

void main() {
  group('RealtimeCashierRefreshPolicy', () {
    test('staff order placed refreshes bell and online orders', () {
      const event = RealtimeNotificationEvent(
        type: 'ecommerce.order_placed.staff',
        title: 'New order placed',
        body: 'Order ORD-000001 has been placed',
        sourceReferenceId: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
      );
      expect(
        RealtimeCashierRefreshPolicy.shouldRefreshPosNotifications(event),
        isTrue,
      );
      expect(
        RealtimeCashierRefreshPolicy.shouldRefreshOnlineOrders(event),
        isTrue,
      );
    });

    test('empty type does not refresh', () {
      const event = RealtimeNotificationEvent(
        type: '',
        title: 'x',
        body: 'y',
      );
      expect(
        RealtimeCashierRefreshPolicy.shouldRefreshPosNotifications(event),
        isFalse,
      );
      expect(
        RealtimeCashierRefreshPolicy.shouldRefreshOnlineOrders(event),
        isFalse,
      );
    });

    test('non ecommerce event refreshes bell only', () {
      const event = RealtimeNotificationEvent(
        type: 'pos.till.alert',
        title: 'Till',
        body: 'Alert',
      );
      expect(
        RealtimeCashierRefreshPolicy.shouldRefreshPosNotifications(event),
        isTrue,
      );
      expect(
        RealtimeCashierRefreshPolicy.shouldRefreshOnlineOrders(event),
        isFalse,
      );
    });
  });
}
