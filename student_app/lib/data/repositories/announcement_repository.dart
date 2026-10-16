import 'package:dio/dio.dart';

import 'package:mysun_app/core/constants/app_constants.dart';
import 'package:mysun_app/core/network/api_exception.dart';
import 'package:mysun_app/core/network/json_cache.dart';
import 'package:mysun_app/data/mock/mock_data.dart';
import 'package:mysun_app/data/models/announcement.dart';

/// Read access to announcements. Backed by mock data today; the same surface
/// maps onto `GET /api/v1/announcements` (spec §5.3).
abstract interface class AnnouncementRepository {
  Future<List<Announcement>> list({
    String? category,
    int limit = AppConstants.pageSize,
    int offset = 0,
  });

  Future<Announcement> getById(String id);

  Future<List<Announcement>> byIds(Set<String> ids);

  Future<List<Announcement>> search(String query);

  /// Publisher-submitted announcement — live immediately (§4.4).
  Future<Announcement> create(Announcement announcement);

  /// Admin removal for content that breaks the terms of service (§5.1).
  Future<void> delete(String id);
}

class MockAnnouncementRepository implements AnnouncementRepository {
  static final List<Announcement> _announcements =
      MockData.announcements.toList();

  List<Announcement> get _sorted => _announcements.toList()
    ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

  @override
  Future<List<Announcement>> list({
    String? category,
    int limit = AppConstants.pageSize,
    int offset = 0,
  }) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    var items = _sorted.where((a) => !a.isExpired).toList();
    if (category != null && category != 'All') {
      items = items.where((a) => a.category == category).toList();
    }
    if (offset >= items.length) return const [];
    return items.sublist(offset, (offset + limit).clamp(0, items.length));
  }

  @override
  Future<Announcement> getById(String id) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return _announcements.firstWhere(
      (a) => a.id == id,
      orElse: () => throw StateError('Announcement $id not found'),
    );
  }

  @override
  Future<List<Announcement>> byIds(Set<String> ids) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return _sorted.where((a) => ids.contains(a.id)).toList();
  }

  @override
  Future<List<Announcement>> search(String query) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _sorted
        .where((a) =>
            a.title.toLowerCase().contains(q) ||
            a.description.toLowerCase().contains(q) ||
            a.category.toLowerCase().contains(q) ||
            a.publisherName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<Announcement> create(Announcement announcement) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final saved = Announcement(
      id: 'ann-${DateTime.now().millisecondsSinceEpoch}',
      title: announcement.title,
      description: announcement.description,
      category: announcement.category,
      publisherName: announcement.publisherName,
      publishedAt: DateTime.now(),
      isImportant: announcement.isImportant,
      imageUrl: announcement.imageUrl,
      expiresAt: announcement.expiresAt,
    );
    _announcements.insert(0, saved);
    return saved;
  }

  @override
  Future<void> delete(String id) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    _announcements.removeWhere((a) => a.id == id);
  }
}

class HttpAnnouncementRepository implements AnnouncementRepository {
  HttpAnnouncementRepository(this._dio, [this._cache = const JsonCache(null)]);
  final Dio _dio;
  final JsonCache _cache;

  /// Unfiltered fetch (including expired ones) — [byIds] and [search] use
  /// this directly so a bookmarked or matched announcement doesn't vanish
  /// just because it expired, same as how past events still show up there.
  Future<List<Announcement>> _all(
      {String? category, bool includeExpired = true}) async {
    final key = 'announcements.${category ?? 'All'}.$includeExpired';
    List<Announcement> parse(Object? data) => (data as List)
        .map((e) => Announcement.fromJson(e as Map<String, dynamic>))
        .toList();
    try {
      final res = await _dio.get('/announcements', queryParameters: {
        if (category != null && category != 'All') 'category': category,
        if (includeExpired) 'include_expired': true,
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
  Future<List<Announcement>> list({
    String? category,
    int limit = AppConstants.pageSize,
    int offset = 0,
  }) async {
    final items = (await _all(category: category, includeExpired: false))
        .where((a) => !a.isExpired)
        .toList();
    if (offset >= items.length) return const [];
    return items.sublist(offset, (offset + limit).clamp(0, items.length));
  }

  @override
  Future<Announcement> getById(String id) async {
    try {
      final res = await _dio.get('/announcements/$id');
      return Announcement.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<List<Announcement>> byIds(Set<String> ids) async {
    if (ids.isEmpty) return const [];
    final all = await _all();
    return all.where((a) => ids.contains(a.id)).toList();
  }

  @override
  Future<List<Announcement>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final all = await _all();
    return all
        .where((a) =>
            a.title.toLowerCase().contains(q) ||
            a.description.toLowerCase().contains(q) ||
            a.category.toLowerCase().contains(q) ||
            a.publisherName.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<Announcement> create(Announcement announcement) async {
    try {
      final res = await _dio.post('/announcements', data: {
        'title': announcement.title,
        'description': announcement.description,
        'category': announcement.category,
        // The backend falls back to the user's own faculty first, then
        // this — matches `user.faculty ?? _department` in the Flutter UI.
        'department': announcement.publisherName,
        'is_important': announcement.isImportant,
        'image_url': announcement.imageUrl,
        // Always UTC with an offset, so the server reads the same instant
        // the user picked regardless of its own timezone.
        'expires_at': announcement.expiresAt?.toUtc().toIso8601String(),
        'publish_at': announcement.publishAt?.toUtc().toIso8601String(),
      });
      return Announcement.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('/announcements/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
