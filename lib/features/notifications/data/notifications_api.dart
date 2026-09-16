import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import '../domain/entities/notification_inbox_item.dart';

class NotificationsApi {
  const NotificationsApi(this._dio);

  final Dio _dio;

  Future<List<NotificationInboxItem>> fetchInbox({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.tenantNotifications,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );

    final items = (response.data?['data']?['items'] as List<dynamic>?) ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(NotificationInboxItem.fromJson)
        .toList(growable: false);
  }

  Future<int> fetchUnreadCount() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.tenantNotificationsUnreadCount,
    );
    final count = response.data?['data']?['unreadCount'];
    return count is int ? count : int.tryParse('$count') ?? 0;
  }

  Future<void> markRead(String notificationId) {
    return _dio.put<void>(
      ApiEndpoints.tenantNotificationRead(notificationId),
    );
  }

  Future<void> markAllRead() {
    return _dio.put<void>(ApiEndpoints.tenantNotificationsReadAll);
  }

  /// The full session access token carries every granted permission code as a
  /// claim, which can grow large enough to push the WebSocket handshake's
  /// request line (the token travels via query string, since browsers cannot
  /// set custom headers on a WebSocket upgrade) past the server's request-line
  /// limit -- failing the handshake with HTTP 414 before it ever connects.
  /// This exchanges the full token for a minimal, short-lived one scoped only
  /// to opening the notifications socket.
  Future<String?> fetchSocketToken() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.tenantNotificationsSocketToken,
    );
    final token = response.data?['data']?['accessToken'];
    return token is String && token.isNotEmpty ? token : null;
  }
}
