import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/data/models/publisher_performance.dart';
import 'package:mysun_app/data/models/publisher_submission.dart';
import 'package:mysun_app/providers/accommodation_providers.dart';
import 'package:mysun_app/providers/announcements_provider.dart';
import 'package:mysun_app/providers/events_provider.dart';
import 'package:mysun_app/providers/repositories.dart';
import 'package:mysun_app/providers/transport_providers.dart';

/// A publisher's own drafts + submissions (§4.4 Publisher Dashboard).
final publisherSubmissionsProvider =
    FutureProvider.autoDispose<List<PublisherSubmission>>((ref) async {
  return ref.watch(publisherRepositoryProvider).mySubmissions();
});

/// Drafts only — backs the "View Drafts" screen.
final publisherDraftsProvider =
    FutureProvider.autoDispose<List<PublisherSubmission>>((ref) async {
  return ref.watch(publisherRepositoryProvider).drafts();
});

/// Backs the "My Performance" screen.
final publisherPerformanceProvider =
    FutureProvider.autoDispose<PublisherPerformance>((ref) async {
  final submissions = await ref.watch(publisherRepositoryProvider).mySubmissions();
  return PublisherPerformance.from(submissions);
});

/// Lets a publisher take down a piece of their own live content (e.g. a
/// boda rider they added by mistake) — distinct from an admin's
/// terms-of-service removal in [removeSubmission]; no reason is recorded.
/// `removeOwn` itself deletes the real content row (server-side for the
/// real backend; via the injected callback for the Mock repository).
Future<void> removeMyContent(WidgetRef ref, PublisherSubmission submission) async {
  await ref.read(publisherRepositoryProvider).removeOwn(submission.id);
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
  ref.invalidate(publisherSubmissionsProvider);
  ref.invalidate(publisherPerformanceProvider);
}
