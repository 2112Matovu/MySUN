import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/core/utils/phone_launcher.dart';
import 'package:mysun_app/data/models/campus_service.dart';
import 'package:mysun_app/providers/auth_provider.dart';
import 'package:mysun_app/providers/booking_providers.dart';
import 'package:mysun_app/providers/repositories.dart';
import 'package:mysun_app/widgets/state_views.dart';

/// Food, health, IT support and library services on campus. Everyone can
/// browse; admins can add and remove entries.
class CampusServicesSection extends ConsumerWidget {
  const CampusServicesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(serviceCategoryFilterProvider);
    final async = ref.watch(campusServicesProvider);
    final isAdmin = ref.watch(currentUserProvider).role.isAdminLevel;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(campusServicesProvider);
        await ref.read(campusServicesProvider.future);
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: filter == null,
                    onSelected: (_) => ref
                        .read(serviceCategoryFilterProvider.notifier)
                        .state = null,
                  ),
                  for (final c in ServiceCategory.values) ...[
                    const SizedBox(width: 8),
                    ChoiceChip(
                      avatar: Icon(c.icon, size: 18),
                      label: Text(c.label),
                      selected: filter == c,
                      onSelected: (_) => ref
                          .read(serviceCategoryFilterProvider.notifier)
                          .state = c,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isAdmin)
            SliverToBoxAdapter(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextButton.icon(
                    onPressed: () => _showAddDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add a service'),
                  ),
                ),
              ),
            ),
          async.when(
            loading: () => const SliverFillRemaining(
                hasScrollBody: false, child: LoadingView()),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorView(
                message: '$e',
                onRetry: () => ref.invalidate(campusServicesProvider),
              ),
            ),
            data: (items) {
              if (items.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.storefront_outlined,
                    title: 'Nothing listed yet',
                    message: 'Campus services will appear here.',
                  ),
                );
              }
              return SliverList.builder(
                itemCount: items.length,
                itemBuilder: (context, i) =>
                    _ServiceCard(items[i], canDelete: isAdmin),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) {
    return showDialog<void>(
      context: context,
      builder: (_) => const _AddServiceDialog(),
    );
  }
}

class _ServiceCard extends ConsumerWidget {
  const _ServiceCard(this.service, {required this.canDelete});
  final CampusService service;
  final bool canDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    Widget line(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 15, color: theme.colorScheme.outline),
              const SizedBox(width: 6),
              Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
            ],
          ),
        );

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(service.category.icon,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(service.name,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      Text(service.category.label,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.outline)),
                    ],
                  ),
                ),
                if (canDelete)
                  IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await ref
                            .read(campusServiceRepositoryProvider)
                            .delete(service.id);
                        ref.invalidate(campusServicesProvider);
                      } catch (e) {
                        messenger.showSnackBar(SnackBar(content: Text('$e')));
                      }
                    },
                  ),
              ],
            ),
            if (service.description != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child:
                    Text(service.description!, style: theme.textTheme.bodyMedium),
              ),
            if (service.location != null)
              line(Icons.place_outlined, service.location!),
            if (service.openingHours != null)
              line(Icons.access_time, service.openingHours!),
            if (service.contactPhone != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () => callNumber(context, service.contactPhone!),
                  icon: const Icon(Icons.call, size: 18),
                  label: Text(service.contactPhone!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddServiceDialog extends ConsumerStatefulWidget {
  const _AddServiceDialog();

  @override
  ConsumerState<_AddServiceDialog> createState() => _AddServiceDialogState();
}

class _AddServiceDialogState extends ConsumerState<_AddServiceDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _hours = TextEditingController();
  final _phone = TextEditingController();
  ServiceCategory _category = ServiceCategory.food;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _description, _location, _hours, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final nav = Navigator.of(context);
    try {
      await ref.read(campusServiceRepositoryProvider).create(
            category: _category,
            name: _name.text,
            description: _description.text,
            location: _location.text,
            openingHours: _hours.text,
            contactPhone: _phone.text,
          );
      ref.invalidate(campusServicesProvider);
      nav.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a campus service'),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<ServiceCategory>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final c in ServiceCategory.values)
                    DropdownMenuItem(value: c, child: Text(c.label)),
                ],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              TextFormField(
                controller: _name,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().length < 2) ? 'Required' : null,
              ),
              TextFormField(
                controller: _description,
                maxLength: 500,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: _location,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              TextFormField(
                controller: _hours,
                decoration: const InputDecoration(labelText: 'Opening hours'),
              ),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Contact phone'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Add'),
        ),
      ],
    );
  }
}
