import 'package:dio/dio.dart';

import 'package:mysun_app/core/network/api_exception.dart';
import 'package:mysun_app/data/models/campus_service.dart';

/// Food, health, IT-support and library services (`/api/v1/campus-services`).
abstract interface class CampusServiceRepository {
  Future<List<CampusService>> list({ServiceCategory? category});

  /// Admin-level only.
  Future<CampusService> create({
    required ServiceCategory category,
    required String name,
    String? description,
    String? location,
    String? openingHours,
    String? contactPhone,
  });

  Future<void> delete(String id);
}

class HttpCampusServiceRepository implements CampusServiceRepository {
  HttpCampusServiceRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<CampusService>> list({ServiceCategory? category}) async {
    try {
      final res = await _dio.get('/campus-services', queryParameters: {
        if (category != null) 'category': category.apiValue,
      });
      return (res.data as List)
          .map((e) => CampusService.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  String? _blank(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();

  @override
  Future<CampusService> create({
    required ServiceCategory category,
    required String name,
    String? description,
    String? location,
    String? openingHours,
    String? contactPhone,
  }) async {
    try {
      final res = await _dio.post('/campus-services', data: {
        'category': category.apiValue,
        'name': name.trim(),
        'description': _blank(description),
        'location': _blank(location),
        'opening_hours': _blank(openingHours),
        'contact_phone': _blank(contactPhone),
      });
      return CampusService.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      await _dio.delete('/campus-services/$id');
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
