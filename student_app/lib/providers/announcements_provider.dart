import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/data/models/announcement.dart';
import 'package:mysun_app/data/models/event.dart';
import 'package:mysun_app/providers/repositories.dart';

/// Selected category chip on the Home feed ("All" by default).
final announcementCategoryProvider = StateProvider<String>((ref) => 'All');

/// The Home feed, filtered by [announcementCategoryProvider].
final announcementsProvider =
    FutureProvider.autoDispose<List<Announcement>>((ref) async {
  final repo = ref.watch(announcementRepositoryProvider);
  final category = ref.watch(announcementCategoryProvider);
  return repo.list(category: category);
});

/// A single announcement for the detail screen.
final announcementProvider =
    FutureProvider.autoDispose.family<Announcement, String>((ref, id) async {
  return ref.watch(announcementRepositoryProvider).getById(id);
});

/// The "All" view of the Home feed: announcements and upcoming events
/// together, ordered by priority:
///  1. important announcements, newest first
///  2. featured upcoming events, soonest first
///  3. other events starting within the next 7 days, soonest first
///  4. other announcements, newest first
///  5. other upcoming events, soonest first
/// Items are [Announcement] or [Event].
final campusFeedProvider =
    FutureProvider.autoDispose<List<Object>>((ref) async {
  final announcements =
      await ref.watch(announcementRepositoryProvider).list(category: 'All');
  final events = await ref.watch(eventRepositoryProvider).list(category: 'All');

  int byNewest(Announcement a, Announcement b) =>
      b.publishedAt.compareTo(a.publishedAt);
  int bySoonest(Event a, Event b) => a.dateTime.compareTo(b.dateTime);

  final soon = DateTime.now().add(const Duration(days: 7));
  final important = announcements.where((a) => a.isImportant).toList()
    ..sort(byNewest);
  final featured = events.where((e) => e.isFeatured).toList()..sort(bySoonest);
  final nearEvents = events
      .where((e) => !e.isFeatured && e.dateTime.isBefore(soon))
      .toList()
    ..sort(bySoonest);
  final ordinary = announcements.where((a) => !a.isImportant).toList()
    ..sort(byNewest);
  final laterEvents = events
      .where((e) => !e.isFeatured && !e.dateTime.isBefore(soon))
      .toList()
    ..sort(bySoonest);

  return [
    ...important,
    ...featured,
    ...nearEvents,
    ...ordinary,
    ...laterEvents
  ];
});
