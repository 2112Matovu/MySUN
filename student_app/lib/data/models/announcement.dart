/// A campus announcement shown in the feed.
///
/// Field names mirror the backend contract in
/// `MySun_Complete_Software_Specification.md` (§5.3) so the mock repository can
/// be swapped for a real HTTP client with no model changes.
class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.publisherName,
    required this.publishedAt,
    this.isImportant = false,
    this.imageUrl,
    this.expiresAt,
    this.publishAt,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String publisherName;
  final DateTime publishedAt;
  final bool isImportant;
  final String? imageUrl;
  final DateTime? expiresAt;

  /// When a scheduled announcement goes live; null = published immediately.
  final DateTime? publishAt;

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        category: json['category'] as String,
        publisherName: json['publisher_name'] as String? ?? 'Soroti University',
        publishedAt: DateTime.parse(json['published_at'] as String).toLocal(),
        isImportant: json['is_important'] as bool? ?? false,
        imageUrl: json['image_url'] as String?,
        expiresAt: json['expires_at'] == null
            ? null
            : DateTime.parse(json['expires_at'] as String).toLocal(),
        publishAt: json['publish_at'] == null
            ? null
            : DateTime.parse(json['publish_at'] as String).toLocal(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'publisher_name': publisherName,
        'published_at': publishedAt.toIso8601String(),
        'is_important': isImportant,
        'image_url': imageUrl,
        'expires_at': expiresAt?.toIso8601String(),
        'publish_at': publishAt?.toIso8601String(),
      };

  /// True once [expiresAt] has passed — this is what drops it out of the
  /// feed. `null` means it never expires.
  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  String get bookmarkKey => 'announcement:$id';
}
