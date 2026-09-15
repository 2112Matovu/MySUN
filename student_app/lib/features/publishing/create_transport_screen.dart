import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mysun_app/data/models/publisher_submission.dart';
import 'package:mysun_app/data/models/transport_provider.dart';
import 'package:mysun_app/providers/publisher_provider.dart';
import 'package:mysun_app/providers/repositories.dart';
import 'package:mysun_app/providers/transport_providers.dart';

/// Publisher-only "add a transport provider" flow — the Transport
/// equivalent of Create Accommodation. A published provider is inserted at
/// the top of [TransportRepository.providers] and renders through the same
/// `TransportCard` as every seeded entry, unverified until an admin reviews
/// it (§4.4-style pattern, extended from announcements/events to Transport).
///
/// Boda-only for now, matching the rest of the Transport service. Pass
/// [draft] to resume an existing draft from the Drafts screen.
class CreateTransportProviderScreen extends ConsumerStatefulWidget {
  const CreateTransportProviderScreen({super.key, this.draft});

  final PublisherSubmission? draft;

  @override
  ConsumerState<CreateTransportProviderScreen> createState() =>
      _CreateTransportProviderScreenState();
}

class _CreateTransportProviderScreenState
    extends ConsumerState<CreateTransportProviderScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: _form?['name'] as String?);
  late final _phone = TextEditingController(text: _form?['phone'] as String?);
  late final _contactPerson =
      TextEditingController(text: _form?['contactPerson'] as String?);
  late final _operatingHours =
      TextEditingController(text: _form?['operatingHours'] as String?);
  late final _serviceAreas =
      TextEditingController(text: _form?['serviceAreas'] as String?);
  bool _saving = false;

  Map<String, dynamic>? get _form => widget.draft?.formData;

  Map<String, dynamic> _buildFormData() => {
        'name': _name.text,
        'phone': _phone.text,
        'contactPerson': _contactPerson.text,
        'operatingHours': _operatingHours.text,
        'serviceAreas': _serviceAreas.text,
      };

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _contactPerson.dispose();
    _operatingHours.dispose();
    _serviceAreas.dispose();
    super.dispose();
  }

  Future<void> _save({required bool submit}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      if (submit) {
        final areas = _serviceAreas.text
            .split(',')
            .map((a) => a.trim())
            .where((a) => a.isNotEmpty)
            .toList();
        final saved = await ref.read(transportRepositoryProvider).create(
              TransportProvider(
                id: '',
                name: _name.text.trim(),
                phoneNumber: _phone.text.trim(),
                serviceType: 'boda',
                contactPerson: _contactPerson.text.trim().isEmpty
                    ? null
                    : _contactPerson.text.trim(),
                operatingHours: _operatingHours.text.trim().isEmpty
                    ? null
                    : _operatingHours.text.trim(),
                serviceAreas: areas,
              ),
            );
        await ref.read(publisherRepositoryProvider).publish(
              draftId: widget.draft?.id,
              type: SubmissionType.transport,
              title: _name.text.trim(),
              contentId: saved.id,
            );
        ref.invalidate(transportProvidersProvider);
      } else {
        await ref.read(publisherRepositoryProvider).saveDraft(
              id: widget.draft?.id,
              type: SubmissionType.transport,
              title: _name.text.trim(),
              formData: _buildFormData(),
            );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      return;
    }
    ref.invalidate(publisherSubmissionsProvider);
    ref.invalidate(publisherDraftsProvider);

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(submit
          ? 'Provider published to Services > Transport'
          : 'Draft saved'),
    ));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Boda Rider')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Provider Name *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(labelText: 'Phone Number *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _contactPerson,
                decoration:
                    const InputDecoration(labelText: 'Contact Person'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _operatingHours,
                decoration: const InputDecoration(
                  labelText: 'Operating Hours',
                  hintText: 'e.g. 6:00 AM - 9:00 PM',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _serviceAreas,
                decoration: const InputDecoration(
                  labelText: 'Service Areas',
                  hintText: 'Comma-separated, e.g. Main Campus, Soroti Town',
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => _save(submit: false),
                      child: const Text('Save Draft'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : () => _save(submit: true),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Publish Provider'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
