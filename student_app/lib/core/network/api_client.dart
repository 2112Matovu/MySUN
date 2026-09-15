import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/core/constants/app_constants.dart';
import 'package:mysun_app/core/network/token_storage.dart';
import 'package:mysun_app/providers/auth_provider.dart';

/// A configured [Dio] instance pointed at the FastAPI backend (§9), with the
/// stored Supabase access token attached to every request automatically,
/// and a refresh-and-retry flow on 401s so an expired access token doesn't
/// force a re-login mid-session.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // Separate client for the refresh call itself: it must not carry the
  // (expired) access token, and must not re-enter this same interceptor.
  final refreshDio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));

  // Dedups concurrent refreshes — several requests can 401 at once right
  // after expiry, and Supabase rotates the refresh token on every use, so
  // firing one per request would invalidate all but the first and log
  // everyone out.
  Future<String>? refreshing;

  Future<String> refreshAccessToken() {
    final tokenStorage = ref.read(tokenStorageProvider);
    final refreshToken = tokenStorage.refreshToken;
    if (refreshToken == null) {
      return Future.error(StateError('No refresh token available'));
    }
    return refreshDio
        .post('/auth/refresh', data: {'refresh_token': refreshToken})
        .then((res) async {
      final data = res.data as Map<String, dynamic>;
      final newAccessToken = data['access_token'] as String;
      await tokenStorage.save(
        accessToken: newAccessToken,
        refreshToken: data['refresh_token'] as String?,
      );
      return newAccessToken;
    });
  }

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = ref.read(tokenStorageProvider).accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      final isAuthEndpoint = error.requestOptions.path.startsWith('/auth/');
      if (error.response?.statusCode != 401 || isAuthEndpoint) {
        return handler.next(error);
      }

      try {
        refreshing ??= refreshAccessToken().whenComplete(() => refreshing = null);
        final newAccessToken = await refreshing!;
        final retryOptions = error.requestOptions
          ..headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await dio.fetch(retryOptions);
        handler.resolve(retryResponse);
      } catch (_) {
        await ref.read(tokenStorageProvider).clear();
        ref.read(authProvider.notifier).forceLogout();
        handler.next(error);
      }
    },
  ));

  return dio;
});
