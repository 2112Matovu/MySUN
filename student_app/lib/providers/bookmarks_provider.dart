import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/data/models/announcement.dart';
import 'package:mysun_app/data/models/event.dart';
import 'package:mysun_app/providers/repositories.dart';
import 'package:mysun_app/providers/settings_provider.dart';

/// Bookmarked items, stored locally as a set of keys: `announcement:<id>` /
/// `event:<id>` (see the model `bookmarkKey` getters).
class BookmarksNotifier extends Notifier<Set<String>> {
  static const _key = 'bookmarks';

  @override
  Set<String> build() {
    final raw = ref.watch(sharedPreferencesProvider).getStringList(_key);
    return (raw ?? const <String>[]).toSet();
  }

  Future<void> toggle(String bookmarkKey) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final next = {...state};
    if (!next.add(bookmarkKey)) next.remove(bookmarkKey);
    await prefs.setStringList(_key, next.toList());
    state = next;
  }

  bool has(String bookmarkKey) => state.contains(bookmarkKey);
}

final bookmarksProvider =
    NotifierProvider<BookmarksNotifier, Set<String>>(BookmarksNotifier.new);

final bookmarkedAnnouncementsProvider =
    FutureProvider.autoDispose<List<Announcement>>((ref) async {
  final keys = ref.watch(bookmarksProvider);
  final ids = keys
      .where((k) => k.startsWith('announcement:'))
      .map((k) => k.split(':')[1])
      .toSet();
  if (ids.isEmpty) return const [];
  return ref.watch(announcementRepositoryProvider).byIds(ids);
});

final bookmarkedEventsProvider =
    FutureProvider.autoDispose<List<Event>>((ref) async {
  final keys = ref.watch(bookmarksProvider);
  final ids =
      keys.where((k) => k.startsWith('event:')).map((k) => k.split(':')[1]).toSet();
  if (ids.isEmpty) return const [];
  return ref.watch(eventRepositoryProvider).byIds(ids);
});
