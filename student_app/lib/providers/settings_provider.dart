import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in [main] with the resolved instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

class SettingsState {
  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.followedCategories = const {},
  });

  final ThemeMode themeMode;
  final Set<String> followedCategories;

  SettingsState copyWith({
    ThemeMode? themeMode,
    Set<String>? followedCategories,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        followedCategories: followedCategories ?? this.followedCategories,
      );
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _kTheme = 'theme_mode';
  static const _kCategories = 'followed_categories';

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
    );
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

final themeModeProvider =
    Provider<ThemeMode>((ref) => ref.watch(settingsProvider).themeMode);
