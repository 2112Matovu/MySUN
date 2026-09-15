enum SubmissionType { announcement, event, accommodation, transport }

/// Publishing is immediate (no pre-approval gate) — a submission is either
/// still a private [draft], [published] and live, or [removed] by an admin
/// for violating the terms of service.
enum SubmissionStatus { draft, published, removed }

/// A publisher's content submission (spec §4.4, §8.2/8.3 `status` column,
/// adapted: this app publishes on submit and only supports after-the-fact
/// removal — see §5.1 Minor/Super Admin "Content moderation"). Lives only in
/// [MockPublisherRepository] until the backend moderation endpoints exist
/// (§9.4).
class PublisherSubmission {
  const PublisherSubmission({
    required this.id,
    required this.type,
    required this.title,
    required this.status,
    required this.updatedAt,
    this.contentId,
    this.formData,
    this.publisherName = 'Sarah Akena (HR Department)',
    this.removalReason,
  });

  final String id;
  final SubmissionType type;
  final String title;
  final SubmissionStatus status;
  final DateTime updatedAt;

  /// The id of the live record in its own repository (e.g. the
  /// `AccommodationListing.id`) — needed so an admin's removal can delete the
  /// actual content, not just this history entry. Null for drafts and for
  /// illustrative seed entries with no backing content.
  final String? contentId;

  /// The Create screen's form fields, saved so a draft can be resumed later
  /// (§4.4 "Draft auto-save and management"). Only set for [SubmissionStatus.draft].
  final Map<String, dynamic>? formData;
  final String publisherName;
  final String? removalReason;

  factory PublisherSubmission.fromJson(Map<String, dynamic> json) =>
      PublisherSubmission(
        id: json['id'] as String,
        type: SubmissionType.values.byName(json['type'] as String),
        title: json['title'] as String,
        status: SubmissionStatus.values.byName(json['status'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
        contentId: json['content_id'] as String?,
        formData: json['form_data'] as Map<String, dynamic>?,
        publisherName: json['publisher_name'] as String? ?? 'Publisher',
        removalReason: json['removal_reason'] as String?,
      );

  PublisherSubmission copyWith({
    String? title,
    SubmissionStatus? status,
    DateTime? updatedAt,
    String? contentId,
    Map<String, dynamic>? formData,
    String? removalReason,
  }) =>
      PublisherSubmission(
        id: id,
        type: type,
        title: title ?? this.title,
        status: status ?? this.status,
        updatedAt: updatedAt ?? this.updatedAt,
        contentId: contentId ?? this.contentId,
        formData: formData ?? this.formData,
        publisherName: publisherName,
        removalReason: removalReason ?? this.removalReason,
      );
}
