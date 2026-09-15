/// An in-app notification (spec §4.2 `notifications`).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.relatedId,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;

  /// One of: `announcement`, `event`, `reminder`, `transport`, `system`.
  final String type;
  final DateTime createdAt;
  final String? relatedId;
  final bool isRead;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        type: json['type'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        relatedId: json['related_id'] as String?,
        isRead: json['is_read'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'created_at': createdAt.toIso8601String(),
        'related_id': relatedId,
        'is_read': isRead,
      };

  AppNotification copyWith({bool? isRead}) => AppNotification(
        id: id,
        title: title,
        body: body,
        type: type,
        createdAt: createdAt,
        relatedId: relatedId,
        isRead: isRead ?? this.isRead,
      );
}
