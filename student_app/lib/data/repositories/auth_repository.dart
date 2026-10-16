import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:mysun_app/core/constants/app_constants.dart';
import 'package:mysun_app/core/network/api_exception.dart';
import 'package:mysun_app/core/network/google_auth_service.dart';
import 'package:mysun_app/core/network/token_storage.dart';
import 'package:mysun_app/data/models/user_profile.dart';
import 'package:mysun_app/data/models/user_role.dart';

/// Thrown by [AuthRepository] on bad credentials or a duplicate sign-up.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Thrown by [AuthRepository.login] when the account has two-factor turned
/// on: the password was right, but a 6-digit code is still needed.
class MfaRequired implements Exception {
  const MfaRequired(this.factorId);
  final String factorId;
}

/// What an authenticator app needs to add MySun: the secret to type in, or the
/// otpauth URI to open/scan, plus the factor id to confirm with.
class MfaEnrollment {
  const MfaEnrollment({required this.factorId, this.secret, this.uri});
  final String factorId;
  final String? secret;
  final String? uri;
}

/// Backed by `POST /api/v1/auth/login` etc. (spec §9.1).
abstract class AuthRepository {
  Future<UserProfile> login(String email, String password);

  Future<UserProfile> signUp({
    required String name,
    required String email,
    required String password,
    String? faculty,
    String? program,
  });

  Future<void> requestPasswordReset(String email);

  /// Second step of a two-factor sign-in, or the confirmation step of
  /// enrolment. Stores the upgraded session and returns the profile.
  Future<UserProfile> verifyMfa(String factorId, String code);

  /// Starts TOTP enrolment for the signed-in admin-level account.
  Future<MfaEnrollment> enrollMfa();

  /// Everything the backend holds about the signed-in user, as pretty JSON
  /// (`GET /auth/me/export`).
  Future<String> exportMyData();

  /// Permanently deletes the signed-in account (`DELETE /auth/me`).
  Future<void> deleteAccount();

  /// Signs in with Google (native/web picker via `google_sign_in`), then
  /// exchanges the ID token for a session via `POST /auth/google`. Returns
  /// `null` if the user cancelled the Google picker rather than throwing.
  Future<UserProfile?> loginWithGoogle();

  /// Clears anything the repository holds locally (e.g. tokens). A no-op
  /// for the mock — [AuthNotifier] handles its own local state regardless.
  Future<void> logout();
}

class _DemoAccount {
  const _DemoAccount(this.password, this.profile);
  final String password;
  final UserProfile profile;
}

/// Fixed demo accounts so the role-based flow (§4.2 "After Login - Role
/// Detection") can be exercised end to end without the real backend.
class MockAuthRepository implements AuthRepository {
  static final Map<String, _DemoAccount> _accounts = {
    'student@sun.ac.ug': const _DemoAccount(
      'student123',
      UserProfile(
        id: 'usr-001',
        name: 'Amos Ekiring',
        email: 'student@sun.ac.ug',
        role: UserRole.student,
        studentId: 'SU/2023/BSC/0142',
        faculty: 'Faculty of Science & Education',
        program: 'BSc. Computer Science',
      ),
    ),
    'publisher@sun.ac.ug': const _DemoAccount(
      'publisher123',
      UserProfile(
        id: 'usr-010',
        name: 'Sarah Akena',
        email: 'publisher@sun.ac.ug',
        role: UserRole.publisher,
        faculty: 'HR Department',
      ),
    ),
    'admin@sun.ac.ug': const _DemoAccount(
      'admin123',
      UserProfile(
        id: 'usr-099',
        name: 'Grace Amongin',
        email: 'admin@sun.ac.ug',
        role: UserRole.admin,
      ),
    ),
  };

