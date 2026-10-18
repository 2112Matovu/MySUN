import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mysun_app/core/theme/app_colors.dart';
import 'package:mysun_app/core/theme/app_theme.dart';
import 'package:mysun_app/providers/settings_provider.dart';

Future<ProviderContainer> _container(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
}

void main() {
  test('defaults to MySun amber', () async {
    final c = await _container({});
    expect(c.read(accentColorProvider), AppColors.brandSun);
  });

  test('a chosen accent is applied, saved and restored', () async {
    final c = await _container({});
    await c.read(settingsProvider.notifier).setAccent(const Color(0xFF2F80ED));
    expect(c.read(accentColorProvider), const Color(0xFF2F80ED));

    // A fresh start (new container, same storage) still has it.
    final prefs = await SharedPreferences.getInstance();
    final again = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
    expect(again.read(accentColorProvider).toARGB32(), 0xFF2F80ED);
  });

  test('reset puts the default back', () async {
    final c = await _container({'accent_color': 0xFFD32F2F});
    expect(c.read(settingsProvider).accent, isNotNull);
    await c.read(settingsProvider.notifier).setAccent(null);
    expect(c.read(accentColorProvider), AppColors.brandSun);
  });

  test('the theme is built from the accent', () {
    const blue = Color(0xFF2F80ED);
    expect(AppTheme.light(blue).colorScheme.primary,
        isNot(AppTheme.light().colorScheme.primary));
  });
}
