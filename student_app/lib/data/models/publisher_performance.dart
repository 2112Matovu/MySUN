import 'package:mysun_app/data/models/publisher_submission.dart';

/// A publisher's own performance overview (spec §1.4 "Performance metrics
/// and analytics" for publishers). Counts are real, derived from
/// [PublisherSubmission] history; views/engagement are illustrative until
/// the backend analytics pipeline exists (§9.6) — there's no view-tracking
/// today.
class PublisherPerformance {
  const PublisherPerformance({
    required this.totalSubmissions,
    required this.published,
    required this.removed,
    required this.drafts,
    required this.byType,
    required this.estimatedViews,
    required this.engagementPercent,
  });

  final int totalSubmissions;
  final int published;
  final int removed;
  final int drafts;
  final Map<SubmissionType, int> byType;
  final int estimatedViews;
  final double engagementPercent;

  factory PublisherPerformance.from(List<PublisherSubmission> submissions) {
    final published = submissions
        .where((s) => s.status == SubmissionStatus.published)
        .length;
    final removed =
        submissions.where((s) => s.status == SubmissionStatus.removed).length;
    final drafts =
        submissions.where((s) => s.status == SubmissionStatus.draft).length;

    final byType = <SubmissionType, int>{
      for (final t in SubmissionType.values)
        t: submissions
            .where((s) => s.type == t && s.status != SubmissionStatus.draft)
            .length,
    };

    // Deterministic, plausible-looking placeholders scaled off real activity
    // — swap for real numbers once view/engagement tracking exists.
    final estimatedViews = published == 0 ? 0 : published * 187 + 43;
    final engagementPercent =
        published == 0 ? 0.0 : (12 + published * 1.8).clamp(0, 45).toDouble();

    return PublisherPerformance(
      totalSubmissions: submissions.length,
      published: published,
      removed: removed,
      drafts: drafts,
      byType: byType,
      estimatedViews: estimatedViews,
      engagementPercent: engagementPercent,
    );
  }
}
