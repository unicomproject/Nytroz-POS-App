class RealtimeNotificationEvent {
  const RealtimeNotificationEvent({
    required this.type,
    required this.title,
    required this.body,
    this.actionUrl,
    this.sourceReferenceId,
  });

  final String type;
  final String title;
  final String body;
  final String? actionUrl;
  final String? sourceReferenceId;

  factory RealtimeNotificationEvent.fromJson(Map<String, dynamic> json) {
    return RealtimeNotificationEvent(
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      actionUrl: json['actionUrl']?.toString(),
      sourceReferenceId: json['sourceReferenceId']?.toString(),
    );
  }
}
