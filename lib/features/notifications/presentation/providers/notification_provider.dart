import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/access/pos_access_codes.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/notification_socket_client.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../data/notifications_api.dart';
import '../../domain/entities/notification_inbox_item.dart';
import '../../domain/entities/realtime_notification_event.dart';

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

final notificationInboxProvider = StateNotifierProvider<
    NotificationInboxController, NotificationInboxState>((ref) {
  return NotificationInboxController(ref);
});

class NotificationInboxController extends StateNotifier<NotificationInboxState> {
  NotificationInboxController(this._ref) : super(const NotificationInboxState()) {
    _ref.listen<AuthSession?>(
      authSessionProvider,
      (previous, next) => _handleAuthChanged(next),
      fireImmediately: true,
    );
  }

  final Ref _ref;
  StreamSubscription<RealtimeNotificationEvent>? _eventSubscription;
  NotificationSocketClient? _socketClient;

  void _handleAuthChanged(AuthSession? session) {
    final canView = session != null &&
        session.isAuthenticated &&
        session.hasPermission(PosPermissionCodes.viewNotifications);

    if (!canView) {
      _socketClient?.disconnect();
      state = const NotificationInboxState();
      return;
    }

    _ensureSocketClient().connect(session.accessToken);
    unawaited(refresh());
  }

  NotificationSocketClient _ensureSocketClient() {
    final existing = _socketClient;
    if (existing != null) return existing;

    final dio = _ref.read(appDioProvider);
    final client = NotificationSocketClient(httpBaseUrl: dio.options.baseUrl);
    _eventSubscription = client.events.listen(_handleRealtimeEvent);
    _socketClient = client;
    return client;
  }

  void _handleRealtimeEvent(RealtimeNotificationEvent event) {
    developer.log(
      'Realtime notification received. type=${event.type}',
      name: 'notifications.socket',
    );
    // The push payload carries no inbox-item id to update in place, so treat it
    // purely as a "something changed" signal and resync from the source of truth.
    unawaited(refresh());
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
    unawaited(_eventSubscription?.cancel());
    _socketClient?.dispose();
    super.dispose();
  }
}