  @override
  Future<UserProfile> login(String email, String password) async {
    await Future.delayed(AppConstants.mockLatency);
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      throw const AuthException('Incorrect email or password.');
    }
    return account.profile;
  }

  @override
  Future<UserProfile> signUp({
    required String name,
    required String email,
    required String password,
    String? faculty,
    String? program,
  }) async {
    await Future.delayed(AppConstants.mockLatency);
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const AuthException('An account with this email already exists.');
    }
    // New sign-ups start as regular students; only admins can promote to
    // publisher (§7.3 Role Assignment).
    return UserProfile(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email.trim(),
      role: UserRole.student,
      faculty: faculty,
      program: program,
    );
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await Future.delayed(AppConstants.mockLatency);
  }

  @override
  Future<String> exportMyData() async {
    await Future.delayed(AppConstants.mockLatency);
    return '{}';
  }

  @override
  Future<UserProfile> verifyMfa(String factorId, String code) async {
    await Future.delayed(AppConstants.mockLatency);
    return _accounts['student@sun.ac.ug']!.profile;
  }

  @override
  Future<MfaEnrollment> enrollMfa() async {
    await Future.delayed(AppConstants.mockLatency);
    return const MfaEnrollment(factorId: 'mock', secret: 'MOCKSECRET');
  }

  @override
  Future<void> deleteAccount() async {
    await Future.delayed(AppConstants.mockLatency);
  }

  @override
  Future<UserProfile?> loginWithGoogle() async {
    await Future.delayed(AppConstants.mockLatency);
    return _accounts['student@sun.ac.ug']!.profile;
  }

  @override
  Future<void> logout() async {}
}

/// Talks to the real backend (`backend/app/api/v1/auth.py`), which proxies
/// to Supabase Auth. Stores the returned access/refresh tokens via
/// [TokenStorage] so `api_client.dart`'s interceptor can attach them to
/// every other request — nothing above this layer needs to know a token
/// exists at all.
class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(this._dio, this._tokenStorage);
  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<UserProfile> _handleAuthResponse(Response res) async {
    final data = res.data as Map<String, dynamic>;
    await _tokenStorage.save(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String?,
    );
    if (data['mfa_required'] == true) {
      // Tokens are saved: the first-factor session is what authorises the
      // follow-up verify call. Nothing else works until the code is checked.
      throw MfaRequired(data['mfa_factor_id'] as String);
    }
    return UserProfile.fromJson(data['user'] as Map<String, dynamic>);
  }

  @override
  Future<UserProfile> login(String email, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'email': email.trim(),
        'password': password,
      });
      return await _handleAuthResponse(res);
    } on DioException catch (e) {
      throw AuthException(mapDioError(e).message);
    }
  }

  @override
  Future<UserProfile> signUp({
    required String name,
    required String email,
    required String password,
    String? faculty,
    String? program,
  }) async {
    try {
      final res = await _dio.post('/auth/signup', data: {
        'name': name,
        'email': email.trim(),
        'password': password,
        'faculty': faculty,
        'program': program,
      });
      return await _handleAuthResponse(res);
    } on DioException catch (e) {
      throw AuthException(mapDioError(e).message);
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    try {
      // Always 202, whether or not the address has an account.
      await _dio.post('/auth/password-reset', data: {'email': email.trim()});
    } on DioException catch (e) {
      throw AuthException(mapDioError(e).message);
    }
  }

  @override
  Future<UserProfile> verifyMfa(String factorId, String code) async {
    try {
      final res = await _dio.post('/auth/mfa/verify', data: {
        'factor_id': factorId,
        'code': code.trim(),
      });
      return await _handleAuthResponse(res);
    } on DioException catch (e) {
      throw AuthException(mapDioError(e).message);
    }
  }

  @override
  Future<MfaEnrollment> enrollMfa() async {
    try {
      final res = await _dio.post('/auth/mfa/enroll');
      final d = res.data as Map<String, dynamic>;
      return MfaEnrollment(
        factorId: d['factor_id'] as String,
        secret: d['secret'] as String?,
        uri: d['uri'] as String?,
      );
    } on DioException catch (e) {
      throw AuthException(mapDioError(e).message);
    }
  }

  @override
  Future<String> exportMyData() async {
    try {
      final res = await _dio.get('/auth/me/export');
      return const JsonEncoder.withIndent('  ').convert(res.data);
    } on DioException catch (e) {
      throw AuthException(mapDioError(e).message);
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      await _dio.delete('/auth/me');
    } on DioException catch (e) {
      throw AuthException(mapDioError(e).message);
    }
  }

  @override
  Future<UserProfile?> loginWithGoogle() async {
    final idToken = await GoogleAuthService.instance.signIn();
    if (idToken == null) return null; // user cancelled the picker
    try {
      final res = await _dio.post('/auth/google', data: {'id_token': idToken});
      return await _handleAuthResponse(res);
    } on DioException catch (e) {
      throw AuthException(mapDioError(e).message);
    }
  }

  @override
  Future<void> logout() async {
    await GoogleAuthService.instance.signOut();
    await _tokenStorage.clear();
  }
}
