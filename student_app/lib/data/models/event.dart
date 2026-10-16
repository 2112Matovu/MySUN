/// A campus event. Mirrors the `events` table / API contract (spec §4.2, §5.3).
class Event {
  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.organizerName,
    required this.dateTime,
    required this.venue,
    this.endDateTime,
    this.imageUrl,
    this.capacity,
    this.registeredCount = 0,
    this.isFeatured = false,
    this.publishAt,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String organizerName;
  final DateTime dateTime;
  final String venue;
  final DateTime? endDateTime;
  final String? imageUrl;
  final int? capacity;
  final int registeredCount;
  final bool isFeatured;

  /// When a scheduled event goes live; null = published immediately.
  final DateTime? publishAt;

  Event copyWith({int? registeredCount}) => Event(
        id: id,
        title: title,
        description: description,
        category: category,
        organizerName: organizerName,
        dateTime: dateTime,
        venue: venue,
        endDateTime: endDateTime,
        imageUrl: imageUrl,
        capacity: capacity,
        registeredCount: registeredCount ?? this.registeredCount,
        isFeatured: isFeatured,
        publishAt: publishAt,
      );

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: json['category'] as String,
        organizerName: json['organizer_name'] as String? ?? 'Soroti University',
        dateTime: DateTime.parse(json['date_time'] as String).toLocal(),
        venue: json['venue'] as String,
        endDateTime: json['end_date_time'] == null
            ? null
            : DateTime.parse(json['end_date_time'] as String).toLocal(),
        imageUrl: json['image_url'] as String?,
        capacity: json['capacity'] as int?,
        registeredCount: json['registered_count'] as int? ?? 0,
        isFeatured: json['is_featured'] as bool? ?? false,
        publishAt: json['publish_at'] == null
            ? null
            : DateTime.parse(json['publish_at'] as String).toLocal(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'organizer_name': organizerName,
        'date_time': dateTime.toIso8601String(),
        'venue': venue,
        'end_date_time': endDateTime?.toIso8601String(),
        'image_url': imageUrl,
        'capacity': capacity,
        'registered_count': registeredCount,
        'is_featured': isFeatured,
        'publish_at': publishAt?.toIso8601String(),
      };

  /// True once the event's end time has passed (or its start time, for
  /// events with no end time set) — this is what drops it out of the
  /// Events list, not the start time alone, so it stays visible for its
  /// whole duration.
  bool get isPast => (endDateTime ?? dateTime).isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  Duration get countdown => dateTime.difference(DateTime.now());

  String get bookmarkKey => 'event:$id';
}
