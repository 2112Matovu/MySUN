import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mysun_app/core/constants/categories.dart';
import 'package:mysun_app/data/models/event.dart';
import 'package:mysun_app/data/models/publisher_submission.dart';
import 'package:mysun_app/providers/events_provider.dart';
import 'package:mysun_app/providers/publisher_provider.dart';
import 'package:mysun_app/providers/repositories.dart';

const _organizers = [
  'Student Affairs Office',
  'Department of Computer Science',
  'Sports Department',
  'Careers & Counselling Unit',
  'Students\' Guild',
];

/// §4.4 Create Event (publisher only). Submitting publishes immediately to
/// the live Events list — the real endpoint is `POST /api/v1/events` (§9.2).
/// An admin can still remove it later if it breaks the terms of service
/// (§5.1).
///
/// Pass [draft] to resume an existing draft from the Drafts screen — saving
/// or publishing then updates that same record instead of creating a new one.
class CreateEventScreen extends ConsumerStatefulWidget {
  const CreateEventScreen({super.key, this.draft});

  final PublisherSubmission? draft;

  @override
  ConsumerState<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends ConsumerState<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: _form?['title'] as String?);
  late final _description =
      TextEditingController(text: _form?['description'] as String?);
  late final _location =
      TextEditingController(text: _form?['location'] as String?);
  late String _organizer = _form?['organizer'] as String? ?? _organizers.first;
  late String _category = _form?['category'] as String? ??
      eventCategories.firstWhere((c) => c != 'All');
  late DateTime? _startDate = _form?['startDate'] == null
      ? null
      : DateTime.parse(_form!['startDate'] as String);
  late TimeOfDay? _startTime = _form?['startHour'] == null
      ? null
      : TimeOfDay(
          hour: _form!['startHour'] as int, minute: _form!['startMinute'] as int);
  late TimeOfDay? _endTime = _form?['endHour'] == null
      ? null
      : TimeOfDay(
          hour: _form!['endHour'] as int, minute: _form!['endMinute'] as int);
  bool _saving = false;

  Map<String, dynamic>? get _form => widget.draft?.formData;

  Map<String, dynamic> _buildFormData() => {
        'title': _title.text,
        'description': _description.text,
        'location': _location.text,
        'organizer': _organizer,
        'category': _category,
        'startDate': _startDate?.toIso8601String(),
        'startHour': _startTime?.hour,
        'startMinute': _startTime?.minute,
        'endHour': _endTime?.hour,
        'endMinute': _endTime?.minute,
      };

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => isStart ? _startTime = picked : _endTime = picked);
    }
  }

  Future<void> _save({required bool submit}) async {
    if (!_formKey.currentState!.validate()) return;
    if (submit && (_startDate == null || _startTime == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a start date and time')),
      );
      return;
    }
    setState(() => _saving = true);
    final publisherRepo = ref.read(publisherRepositoryProvider);
    try {
      if (submit) {
        final start = DateTime(_startDate!.year, _startDate!.month,
            _startDate!.day, _startTime!.hour, _startTime!.minute);
        final end = _endTime == null
            ? null
            : DateTime(_startDate!.year, _startDate!.month, _startDate!.day,
                _endTime!.hour, _endTime!.minute);
        final saved = await ref.read(eventRepositoryProvider).create(
              Event(
                id: '',
                title: _title.text.trim(),
                description: _description.text.trim(),
                category: _category,
                organizerName: _organizer,
                dateTime: start,
                endDateTime: end,
                venue: _location.text.trim(),
              ),
            );
        await publisherRepo.publish(
          draftId: widget.draft?.id,
          type: SubmissionType.event,
          title: _title.text.trim(),
          contentId: saved.id,
        );
        ref.invalidate(eventsProvider);
        ref.invalidate(nextEventProvider);
      } else {
        await publisherRepo.saveDraft(
          id: widget.draft?.id,
          type: SubmissionType.event,
          title: _title.text.trim(),
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
      content: Text(submit ? 'Published to Events' : 'Draft saved'),
    ));
    context.pop();
  }

  String _fmtDate() => _startDate == null
      ? 'Select date'
      : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}';

  String _fmtTime(TimeOfDay? t) => t == null ? 'Select time' : t.format(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Event Title *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                    labelText: 'Description *', alignLabelWithHint: true),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text('Start Date: ${_fmtDate()}'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(true),
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text('Start: ${_fmtTime(_startTime)}'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(false),
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text('End: ${_fmtTime(_endTime)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _location,
                decoration: const InputDecoration(labelText: 'Location *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _organizer,
                decoration: const InputDecoration(labelText: 'Organizer *'),
                items: [
                  for (final o in _organizers)
                    DropdownMenuItem(value: o, child: Text(o)),
                ],
                onChanged: (v) => setState(() => _organizer = v!),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category *'),
                items: [
                  for (final c in eventCategories.where((c) => c != 'All'))
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Image upload arrives with the backend')),
                ),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Event Image'),
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
                          : const Text('Publish'),
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
