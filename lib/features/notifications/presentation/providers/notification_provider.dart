import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/root_navigator_key.dart';
import '../../../../core/access/pos_access_codes.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/notification_socket_client.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../fulfilment_pickup/presentation/providers/pos_online_orders_provider.dart';
import '../../../pos_shell/presentation/providers/pos_notifications_provider.dart';
import '../../../tenant_admin/presentation/widgets/tenant_admin_toast.dart';
import '../../data/notifications_api.dart';
import '../../domain/entities/notification_inbox_item.dart';
import '../../domain/entities/realtime_notification_event.dart';
import 'realtime_cashier_refresh_policy.dart';

class NotificationInboxState {
  const NotificationInboxState({
    this.items = const [],
    this.unreadCount = 0,
    this.isLoading = false,
  });

  final List<NotificationInboxItem> items;
  final int unreadCount;
  final bool isLoading;

  NotificationInboxState copyWith({
    List<NotificationInboxItem>? items,
    int? unreadCount,
    bool? isLoading,
  }) {
    return NotificationInboxState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final notificationsApiProvider = Provider<NotificationsApi>((ref) {
  return NotificationsApi(ref.watch(appDioProvider));
});

final notificationInboxProvider =
    StateNotifierProvider<NotificationInboxController, NotificationInboxState>(
        (ref) {
  return NotificationInboxController(ref);
});

class NotificationInboxController
    extends StateNotifier<NotificationInboxState> {
  NotificationInboxController(this._ref)
      : super(const NotificationInboxState()) {
    _ref.listen<AuthSession?>(
      authSessionProvider,
      (previous, next) => _handleAuthChanged(next),
      fireImmediately: true,
    );
  }

  static const _fanoutDebounce = Duration(milliseconds: 350);

  final Ref _ref;
  StreamSubscription<RealtimeNotificationEvent>? _eventSubscription;
  NotificationSocketClient? _socketClient;
  Timer? _fanoutDebounceTimer;
  bool _pendingOnlineOrdersRefresh = false;
  int _fanoutGeneration = 0;

  void _handleAuthChanged(AuthSession? session) {
    final canView = session != null &&
        session.isAuthenticated &&
        session.hasPermission(PosPermissionCodes.viewNotifications);

    if (!canView) {
      _fanoutDebounceTimer?.cancel();
      _pendingOnlineOrdersRefresh = false;
      _socketClient?.disconnect();
      state = const NotificationInboxState();
      return;
    }

    _ensureSocketClient().connect(
      session.accessToken,
      () async => _ref.read(authSessionProvider)?.accessToken,
    );
    unawaited(refreshAuthoritativeSurfaces(includeOnlineOrders: true));
  }

  NotificationSocketClient _ensureSocketClient() {
    final existing = _socketClient;
    if (existing != null) return existing;

    final dio = _ref.read(appDioProvider);
    final client = NotificationSocketClient(
      httpBaseUrl: dio.options.baseUrl,
      onConnected: _handleSocketReconnected,
      ticketProvider: () => _ref
          .read(posNotificationsRemoteDatasourceProvider)
          .getWebSocketTicket(),
    );
    _eventSubscription = client.events.listen(_handleRealtimeEvent);
    _socketClient = client;
    return client;
  }

  void _handleSocketReconnected() {
    developer.log(
      'Notification socket reconnected; refreshing authoritative surfaces.',
      name: 'notifications.socket',
    );
    unawaited(refreshAuthoritativeSurfaces(includeOnlineOrders: true));
  }

  void _handleRealtimeEvent(RealtimeNotificationEvent event) {
    developer.log(
      'Realtime notification received. type=${event.type}',
      name: 'notifications.socket',
    );
    // Payload is a refresh trigger only — never mutate unread/local lists here.
    if (RealtimeCashierRefreshPolicy.shouldRefreshOnlineOrders(event)) {
      _pendingOnlineOrdersRefresh = true;
    }
    if (RealtimeCashierRefreshPolicy.shouldShowNewOrderToast(event)) {
      _showNewOrderToast(event);
    }
    _scheduleFanout();
  }

  /// Surfaces a new-order toast independent of the debounced REST fan-out
  /// above, so the cashier sees it immediately rather than after the
  /// authoritative refetch lands. Uses the root navigator's context rather
  /// than a dedicated listener widget, since this controller has no
  /// BuildContext of its own and lives above any single screen.
  void _showNewOrderToast(RealtimeNotificationEvent event) {
    // The realtime push itself isn't permission-filtered server-side (only
    // the REST inbox list is) — every active staff member's socket receives
    // it, so this client-side check is what actually keeps the toast from
    // appearing for cashiers who can't see online orders at all.
    final session = _ref.read(authSessionProvider);
    final canViewOrders = session != null &&
        session.isAuthenticated &&
        (session.hasPermission(PosPermissionCodes.accessOnlineOrders) ||
            session.hasPermission(PosPermissionCodes.viewOnlineOrders));
    if (!canViewOrders) return;

    final context = rootNavigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    // Overlay.maybeOf(context) would fail here: this context is the
    // Navigator's own element, and the Overlay a Navigator provides is a
    // descendant of it, not an ancestor — so the toast must be given the
    // OverlayState directly rather than relying on the usual lookup.
    final overlay = rootNavigatorKey.currentState?.overlay;
    if (overlay == null) return;

    final orderId = event.sourceReferenceId;
    showAppToast(
      context,
      overlayState: overlay,
      title: event.title.trim().isNotEmpty ? event.title : 'New order placed',
      message: event.body,
      type: AppToastType.info,
      icon: Icons.storefront_rounded,
      onTap: orderId == null || orderId.isEmpty
          ? null
          : () => context.push('/pos/online-orders/$orderId'),
    );
  }

  void _scheduleFanout() {
    _fanoutDebounceTimer?.cancel();
    _fanoutDebounceTimer = Timer(_fanoutDebounce, () {
      final includeOnlineOrders = _pendingOnlineOrdersRefresh;
      _pendingOnlineOrdersRefresh = false;
      unawaited(
        refreshAuthoritativeSurfaces(includeOnlineOrders: includeOnlineOrders),
      );
    });
  }

  /// App-resume / manual recovery entry — authoritative APIs only.
  Future<void> refreshAuthoritativeSurfaces({
    bool includeOnlineOrders = false,
  }) async {
    final generation = ++_fanoutGeneration;
    await refresh();
    if (generation != _fanoutGeneration) return;

    _ref.invalidate(posNotificationsProvider);

    if (!includeOnlineOrders) return;
    final session = _ref.read(authSessionProvider);
    final canViewOrders = session != null &&
        session.isAuthenticated &&
        (session.hasPermission(PosPermissionCodes.accessOnlineOrders) ||
            session.hasPermission(PosPermissionCodes.viewOnlineOrders));
    if (!canViewOrders) return;
    if (generation != _fanoutGeneration) return;
    await _ref.read(posOnlineOrdersProvider.notifier).refreshFromRealtime();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    try {
      final api = _ref.read(notificationsApiProvider);
      final items = await api.fetchInbox();
      final unreadCount = await api.fetchUnreadCount();
      state = NotificationInboxState(items: items, unreadCount: unreadCount);
    } catch (error) {
      developer.log(
        'Notification inbox refresh failed.',
        name: 'notifications.inbox',
        error: error,
      );
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markRead(String notificationId) async {
    final target = state.items.where((item) => item.id == notificationId);
    if (target.isEmpty || target.first.isRead) return;

    try {
      await _ref.read(notificationsApiProvider).markRead(notificationId);
      state = state.copyWith(
        items: [
          for (final item in state.items)
            if (item.id == notificationId) item.markRead() else item,
        ],
        unreadCount: (state.unreadCount - 1).clamp(0, 1 << 31),
      );
      _ref.invalidate(posNotificationsProvider);
    } catch (error) {
      developer.log(
        'Marking notification read failed.',
        name: 'notifications.inbox',
        error: error,
      );
    }
  }

  Future<void> markAllRead() async {
    if (state.unreadCount == 0) return;

    try {
      await _ref.read(notificationsApiProvider).markAllRead();
      state = state.copyWith(
        items: [for (final item in state.items) item.markRead()],
        unreadCount: 0,
      );
      _ref.invalidate(posNotificationsProvider);
    } catch (error) {
      developer.log(
        'Marking all notifications read failed.',
        name: 'notifications.inbox',
        error: error,
      );
    }
  }

  @override
  void dispose() {
    _fanoutDebounceTimer?.cancel();
    unawaited(_eventSubscription?.cancel());
    _socketClient?.dispose();
    super.dispose();
  }
}
