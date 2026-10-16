import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the last successful response of a list endpoint so the feed can still
/// be read offline (FR-PRF-04). Reads are read-only: nothing is ever written
/// back to the server from the cache.
class JsonCache {
  const JsonCache(this._prefs);
  final SharedPreferences? _prefs;

  static String _k(String key) => 'cache.$key';

  Future<void> put(String key, Object? json) async {
    try {
      await _prefs?.setString(_k(key), jsonEncode(json));
    } catch (_) {
      // A cache write must never break a successful request.
    }
  }

  Object? get(String key) {
    try {
      final raw = _prefs?.getString(_k(key));
      return raw == null ? null : jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }

  /// True when the request never got an HTTP answer (no network, timeout).
  static bool isOffline(DioException e) => e.response == null;
}
