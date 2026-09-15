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
    this.notificationsEnabled = true,
    this.eventRemindersEnabled = true,
    this.followedCategories = const {},
  });

  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final bool eventRemindersEnabled;
  final Set<String> followedCategories;

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    bool? eventRemindersEnabled,
    Set<String>? followedCategories,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        eventRemindersEnabled:
            eventRemindersEnabled ?? this.eventRemindersEnabled,
        followedCategories: followedCategories ?? this.followedCategories,
      );
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _kTheme = 'theme_mode';
  static const _kNotifications = 'notifications_enabled';
  static const _kReminders = 'event_reminders_enabled';
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
      notificationsEnabled: prefs.getBool(_kNotifications) ?? true,
      eventRemindersEnabled: prefs.getBool(_kReminders) ?? true,
      followedCategories:
          (prefs.getStringList(_kCategories) ?? const <String>[]).toSet(),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_kTheme, mode.name);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool(_kNotifications, value);
    state = state.copyWith(notificationsEnabled: value);
  }

  Future<void> setEventRemindersEnabled(bool value) async {
    await _prefs.setBool(_kReminders, value);
    state = state.copyWith(eventRemindersEnabled: value);
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
