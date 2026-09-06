import 'package:dio/dio.dart';

import '../../../../core/network/api_endpoints.dart';

class PosNotificationItem {
  const PosNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;

  factory PosNotificationItem.fromJson(Map<String, dynamic> json) =>
      PosNotificationItem(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        isRead: json['isRead'] == true,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}

class PosNotificationInbox {
  const PosNotificationInbox({required this.items, required this.unreadCount});
  final List<PosNotificationItem> items;
  final int unreadCount;
}

class PosNotificationsRemoteDatasource {
  const PosNotificationsRemoteDatasource(this._dio);
  final Dio _dio;

  Future<PosNotificationInbox> getInbox() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiEndpoints.posNotifications,
      queryParameters: const {'page': 1, 'pageSize': 20},
    );
    final root = response.data ?? const <String, dynamic>{};
    final rawData = root['data'];
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : const <String, dynamic>{};
    final rawItems = data['notifications'];
    return PosNotificationInbox(
      items: rawItems is Iterable
          ? rawItems
              .whereType<Map>()
              .map((item) => PosNotificationItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ))
              .toList(growable: false)
          : const [],
      unreadCount: (data['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}
