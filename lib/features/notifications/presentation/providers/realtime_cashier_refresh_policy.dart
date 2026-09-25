import '../../domain/entities/realtime_notification_event.dart';

/// Classifies cashier-relevant realtime notification events for refresh fan-out.
///
/// Realtime payloads are refresh triggers only — never authoritative domain state.
class RealtimeCashierRefreshPolicy {
  const RealtimeCashierRefreshPolicy._();

  static const orderPlacedStaff = 'ecommerce.order_placed.staff';

  /// Any staff notification should refresh the POS bell via authoritative API.
  static bool shouldRefreshPosNotifications(RealtimeNotificationEvent event) =>
      event.type.trim().isNotEmpty;

  /// New Ecommerce / Click & Collect order events should soft-refresh OO-01.
  static bool shouldRefreshOnlineOrders(RealtimeNotificationEvent event) {
    final type = event.type.trim().toLowerCase();
    if (type.isEmpty) return false;
    return type == orderPlacedStaff ||
        type.startsWith('ecommerce.order_placed') ||
        type.startsWith('ecommerce.order_');
  }

  /// A brand-new customer order landing (not a status change on an existing
  /// one) is the only case that should interrupt the cashier with a toast —
  /// the bell badge count already covers every other staff notification.
  static bool shouldShowNewOrderToast(RealtimeNotificationEvent event) =>
      event.type.trim().toLowerCase() == orderPlacedStaff;
}
