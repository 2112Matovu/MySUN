import 'package:dio/dio.dart';

import 'package:mysun_app/core/constants/app_constants.dart';
import 'package:mysun_app/core/network/api_exception.dart';
import 'package:mysun_app/data/mock/mock_data.dart';
import 'package:mysun_app/data/models/app_notification.dart';
import 'package:mysun_app/data/models/notification_prefs.dart';

/// Read access to notifications (`GET /api/v1/notifications` — spec §5.3).
abstract interface class NotificationRepository {
  Future<List<AppNotification>> list();

  Future<void> markRead(String id);

  /// Which categories the user wants (`GET/PUT /notifications/preferences`).
  Future<NotificationPrefs> getPreferences();
  Future<void> setPreferences(NotificationPrefs prefs);

  /// Push token of this phone, so the backend can reach it.
  Future<void> registerDevice(String token);
  Future<void> unregisterDevice(String token);
}

class MockNotificationRepository implements NotificationRepository {
  @override
  Future<List<AppNotification>> list() async {
    await Future<void>.delayed(AppConstants.mockLatency);
    return MockData.notifications
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<void> markRead(String id) async {
    await Future<void>.delayed(AppConstants.mockLatency);
  }

  static NotificationPrefs _prefs = const NotificationPrefs();

  @override
  Future<NotificationPrefs> getPreferences() async => _prefs;

  @override
  Future<void> setPreferences(NotificationPrefs prefs) async => _prefs = prefs;

  @override
  Future<void> registerDevice(String token) async {}

  @override
  Future<void> unregisterDevice(String token) async {}
}

class HttpNotificationRepository implements NotificationRepository {
  HttpNotificationRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<AppNotification>> list() async {
    try {
      final res = await _dio.get('/notifications');
      return (res.data as List)
          .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> markRead(String id) async {
    try {
      await _dio.post('/notifications/$id/read');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<NotificationPrefs> getPreferences() => _guard(() async {
        final res = await _dio.get('/notifications/preferences');
        return NotificationPrefs.fromJson(res.data as Map<String, dynamic>);
      });

  @override
  Future<void> setPreferences(NotificationPrefs prefs) => _guard(
      () => _dio.put('/notifications/preferences', data: prefs.toJson()));

  @override
  Future<void> registerDevice(String token) => _guard(() => _dio.post(
      '/notifications/devices',
      data: {'token': token, 'platform': 'android'}));

  @override
  Future<void> unregisterDevice(String token) => _guard(() =>
      _dio.post('/notifications/devices/unregister', data: {'token': token}));
}
