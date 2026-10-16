import 'package:dio/dio.dart';

import 'package:mysun_app/core/constants/app_constants.dart';
import 'package:mysun_app/core/network/api_exception.dart';
import 'package:mysun_app/core/network/json_cache.dart';
import 'package:mysun_app/data/mock/mock_data.dart';
import 'package:mysun_app/data/models/event.dart';

enum EventDateFilter {
  all('All'),
  today('Today'),
  tomorrow('Tomorrow'),
  thisWeek('This week');

  const EventDateFilter(this.label);
  final String label;
}

/// Read access to events. Maps onto `GET /api/v1/events` (spec §5.3).
abstract interface class EventRepository {
  Future<List<Event>> list({
    String? category,
    EventDateFilter dateFilter = EventDateFilter.all,
    String query = '',
  });

  Future<Event> getById(String id);

  Future<List<Event>> byIds(Set<String> ids);

  Future<List<Event>> featured();

  Future<Event?> nextUpcoming();

  Future<List<Event>> search(String query);

  /// Publisher-submitted event — live immediately (§4.4).
  Future<Event> create(Event event);

  /// Admin removal for content that breaks the terms of service (§5.1).
  Future<void> delete(String id);

  /// Ids of the events the signed-in user has registered for.
  Future<Set<String>> myRegistrations();

  /// Registers the user and returns the event's new registered count.
  /// Throws [ApiException] when the event is full.
  Future<int> register(String eventId);

  Future<int> unregister(String eventId);
}

class MockEventRepository implements EventRepository {
  static final List<Event> _events = MockData.events.toList();

  List<Event> get _upcomingSorted {
    final list = _events.where((e) => !e.isPast).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  bool _matchesDate(Event e, EventDateFilter f) {
    final now = DateTime.now();
    switch (f) {
      case EventDateFilter.all:
        return true;
      case EventDateFilter.today:
        return e.isToday;
      case EventDateFilter.tomorrow:
        final t = now.add(const Duration(days: 1));
        return e.dateTime.year == t.year &&
            e.dateTime.month == t.month &&
            e.dateTime.day == t.day;
      case EventDateFilter.thisWeek:
        return e.dateTime.isBefore(now.add(const Duration(days: 7)));
    }
  }

  @override
  Future<List<Event>> list({
    String? category,
    EventDateFilter dateFilter = EventDateFilter.all,
    String query = '',
  }) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final q = query.trim().toLowerCase();
    return _upcomingSorted.where((e) {
      if (category != null && category != 'All' && e.category != category) {
        return false;
      }
      if (!_matchesDate(e, dateFilter)) return false;
      if (q.isNotEmpty &&
          !e.title.toLowerCase().contains(q) &&
          !e.organizerName.toLowerCase().contains(q) &&
          !e.venue.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<Event> getById(String id) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return _events.firstWhere(
      (e) => e.id == id,
      orElse: () => throw StateError('Event $id not found'),
    );
  }

  @override
  Future<List<Event>> byIds(Set<String> ids) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final list = _events.where((e) => ids.contains(e.id)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return list;
  }

  @override
  Future<List<Event>> featured() async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return _upcomingSorted.where((e) => e.isFeatured).toList();
  }

  @override
  Future<Event?> nextUpcoming() async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final list = _upcomingSorted;
    return list.isEmpty ? null : list.first;
  }

  @override
  Future<List<Event>> search(String query) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _events
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            e.description.toLowerCase().contains(q) ||
            e.venue.toLowerCase().contains(q) ||
            e.organizerName.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  @override
  Future<Event> create(Event event) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final saved = Event(
      id: 'evt-${DateTime.now().millisecondsSinceEpoch}',
      title: event.title,
      description: event.description,
      category: event.category,
      organizerName: event.organizerName,
      dateTime: event.dateTime,
      venue: event.venue,
      endDateTime: event.endDateTime,
      imageUrl: event.imageUrl,
      capacity: event.capacity,
      isFeatured: event.isFeatured,
    );
    _events.insert(0, saved);
    return saved;
  }

