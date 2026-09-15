import 'package:dio/dio.dart';

import 'package:mysun_app/core/constants/app_constants.dart';
import 'package:mysun_app/core/network/api_exception.dart';
import 'package:mysun_app/data/mock/mock_data.dart';
import 'package:mysun_app/data/models/bus_schedule.dart';
import 'package:mysun_app/data/models/transport_provider.dart';

/// Read access to the transport directory and bus schedules
/// (`GET /api/v1/transport`, `GET /api/v1/bus-schedules` — spec §5.3).
abstract interface class TransportRepository {
  Future<List<TransportProvider>> providers({String? serviceType});

  Future<TransportProvider> getProvider(String id);

  Future<List<BusSchedule>> schedules();

  /// The soonest active departure from now.
  Future<BusSchedule?> nextBus();

  Future<List<TransportProvider>> search(String query);

  /// Publisher-submitted provider (§4.4-style flow, mirrored for Transport).
  /// Appears in [providers] immediately, unverified, exactly like any seeded
  /// entry — verification is a separate admin action.
  Future<TransportProvider> create(TransportProvider provider);

  /// Admin removal for content that breaks the terms of service (§5.1).
  Future<void> delete(String id);
}

class MockTransportRepository implements TransportRepository {
  static final List<TransportProvider> _providers =
      MockData.transportProviders.toList();

  @override
  Future<List<TransportProvider>> providers({String? serviceType}) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final list = _providers.toList()
      ..sort((a, b) {
        if (a.isVerified != b.isVerified) return a.isVerified ? -1 : 1;
        return b.rating.compareTo(a.rating);
      });
    if (serviceType == null || serviceType == 'All') return list;
    return list.where((p) => p.serviceType == serviceType).toList();
  }

  @override
  Future<TransportProvider> getProvider(String id) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return _providers.firstWhere(
      (p) => p.id == id,
      orElse: () => throw StateError('Provider $id not found'),
    );
  }

  @override
  Future<TransportProvider> create(TransportProvider provider) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final saved = TransportProvider(
      id: 'trp-${DateTime.now().millisecondsSinceEpoch}',
      name: provider.name,
      phoneNumber: provider.phoneNumber,
      serviceType: provider.serviceType,
      contactPerson: provider.contactPerson,
      imageUrl: provider.imageUrl,
      isVerified: false,
      rating: 0,
      ratingCount: 0,
      operatingHours: provider.operatingHours,
      serviceAreas: provider.serviceAreas,
    );
    _providers.insert(0, saved);
    return saved;
  }

  @override
  Future<void> delete(String id) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    _providers.removeWhere((p) => p.id == id);
  }

  @override
  Future<List<BusSchedule>> schedules() async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final list = MockData.busSchedules.toList()
      ..sort((a, b) => a.nextDeparture().compareTo(b.nextDeparture()));
    return list;
  }

  @override
  Future<BusSchedule?> nextBus() async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final active =
        MockData.busSchedules.where((b) => b.isActive).toList()
          ..sort((a, b) => a.nextDeparture().compareTo(b.nextDeparture()));
    return active.isEmpty ? null : active.first;
  }

  @override
  Future<List<TransportProvider>> search(String query) async {
    await Future<void>.delayed(AppConstants.mockLatency);
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _providers
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.serviceType.toLowerCase().contains(q) ||
            p.serviceAreas.any((a) => a.toLowerCase().contains(q)))
        .toList();
  }
}

class HttpTransportRepository implements TransportRepository {
  HttpTransportRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<TransportProvider>> providers({String? serviceType}) async {
    try {
      final res = await _dio.get('/transport');
      final list = (res.data as List)
          .map((e) => TransportProvider.fromJson(e as Map<String, dynamic>))
          .toList();
      if (serviceType == null || serviceType == 'All') return list;
      return list.where((p) => p.serviceType == serviceType).toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<TransportProvider> getProvider(String id) async {
    try {
      final res = await _dio.get('/transport/$id');
      return TransportProvider.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<List<BusSchedule>> schedules() async {
    try {
      final res = await _dio.get('/transport/bus-schedule');
      return (res.data as List)
          .map((e) => BusSchedule.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.nextDeparture().compareTo(b.nextDeparture()));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<BusSchedule?> nextBus() async {
    final all = await schedules();
    final active = all.where((b) => b.isActive).toList()
      ..sort((a, b) => a.nextDeparture().compareTo(b.nextDeparture()));
    return active.isEmpty ? null : active.first;
  }

  @override
  Future<List<TransportProvider>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    try {
      final res = await _dio.get('/transport', queryParameters: {'query': q});
      return (res.data as List)
          .map((e) => TransportProvider.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<TransportProvider> create(TransportProvider provider) async {
    try {
      final res = await _dio.post('/transport', data: {
        'name': provider.name,
        'phone_number': provider.phoneNumber,
        'contact_person': provider.contactPerson,
        'operating_hours': provider.operatingHours,
        'service_areas': provider.serviceAreas,
        'image_url': provider.imageUrl,
      });
      return TransportProvider.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('/transport/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
