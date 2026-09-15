import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the Supabase-issued access/refresh tokens (§9.1) in the Android
/// Keystore via a small in-house native channel
/// (`android/.../SecureStoragePlugin.kt`, `EncryptedSharedPreferences`) —
/// not a pub package. Both secure-storage packages tried for this were
/// dead ends on this machine: `flutter_secure_storage` pulls in
/// `path_provider`, which fails to build here (project path has a space,
/// breaking its native-assets hook); `flutter_keychain` has no version
/// that's both readable by this JDK 17 toolchain (3.0.1 ships Java 21
/// bytecode) and compatible with Flutter's current plugin embedding (2.5.0
/// still calls the removed v1 `Registrar` API). Persistence is async, but
/// `accessToken`/`refreshToken` stay synchronous for the Dio interceptor by
/// keeping an in-memory copy hydrated once via [load] at app startup.
class TokenStorage {
  static const _channel = MethodChannel('mysun/secure_storage');
  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  Future<void> load() async {
    _accessToken = await _channel.invokeMethod<String>('get', {'key': _kAccessToken});
    _refreshToken = await _channel.invokeMethod<String>('get', {'key': _kRefreshToken});
  }

  Future<void> save({required String accessToken, String? refreshToken}) async {
    _accessToken = accessToken;
    await _channel.invokeMethod('put', {'key': _kAccessToken, 'value': accessToken});
    if (refreshToken != null) {
      _refreshToken = refreshToken;
      await _channel.invokeMethod('put', {'key': _kRefreshToken, 'value': refreshToken});
    }
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    await _channel.invokeMethod('remove', {'key': _kAccessToken});
    await _channel.invokeMethod('remove', {'key': _kRefreshToken});
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  throw UnimplementedError('tokenStorageProvider must be overridden in main.dart after TokenStorage.load()');
});
