import 'package:dio/dio.dart';

import 'package:mysun_app/core/network/api_exception.dart';
import 'package:mysun_app/data/models/booking.dart';

/// In-app boda booking (`/api/v1/bookings`).
abstract interface class BookingRepository {
  Future<Booking> create({
    required String providerId,
    required String pickup,
    required String destination,
    DateTime? requestedTime,
    String? note,
  });

  /// The signed-in student's own bookings, newest first.
  Future<List<Booking>> mine();

  /// Requests for the riders this user listed (admins see all).
  Future<List<Booking>> incoming();

  Future<Booking> cancel(String id);

  /// `accept`, `decline` or `complete`.
  Future<Booking> respond(String id, String action);
}

class HttpBookingRepository implements BookingRepository {
  HttpBookingRepository(this._dio);
  final Dio _dio;

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  List<Booking> _list(dynamic data) => (data as List)
      .map((e) => Booking.fromJson(e as Map<String, dynamic>))
      .toList();

  @override
  Future<Booking> create({
    required String providerId,
    required String pickup,
    required String destination,
    DateTime? requestedTime,
    String? note,
  }) =>
      _guard(() async {
        final res = await _dio.post('/bookings', data: {
          'provider_id': providerId,
          'pickup': pickup,
          'destination': destination,
          'requested_time': requestedTime?.toUtc().toIso8601String(),
          'note': (note == null || note.trim().isEmpty) ? null : note.trim(),
        });
        return Booking.fromJson(res.data as Map<String, dynamic>);
      });

  @override
  Future<List<Booking>> mine() =>
      _guard(() async => _list((await _dio.get('/bookings/mine')).data));

  @override
  Future<List<Booking>> incoming() =>
      _guard(() async => _list((await _dio.get('/bookings/incoming')).data));

  @override
  Future<Booking> cancel(String id) => _guard(() async {
        final res = await _dio.post('/bookings/$id/cancel');
        return Booking.fromJson(res.data as Map<String, dynamic>);
      });

  @override
  Future<Booking> respond(String id, String action) => _guard(() async {
        final res =
            await _dio.post('/bookings/$id/respond', data: {'action': action});
        return Booking.fromJson(res.data as Map<String, dynamic>);
      });
}
