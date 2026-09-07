class NotificationInboxItem {
  const NotificationInboxItem({
    required this.id,
    required this.eventCode,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.linkUrl,
    this.sourceReferenceId,
  });

  final String id;
  final String eventCode;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final String? linkUrl;
  final String? sourceReferenceId;

  NotificationInboxItem markRead() => NotificationInboxItem(
        id: id,
        eventCode: eventCode,
        title: title,
        body: body,
        isRead: true,
        createdAt: createdAt,
        linkUrl: linkUrl,
        sourceReferenceId: sourceReferenceId,
      );

  factory NotificationInboxItem.fromJson(Map<String, dynamic> json) {
    return NotificationInboxItem(
      id: json['id']?.toString() ?? '',
      eventCode: json['eventCode']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      isRead: json['isRead'] == true,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
              DateTime.now(),
      linkUrl: json['linkUrl']?.toString(),
      sourceReferenceId: json['sourceReferenceId']?.toString(),
    );
  }
}
