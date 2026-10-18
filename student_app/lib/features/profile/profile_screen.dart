import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/core/constants/app_constants.dart';
import 'package:mysun_app/core/constants/categories.dart';
import 'package:mysun_app/core/theme/app_colors.dart';
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
          const _SectionTitle('Accent colour'),
          _AccentPicker(
            value: settings.accent,
            onChanged: settingsNotifier.setAccent,
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
            subtitle: Text('Version 1.0.0'),
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
          if (user.role.isAdminLevel)
            ListTile(
              leading: const Icon(Icons.security_outlined),
              title: const Text('Two-factor authentication'),
              subtitle: const Text('Protect this admin account with an authenticator app'),
              onTap: () => _enrollMfa(context, ref),
            ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Download my data'),
            subtitle: const Text('Copies everything MySun holds about you'),
            onTap: () => _exportData(context, ref),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            title: Text('Delete account',
                style: TextStyle(color: theme.colorScheme.error)),
            onTap: () => _confirmDelete(context, ref),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _enrollMfa(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(authProvider.notifier);
    try {
      final enrollment = await notifier.enrollMfa();
      if (!context.mounted) return;
      final code = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Set up two-factor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('In an authenticator app (Google Authenticator, Authy...), '
                    'add an account using this key, then enter the 6-digit code it shows.'),
                const SizedBox(height: 12),
                SelectableText(enrollment.secret ?? enrollment.uri ?? '',
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700)),
                if (enrollment.secret != null)
                  TextButton.icon(
                    onPressed: () => Clipboard.setData(ClipboardData(text: enrollment.secret!)),
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copy key'),
                  ),
                TextField(
                  controller: code,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: '6-digit code'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Turn on')),
          ],
        ),
      );
      if (confirmed != true) return;
      await notifier.confirmMfa(enrollment.factorId, code.text);
      messenger.showSnackBar(const SnackBar(
          content: Text('Two-factor is on. You will be asked for a code each time you sign in.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Couldn't set up two-factor: $e")));
    }
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final json = await ref.read(authProvider.notifier).exportMyData();
      await Clipboard.setData(ClipboardData(text: json));
      messenger.showSnackBar(const SnackBar(
          content: Text('Your data was copied. Paste it into a note or file to keep it.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Couldn't export your data: $e")));
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
            'This permanently removes your account, bookmarks, bookings and '
            'notifications. Content you already published stays live until an '
            'admin removes it. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(authProvider.notifier).deleteAccount();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Couldn't delete the account: $e")));
    }
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
/// Colours offered as one-tap accents. The first entry is MySun's default.
const _accentPresets = <(String, Color)>[
  ('Sun', AppColors.brandSun),
  ('Sky', Color(0xFF2F80ED)),
  ('Emerald', Color(0xFF1E9E5A)),
  ('Teal', Color(0xFF00A3A3)),
  ('Violet', Color(0xFF7C4DFF)),
  ('Rose', Color(0xFFE91E63)),
  ('Crimson', Color(0xFFD32F2F)),
  ('Slate', Color(0xFF455A64)),
];

/// Lets the user recolour the whole app: preset swatches, a custom colour
/// from sliders, and a reset to the default.
class _AccentPicker extends StatelessWidget {
  const _AccentPicker({required this.value, required this.onChanged});

  final Color? value;
  final ValueChanged<Color?> onChanged;

  bool _isSelected(Color c) =>
      (value ?? AppColors.brandSun).toARGB32() == c.toARGB32();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final custom = value != null && !_accentPresets.any((p) => _isSelected(p.$2));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pick the colour you want the app to use for buttons, highlights and tabs.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final (name, color) in _accentPresets)
                _Swatch(
                  color: color,
                  label: name,
                  selected: _isSelected(color),
                  onTap: () => onChanged(color == AppColors.brandSun ? null : color),
                ),
              _Swatch(
                color: custom ? value! : theme.colorScheme.surfaceContainerHighest,
                label: 'Custom',
                selected: custom,
                icon: Icons.colorize_outlined,
                onTap: () async {
                  final picked = await showDialog<Color>(
                    context: context,
                    builder: (_) => _CustomAccentDialog(initial: value ?? AppColors.brandSun),
                  );
                  if (picked != null) onChanged(picked);
                },
              ),
            ],
          ),
          if (value != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => onChanged(null),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Back to the default colour'),
              ),
            ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : Colors.black87;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label accent colour',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 60,
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? theme.colorScheme.onSurface : theme.colorScheme.outlineVariant,
                    width: selected ? 3 : 1,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check, color: onColor)
                    : (icon == null ? null : Icon(icon, color: onColor, size: 20)),
              ),
              const SizedBox(height: 4),
              Text(label, style: theme.textTheme.labelSmall, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hue / saturation / brightness sliders with a live preview.
class _CustomAccentDialog extends StatefulWidget {
  const _CustomAccentDialog({required this.initial});
  final Color initial;

  @override
  State<_CustomAccentDialog> createState() => _CustomAccentDialogState();
}

class _CustomAccentDialogState extends State<_CustomAccentDialog> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initial);

  @override
  Widget build(BuildContext context) {
    final color = _hsv.toColor();
    return AlertDialog(
      title: const Text('Custom colour'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
          ),
          const SizedBox(height: 12),
          _slider('Colour', _hsv.hue, 360, (v) => _hsv = _hsv.withHue(v)),
          _slider('Richness', _hsv.saturation, 1, (v) => _hsv = _hsv.withSaturation(v)),
          _slider('Brightness', _hsv.value, 1, (v) => _hsv = _hsv.withValue(v)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
          onPressed: () => Navigator.of(context).pop(color),
          child: const Text('Use this'),
        ),
      ],
    );
  }

  Widget _slider(String label, double value, double max, void Function(double) set) {
    return Row(
      children: [
        SizedBox(width: 78, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.clamp(0, max),
            max: max,
            semanticFormatterCallback: (_) => label,
            onChanged: (v) => setState(() => set(v)),
          ),
        ),
      ],
    );
  }
}

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