  @override
  Future<void> delete(String id) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    _events.removeWhere((e) => e.id == id);
  }

  static final Set<String> _registered = {};

  @override
  Future<Set<String>> myRegistrations() async => {..._registered};

  @override
  Future<int> register(String eventId) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final i = _events.indexWhere((e) => e.id == eventId);
    if (i < 0) throw const ApiException('Event not found');
    final e = _events[i];
    if (!_registered.add(eventId)) return e.registeredCount;
    if (e.capacity != null && e.registeredCount >= e.capacity!) {
      _registered.remove(eventId);
      throw const ApiException('This event is full');
    }
    final next = e.registeredCount + 1;
    _events[i] = e.copyWith(registeredCount: next);
    return next;
  }

  @override
  Future<int> unregister(String eventId) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final i = _events.indexWhere((e) => e.id == eventId);
    if (i < 0) throw const ApiException('Event not found');
    final e = _events[i];
    if (!_registered.remove(eventId)) return e.registeredCount;
    final next = e.registeredCount > 0 ? e.registeredCount - 1 : 0;
    _events[i] = e.copyWith(registeredCount: next);
    return next;
  }
}

class HttpEventRepository implements EventRepository {
  HttpEventRepository(this._dio, [this._cache = const JsonCache(null)]);
  final Dio _dio;
  final JsonCache _cache;

  bool _matchesDate(Event e, EventDateFilter f) {
    final now = DateTime.now();
    switch (f) {
      case EventDateFilter.all:
        return true;
      case EventDateFilter.today:
        return e.isToday;
      case EventDateFilter.tomorrow:
        final t = now.add(const Duration(days: 1));
        return e.dateTime.year == t.year &&
            e.dateTime.month == t.month &&
            e.dateTime.day == t.day;
      case EventDateFilter.thisWeek:
        return e.dateTime.isBefore(now.add(const Duration(days: 7)));
    }
  }

  /// The backend only filters by category — date/query/upcoming-only
  /// filtering happens client-side on the full list, same shape as the
  /// mock repository.
  Future<List<Event>> _all({String? category}) async {
    final key = 'events.${category ?? 'All'}';
    List<Event> parse(Object? data) =>
        (data as List).map((e) => Event.fromJson(e as Map<String, dynamic>)).toList();
    try {
      final res = await _dio.get('/events', queryParameters: {
        if (category != null && category != 'All') 'category': category,
      });
      await _cache.put(key, res.data);
      return parse(res.data);
    } on DioException catch (e) {
      final cached = JsonCache.isOffline(e) ? _cache.get(key) : null;
      if (cached != null) return parse(cached);
      throw mapDioError(e);
    }
  }

  @override
  Future<List<Event>> list({
    String? category,
    EventDateFilter dateFilter = EventDateFilter.all,
    String query = '',
  }) async {
    final q = query.trim().toLowerCase();
    final items = await _all(category: category);
    return items.where((e) {
      if (e.isPast) return false;
      if (!_matchesDate(e, dateFilter)) return false;
      if (q.isNotEmpty &&
          !e.title.toLowerCase().contains(q) &&
          !e.organizerName.toLowerCase().contains(q) &&
          !e.venue.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  @override
  Future<Event> getById(String id) async {
    try {
      final res = await _dio.get('/events/$id');
      return Event.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<List<Event>> byIds(Set<String> ids) async {
    if (ids.isEmpty) return const [];
    final all = await _all();
    return all.where((e) => ids.contains(e.id)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  @override
  Future<List<Event>> featured() async {
    final all = await _all();
    return all.where((e) => !e.isPast && e.isFeatured).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  @override
  Future<Event?> nextUpcoming() async {
    final upcoming = await list();
    return upcoming.isEmpty ? null : upcoming.first;
  }

  @override
  Future<List<Event>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final all = await _all();
    return all
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            e.description.toLowerCase().contains(q) ||
            e.venue.toLowerCase().contains(q) ||
            e.organizerName.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  @override
  Future<Event> create(Event event) async {
    try {
      final res = await _dio.post('/events', data: {
        'title': event.title,
        'description': event.description,
        'category': event.category,
        'organizer_name': event.organizerName,
        // UTC with an offset, so the server reads the instant the user picked.
        'date_time': event.dateTime.toUtc().toIso8601String(),
        'venue': event.venue,
        'end_date_time': event.endDateTime?.toUtc().toIso8601String(),
        'publish_at': event.publishAt?.toUtc().toIso8601String(),
        'image_url': event.imageUrl,
        'capacity': event.capacity,
        'is_featured': event.isFeatured,
      });
      return Event.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('/events/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<Set<String>> myRegistrations() async {
    try {
      final res = await _dio.get('/events/registrations/mine');
      return (res.data as List).cast<String>().toSet();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<int> _toggle(String method, String eventId) async {
    try {
      final res = await _dio.request('/events/$eventId/register',
          options: Options(method: method));
      return (res.data as Map<String, dynamic>)['registered_count'] as int;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<int> register(String eventId) => _toggle('POST', eventId);

  @override
  Future<int> unregister(String eventId) => _toggle('DELETE', eventId);
}
