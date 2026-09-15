import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mysun_app/providers/settings_provider.dart';

/// Holds the Supabase-issued access/refresh tokens (§9.1) so the Dio
/// interceptor in `api_client.dart` can attach them without every
/// repository needing to know where they live.
class TokenStorage {
  TokenStorage(this._prefs);

  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';

  final SharedPreferences _prefs;

  String? get accessToken => _prefs.getString(_kAccessToken);
  String? get refreshToken => _prefs.getString(_kRefreshToken);

  Future<void> save({required String accessToken, String? refreshToken}) async {
    await _prefs.setString(_kAccessToken, accessToken);
    if (refreshToken != null) {
      await _prefs.setString(_kRefreshToken, refreshToken);
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_kAccessToken);
    await _prefs.remove(_kRefreshToken);
  }
}

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(ref.watch(sharedPreferencesProvider)),
);
