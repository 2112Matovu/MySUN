import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mysun_app/core/theme/app_colors.dart';

/// Overridden in [main] with the resolved instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.followedCategories = const {},
    this.accent,
  });

  final ThemeMode themeMode;
  final Set<String> followedCategories;

  /// The accent colour the user picked, or null for MySun's default amber.
  final Color? accent;

  SettingsState copyWith({
    ThemeMode? themeMode,
    Set<String>? followedCategories,
    Color? accent,
    bool clearAccent = false,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        followedCategories: followedCategories ?? this.followedCategories,
        accent: clearAccent ? null : (accent ?? this.accent),
      );
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _kTheme = 'theme_mode';
  static const _kCategories = 'followed_categories';
  static const _kAccent = 'accent_color';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return SettingsState(
      themeMode: switch (prefs.getString(_kTheme)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      followedCategories:
          (prefs.getStringList(_kCategories) ?? const <String>[]).toSet(),
      accent: prefs.getInt(_kAccent) == null ? null : Color(prefs.getInt(_kAccent)!),
    );
  }

  /// Saves the accent colour; null puts MySun's default back.
  Future<void> setAccent(Color? color) async {
    if (color == null) {
      await _prefs.remove(_kAccent);
      state = state.copyWith(clearAccent: true);
    } else {
      await _prefs.setInt(_kAccent, color.toARGB32());
      state = state.copyWith(accent: color);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_kTheme, mode.name);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> toggleCategory(String category) async {
    final next = {...state.followedCategories};
    if (!next.add(category)) next.remove(category);
    await _prefs.setStringList(_kCategories, next.toList());
    state = state.copyWith(followedCategories: next);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

/// The colour the whole app theme is built from.
final accentColorProvider = Provider<Color>(
  (ref) => ref.watch(settingsProvider).accent ?? AppColors.brandSun,
);

final themeModeProvider =
    Provider<ThemeMode>((ref) => ref.watch(settingsProvider).themeMode);
