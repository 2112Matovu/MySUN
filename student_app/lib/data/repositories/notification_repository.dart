import 'package:dio/dio.dart';

import 'package:mysun_app/core/constants/app_constants.dart';
import 'package:mysun_app/core/network/api_exception.dart';
import 'package:mysun_app/data/mock/mock_data.dart';
import 'package:mysun_app/data/models/app_notification.dart';

/// Read access to notifications (`GET /api/v1/notifications` — spec §5.3).
abstract interface class NotificationRepository {
  Future<List<AppNotification>> list();

  Future<void> markRead(String id);
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
}
