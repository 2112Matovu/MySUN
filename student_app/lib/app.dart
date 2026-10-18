import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/core/push/push_service.dart';
import 'package:mysun_app/core/router/app_router.dart';
import 'package:mysun_app/core/theme/app_theme.dart';
import 'package:mysun_app/providers/settings_provider.dart';

class MySunApp extends ConsumerWidget {
  const MySunApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(accentColorProvider);
    ref.watch(pushBootstrapProvider);

    return MaterialApp.router(
      title: 'MySun',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accent),
      darkTheme: AppTheme.dark(accent),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
