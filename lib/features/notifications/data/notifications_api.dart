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
}
