import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mysun_app/app.dart';
import 'package:mysun_app/core/constants/app_constants.dart';
import 'package:mysun_app/core/network/token_storage.dart';
import 'package:mysun_app/providers/settings_provider.dart';

Future<void> main() async {
  // A release build that silently fell back to localhost would install fine
  // and then fail every request on a real phone.
  if (kReleaseMode && !AppConstants.hasExplicitApiBaseUrl) {
    throw StateError(
      'Release build is missing --dart-define=API_BASE_URL=https://<host>/api/v1',
    );
  }

  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final tokenStorage = TokenStorage();
  await tokenStorage.load();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        tokenStorageProvider.overrideWithValue(tokenStorage),
      ],
      child: const MySunApp(),
    ),
  );
}
