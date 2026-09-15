import 'package:dio/dio.dart';

import 'package:mysun_app/core/constants/app_constants.dart';
import 'package:mysun_app/core/network/api_exception.dart';
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
    'student@mysun.ug': const _DemoAccount(
      'student123',
      UserProfile(
        id: 'usr-001',
        name: 'Amos Ekiring',
        email: 'student@mysun.ug',
        role: UserRole.student,
        studentId: 'SU/2023/BSC/0142',
        faculty: 'Faculty of Science & Education',
        program: 'BSc. Computer Science',
      ),
    ),
    'publisher@mysun.ug': const _DemoAccount(
      'publisher123',
      UserProfile(
        id: 'usr-010',
        name: 'Sarah Akena',
        email: 'publisher@mysun.ug',
        role: UserRole.publisher,
        faculty: 'HR Department',
      ),
    ),
    'admin@mysun.ug': const _DemoAccount(
      'admin123',
      UserProfile(
        id: 'usr-099',
        name: 'Grace Amongin',
        email: 'admin@mysun.ug',
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
    // Not yet exposed by the backend (Supabase Auth has this built in —
    // see backend/README.md) — no-op for now rather than a broken call.
  }

  @override
  Future<void> logout() => _tokenStorage.clear();
}
