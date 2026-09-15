import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/data/models/admin_analytics.dart';
import 'package:mysun_app/data/models/publisher_submission.dart';
import 'package:mysun_app/data/models/user_profile.dart';
import 'package:mysun_app/data/models/user_role.dart';
import 'package:mysun_app/providers/accommodation_providers.dart';
import 'package:mysun_app/providers/announcements_provider.dart';
import 'package:mysun_app/providers/events_provider.dart';
import 'package:mysun_app/providers/repositories.dart';
import 'package:mysun_app/providers/transport_providers.dart';

/// §5.3 Moderation Queue, adapted: everything currently live, across all
/// publishers, that an admin can review and remove (no approval gate).
final moderationQueueProvider =
    FutureProvider.autoDispose<List<PublisherSubmission>>((ref) async {
  return ref.watch(publisherRepositoryProvider).recentSubmissions();
});

/// §5.3 User Management — optionally filtered by role.
final adminUsersProvider =
    FutureProvider.autoDispose.family<List<UserProfile>, UserRole?>(
        (ref, role) async {
  return ref.watch(adminRepositoryProvider).listUsers(role: role);
});

/// §5.3 Analytics Dashboard / Main Dashboard metrics.
final adminAnalyticsProvider =
    FutureProvider.autoDispose<AdminAnalytics>((ref) async {
  return ref.watch(adminRepositoryProvider).analytics();
});

/// Removes a piece of live content (§5.1 "Content moderation" — remove-only,
/// there is no approve step) and records why on the submission history.
/// `markRemoved` itself is responsible for deleting the real content row
/// (server-side for the real backend; via the injected callback for the
/// Mock repository) — this just invalidates the affected lists afterwards.
Future<void> removeSubmission(
  WidgetRef ref,
  PublisherSubmission submission, {
  required String reason,
}) async {
  await ref.read(publisherRepositoryProvider).markRemoved(submission.id, reason: reason);
  switch (submission.type) {
    case SubmissionType.announcement:
      ref.invalidate(announcementsProvider);
    case SubmissionType.event:
      ref.invalidate(eventsProvider);
      ref.invalidate(nextEventProvider);
    case SubmissionType.accommodation:
      ref.invalidate(accommodationsProvider);
    case SubmissionType.transport:
      ref.invalidate(transportProvidersProvider);
  }
}
