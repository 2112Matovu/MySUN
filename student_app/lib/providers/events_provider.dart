import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/data/models/event.dart';
import 'package:mysun_app/data/repositories/event_repository.dart';
import 'package:mysun_app/providers/repositories.dart';

class EventFilter {
  const EventFilter({
    this.category = 'All',
    this.dateFilter = EventDateFilter.all,
    this.query = '',
  });

  final String category;
  final EventDateFilter dateFilter;
  final String query;

  EventFilter copyWith({
    String? category,
    EventDateFilter? dateFilter,
    String? query,
  }) =>
      EventFilter(
        category: category ?? this.category,
        dateFilter: dateFilter ?? this.dateFilter,
        query: query ?? this.query,
      );
}

class EventFilterNotifier extends Notifier<EventFilter> {
  @override
  EventFilter build() => const EventFilter();

  void setCategory(String category) =>
      state = state.copyWith(category: category);
  void setDateFilter(EventDateFilter f) => state = state.copyWith(dateFilter: f);
  void setQuery(String q) => state = state.copyWith(query: q);
  void reset() => state = const EventFilter();
}

final eventFilterProvider =
    NotifierProvider<EventFilterNotifier, EventFilter>(EventFilterNotifier.new);

final eventsProvider = FutureProvider.autoDispose<List<Event>>((ref) async {
  final repo = ref.watch(eventRepositoryProvider);
  final filter = ref.watch(eventFilterProvider);
  return repo.list(
    category: filter.category,
    dateFilter: filter.dateFilter,
    query: filter.query,
  );
});

final featuredEventsProvider =
    FutureProvider.autoDispose<List<Event>>((ref) async {
  return ref.watch(eventRepositoryProvider).featured();
});

final nextEventProvider = FutureProvider.autoDispose<Event?>((ref) async {
  return ref.watch(eventRepositoryProvider).nextUpcoming();
});

final eventProvider =
    FutureProvider.autoDispose.family<Event, String>((ref, id) async {
  return ref.watch(eventRepositoryProvider).getById(id);
});

/// Ids of events the signed-in user registered for. Signed-out users (or a
/// failed lookup) simply have none, so the detail screen still renders.
final myRegistrationsProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  try {
    return await ref.watch(eventRepositoryProvider).myRegistrations();
  } catch (_) {
    return const <String>{};
  }
});
