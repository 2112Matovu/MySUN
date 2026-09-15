import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/data/models/announcement.dart';
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
