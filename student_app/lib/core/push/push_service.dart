import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/core/constants/app_constants.dart';
import 'package:mysun_app/core/router/app_router.dart';
import 'package:mysun_app/providers/auth_provider.dart';
import 'package:mysun_app/providers/notifications_provider.dart';
import 'package:mysun_app/providers/repositories.dart';

/// Device push notifications through Firebase Cloud Messaging.
///
/// Entirely optional: with no `FIREBASE_*` build values (see
/// [AppConstants.pushConfigured]) every method is a quiet no-op and the app
/// keeps working with the in-app notification list only.
class PushService {
  PushService(this._ref);
  final Ref _ref;

  bool? _available;
  String? _token;
  String? _registeredFor;
  StreamSubscription<String>? _refreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<RemoteMessage>? _openedSub;

  Future<bool> _init() async {
    final known = _available;
    if (known != null) return known;
    if (kIsWeb || !AppConstants.pushConfigured) return _available = false;
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: AppConstants.firebaseApiKey,
          appId: AppConstants.firebaseAppId,
          messagingSenderId: AppConstants.firebaseSenderId,
          projectId: AppConstants.firebaseProjectId,
        ),
      );
      return _available = true;
    } catch (e) {
      debugPrint('Push disabled: Firebase failed to start ($e)');
      return _available = false;
    }
  }

  /// Asks for permission, then gives this phone's token to the backend.
  /// Safe to call repeatedly for the same user.
  Future<void> register(String userId) async {
    if (_registeredFor == userId) return;
    if (!await _init()) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await messaging.getToken();
      if (token == null) return;
      _token = token;
      final repo = _ref.read(notificationRepositoryProvider);
      await repo.registerDevice(token);
      _registeredFor = userId;

      _refreshSub ??= messaging.onTokenRefresh.listen((t) {
        _token = t;
        _ref.read(notificationRepositoryProvider).registerDevice(t).catchError((_) {});
      });
      // Pushes arrive silently while the app is open: just refresh the list.
      _foregroundSub ??= FirebaseMessaging.onMessage
          .listen((_) => _ref.invalidate(notificationsProvider));
      _openedSub ??= FirebaseMessaging.onMessageOpenedApp
          .listen((_) => _ref.read(routerProvider).go('/notifications'));

      if (await messaging.getInitialMessage() != null) {
        _ref.read(routerProvider).go('/notifications');
      }
    } catch (e) {
      debugPrint('Push registration failed: $e');
    }
  }

  /// Stops pushes for the signed-in user (call before signing out, while the
  /// auth token still works).
  Future<void> unregister() async {
    final token = _token;
    _registeredFor = null;
    if (token == null) return;
    try {
      await _ref.read(notificationRepositoryProvider).unregisterDevice(token);
    } catch (_) {}
  }
}

final pushServiceProvider = Provider<PushService>((ref) => PushService(ref));

/// Watched once by the app root: registers the device whenever a user is
/// signed in (including a session restored at launch).
final pushBootstrapProvider = Provider<void>((ref) {
  void sync(AuthState next) {
    final id = next.user?.id;
    if (next.isLoggedIn && id != null) {
      ref.read(pushServiceProvider).register(id);
    }
  }

  ref.listen<AuthState>(authProvider, (_, next) => sync(next));
  sync(ref.read(authProvider));
});
