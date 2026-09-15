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

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: json['category'] as String,
        organizerName: json['organizer_name'] as String? ?? 'Soroti University',
        dateTime: DateTime.parse(json['date_time'] as String),
        venue: json['venue'] as String,
        endDateTime: json['end_date_time'] == null
            ? null
            : DateTime.parse(json['end_date_time'] as String),
        imageUrl: json['image_url'] as String?,
        capacity: json['capacity'] as int?,
        registeredCount: json['registered_count'] as int? ?? 0,
        isFeatured: json['is_featured'] as bool? ?? false,
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
      };

  bool get isPast => dateTime.isBefore(DateTime.now());
  bool get isToday {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  Duration get countdown => dateTime.difference(DateTime.now());

  String get bookmarkKey => 'event:$id';
}
