import 'package:dio/dio.dart';

/// Thrown by `Http*Repository` classes on any failed API call. UI code
/// generally just shows `'$e'`, so [toString] carries the whole message.
class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Extracts FastAPI's `{"detail": "..."}` error body when present, else
/// falls back to a generic network-error message.
ApiException mapDioError(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['detail'] != null) {
    return ApiException(data['detail'].toString());
  }
  if (e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout) {
    return const ApiException('Could not reach the server. Check your connection.');
  }
  return ApiException(e.message ?? 'Something went wrong.');
}
