import 'package:dio/dio.dart';

import 'package:mysun_app/core/network/api_exception.dart';
import 'package:mysun_app/data/models/accommodation_listing.dart';
import 'package:mysun_app/data/models/announcement.dart';
import 'package:mysun_app/data/models/event.dart';
import 'package:mysun_app/data/models/transport_provider.dart';

class SearchResults {
  const SearchResults({
    this.announcements = const [],
    this.events = const [],
    this.accommodation = const [],
    this.transport = const [],
  });

  final List<Announcement> announcements;
  final List<Event> events;
  final List<AccommodationListing> accommodation;
  final List<TransportProvider> transport;

  bool get isEmpty =>
      announcements.isEmpty &&
      events.isEmpty &&
      accommodation.isEmpty &&
      transport.isEmpty;
}

/// One search across every content type (`GET /api/v1/search`).
abstract interface class SearchRepository {
  Future<SearchResults> search(String query);
}

class HttpSearchRepository implements SearchRepository {
  HttpSearchRepository(this._dio);
  final Dio _dio;

  List<T> _parse<T>(dynamic raw, T Function(Map<String, dynamic>) from) =>
      (raw as List? ?? const [])
          .map((e) => from(e as Map<String, dynamic>))
          .toList();

  @override
  Future<SearchResults> search(String query) async {
    try {
      final res = await _dio.get('/search', queryParameters: {'q': query});
      final data = res.data as Map<String, dynamic>;
      return SearchResults(
        announcements: _parse(data['announcements'], Announcement.fromJson),
        events: _parse(data['events'], Event.fromJson),
        accommodation:
            _parse(data['accommodation'], AccommodationListing.fromJson),
        transport: _parse(data['transport'], TransportProvider.fromJson),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
