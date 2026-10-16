import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/core/constants/app_constants.dart';
import 'package:mysun_app/core/constants/categories.dart';
import 'package:mysun_app/data/models/notification_prefs.dart';
import 'package:mysun_app/providers/auth_provider.dart';
import 'package:mysun_app/providers/notification_prefs_provider.dart';
import 'package:mysun_app/providers/settings_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & settings')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    user.initials,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      Text(user.email,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.outline)),
                      if (user.faculty != null)
                        Text(user.faculty!,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(
                  icon: user.role.canPublish
                      ? Icons.verified_outlined
                      : Icons.person_outline,
                  text: 'Account: ${user.role.label}',
                ),
                if (user.studentId != null)
                  _Pill(icon: Icons.badge_outlined, text: user.studentId!),
                if (user.program != null)
                  _Pill(icon: Icons.school_outlined, text: user.program!),
              ],
            ),
          ),
          const Divider(height: 24),
          const _SectionTitle('Appearance'),
          _ThemeModeSelector(
            value: settings.themeMode,
            onChanged: settingsNotifier.setThemeMode,
          ),
          const Divider(height: 24),
          const _SectionTitle('Notifications'),
          const _NotificationCategorySwitches(),
          const Divider(height: 24),
          const _SectionTitle('Followed categories'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              'Followed categories are highlighted in your feed.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final c
                    in announcementCategories.where((c) => c != 'All'))
                  FilterChip(
                    label: Text(c),
                    selected: settings.followedCategories.contains(c),
                    onSelected: (_) => settingsNotifier.toggleCategory(c),
                  ),
              ],
            ),
          ),
          const Divider(height: 24),
          const _SectionTitle('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('${AppConstants.appName} for ${AppConstants.university}'),
            subtitle: Text('Version 1.0.0 • running on sample data'),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _soon(context),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Terms of use'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _soon(context),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _soon(context),
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => ref.read(authProvider.notifier).logout(),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            title: Text('Delete account',
                style: TextStyle(color: theme.colorScheme.error)),
            onTap: () => _soon(context),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("This isn't available yet.")),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.outline),
          const SizedBox(width: 6),
          Text(text, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}

/// Theme-mode selector: a [RadioGroup] ancestor manages the shared value so
/// each [RadioListTile] only needs its own `value`.
class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({
    required this.value,
    required this.onChanged,
  });

  final ThemeMode value;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<ThemeMode>(
      groupValue: value,
      onChanged: (m) {
        if (m != null) onChanged(m);
      },
      child: Column(
        children: [
          for (final mode in ThemeMode.values)
            RadioListTile<ThemeMode>(
              title: Text(switch (mode) {
                ThemeMode.system => 'Match device',
                ThemeMode.light => 'Light',
                ThemeMode.dark => 'Dark',
              }),
              value: mode,
            ),
        ],
      ),
    );
  }
}


/// One switch per notification category, saved to the server. Moderation
/// notices about your own content are always delivered.
class _NotificationCategorySwitches extends ConsumerWidget {
  const _NotificationCategorySwitches();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPrefsProvider);
    final theme = Theme.of(context);

    return prefs.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => ListTile(
        leading: const Icon(Icons.error_outline),
        title: const Text("Couldn't load notification settings"),
        subtitle: Text('$e'),
        trailing: TextButton(
          onPressed: () => ref.invalidate(notificationPrefsProvider),
          child: const Text('Retry'),
        ),
      ),
      data: (p) => Column(
        children: [
          for (final c in NotificationCategory.values)
            SwitchListTile(
              title: Text(c.title),
              subtitle: Text(c.subtitle),
              value: p.isOn(c),
              onChanged: (v) async {
                final messenger = ScaffoldMessenger.of(context);
                final error =
                    await ref.read(notificationPrefsProvider.notifier).set(c, v);
                if (error != null) {
                  messenger.showSnackBar(SnackBar(content: Text(error)));
                }
              },
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              'Notices about content you published, such as a removal, are '
              'always sent.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ],
      ),
    );
  }
}
