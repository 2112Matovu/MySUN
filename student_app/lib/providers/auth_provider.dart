import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/data/mock/mock_data.dart';
import 'package:mysun_app/data/models/user_profile.dart';
import 'package:mysun_app/data/repositories/auth_repository.dart';
import 'package:mysun_app/providers/repositories.dart';
import 'package:mysun_app/providers/settings_provider.dart';

enum AuthStatus { loggedOut, loggedIn }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
  });

  final AuthStatus status;
  final UserProfile? user;
  final bool isSubmitting;
  final String? errorMessage;

  bool get isLoggedIn => status == AuthStatus.loggedIn;

  AuthState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) =>
      AuthState(
        status: status,
        user: user,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

/// Local mock session (spec §4.2, §9.1). `login`/`signUp` call
/// [AuthRepository] — swap that for the real HTTP client and this notifier
/// doesn't change.
class AuthNotifier extends Notifier<AuthState> {
  static const _kLoggedIn = 'is_logged_in';
  static const _kUser = 'user_profile';

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final loggedIn = prefs.getBool(_kLoggedIn) ?? false;
    final raw = prefs.getString(_kUser);
    if (loggedIn && raw != null) {
      try {
        final user = UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
        return AuthState(status: AuthStatus.loggedIn, user: user);
      } catch (_) {
        // Fall through to logged-out below.
      }
    }
    return const AuthState(status: AuthStatus.loggedOut);
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final user = await _repo.login(email, password);
      await _persist(user);
      state = AuthState(status: AuthStatus.loggedIn, user: user);
    } on AuthException catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.message);
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    String? faculty,
    String? program,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final user = await _repo.signUp(
        name: name,
        email: email,
        password: password,
        faculty: faculty,
        program: program,
      );
      await _persist(user);
      state = AuthState(status: AuthStatus.loggedIn, user: user);
    } on AuthException catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.message);
    }
  }

  Future<void> requestPasswordReset(String email) => _repo.requestPasswordReset(email);

  Future<void> loginWithGoogle() async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final user = await _repo.loginWithGoogle();
      if (user == null) {
        // User cancelled the Google picker — not an error.
        state = state.copyWith(isSubmitting: false);
        return;
      }
      await _persist(user);
      state = AuthState(status: AuthStatus.loggedIn, user: user);
    } on AuthException catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.message);
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_kLoggedIn, false);
    state = const AuthState(status: AuthStatus.loggedOut);
  }

  void clearError() => state = state.copyWith(clearError: true);

  Future<void> _persist(UserProfile user) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_kLoggedIn, true);
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// Convenience accessor for widgets that only need the signed-in profile.
/// Falls back to the seed profile so screens render sensibly in previews.
final currentUserProvider = Provider<UserProfile>(
  (ref) => ref.watch(authProvider).user ?? MockData.currentUser,
);
