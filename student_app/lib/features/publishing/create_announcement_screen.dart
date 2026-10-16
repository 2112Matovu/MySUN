import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mysun_app/core/constants/categories.dart';
import 'package:mysun_app/data/models/announcement.dart';
import 'package:mysun_app/data/models/publisher_submission.dart';
import 'package:mysun_app/providers/announcements_provider.dart';
import 'package:mysun_app/providers/auth_provider.dart';
import 'package:mysun_app/providers/publisher_provider.dart';
import 'package:mysun_app/providers/repositories.dart';
import 'package:mysun_app/widgets/image_upload_helper.dart';
import 'package:mysun_app/widgets/schedule_picker.dart';

const _departments = [
  'HR Department',
  'Academic Registrar',
  'Student Affairs',
  'ICT Directorate',
  'Finance Department',
];

/// §4.4 Create Announcement (publisher only). Submitting publishes
/// immediately to the live feed — the real endpoint is
/// `POST /api/v1/announcements` (§9.2). An admin can still remove it later
/// if it breaks the terms of service (§5.1).
///
/// Pass [draft] to resume an existing draft from the Drafts screen — saving
/// or publishing then updates that same record instead of creating a new one.
class CreateAnnouncementScreen extends ConsumerStatefulWidget {
  const CreateAnnouncementScreen({super.key, this.draft});

  final PublisherSubmission? draft;

  @override
  ConsumerState<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState
    extends ConsumerState<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: _form?['title'] as String?);
  late final _content =
      TextEditingController(text: _form?['content'] as String?);
  late String _department =
      _form?['department'] as String? ?? _departments.first;
  late String _category = _form?['category'] as String? ??
      announcementCategories.firstWhere((c) => c != 'All');
  late bool _hasExpiry = _form?['expiryDate'] != null;
  late DateTime? _expiryDate = _form?['expiryDate'] == null
      ? null
      : DateTime.parse(_form!['expiryDate'] as String);
  late TimeOfDay? _expiryTime = _form?['expiryHour'] == null
      ? null
      : TimeOfDay(
          hour: _form!['expiryHour'] as int,
          minute: _form!['expiryMinute'] as int);
  late String? _imageUrl = _form?['imageUrl'] as String?;
  late DateTime? _publishAt = _form?['publishAt'] == null
      ? null
      : DateTime.parse(_form!['publishAt'] as String);
  bool _saving = false;
  bool _uploadingImage = false;

  Map<String, dynamic>? get _form => widget.draft?.formData;

  /// Defaults to end-of-day when a date is picked but no specific time is.
  DateTime? get _expiresAt {
    if (!_hasExpiry || _expiryDate == null) return null;
    final t = _expiryTime ?? const TimeOfDay(hour: 23, minute: 59);
    return DateTime(_expiryDate!.year, _expiryDate!.month, _expiryDate!.day,
        t.hour, t.minute);
  }

  Map<String, dynamic> _buildFormData() => {
        'title': _title.text,
        'content': _content.text,
        'department': _department,
        'category': _category,
        'expiryDate': _hasExpiry ? _expiryDate?.toIso8601String() : null,
        'expiryHour': _hasExpiry ? _expiryTime?.hour : null,
        'expiryMinute': _hasExpiry ? _expiryTime?.minute : null,
        'imageUrl': _imageUrl,
        'publishAt': _publishAt?.toIso8601String(),
      };

  Future<void> _pickImage() async {
    setState(() => _uploadingImage = true);
    final url = await pickAndUploadImage(context, ref);
    if (!mounted) return;
    setState(() {
      _uploadingImage = false;
      if (url != null) _imageUrl = url;
    });
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  Future<void> _pickExpiryTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _expiryTime ?? const TimeOfDay(hour: 23, minute: 59),
    );
    if (picked != null) setState(() => _expiryTime = picked);
  }

  String _fmtExpiryDate() => _expiryDate == null
      ? 'Select date'
      : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}';

  String _fmtExpiryTime() =>
      _expiryTime == null ? 'End of day' : _expiryTime!.format(context);

  void _toast(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save({required bool submit}) async {
    if (!_formKey.currentState!.validate()) return;
    if (submit && _hasExpiry && _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick an expiry date, or turn expiry off')),
      );
      return;
    }
    if (submit && _publishAt != null) {
      if (_publishAt!.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
        _toast('That time has passed. Pick a new one or publish now.');
        return;
      }
      final expires = _expiresAt;
      if (expires != null && !expires.isAfter(_publishAt!)) {
        _toast('It would expire before it goes live');
        return;
      }
    }
    setState(() => _saving = true);
    final publisherRepo = ref.read(publisherRepositoryProvider);
    try {
      if (submit) {
        final user = ref.read(currentUserProvider);
        final saved = await ref.read(announcementRepositoryProvider).create(
              Announcement(
                id: '',
                title: _title.text.trim(),
                description: _content.text.trim(),
                category: _category,
                publisherName: user.faculty ?? _department,
                publishedAt: DateTime.now(),
                expiresAt: _expiresAt,
                publishAt: _publishAt,
                imageUrl: _imageUrl,
              ),
            );
        await publisherRepo.publish(
          draftId: widget.draft?.id,
          type: SubmissionType.announcement,
          title: _title.text.trim(),
          contentId: saved.id,
        );
        ref.invalidate(announcementsProvider);
      } else {
        await publisherRepo.saveDraft(
          id: widget.draft?.id,
          type: SubmissionType.announcement,
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
      content: Text(!submit
          ? 'Draft saved'
          : _publishAt == null
              ? 'Published to the campus feed'
              : 'Scheduled for ${describeSchedule(_publishAt!)}'),
    ));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Announcement')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _department,
                decoration: const InputDecoration(labelText: 'Department *'),
                items: [
                  for (final d in _departments)
                    DropdownMenuItem(value: d, child: Text(d)),
                ],
                onChanged: (v) => setState(() => _department = v!),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Category *'),
                items: [
                  for (final c
                      in announcementCategories.where((c) => c != 'All'))
                    DropdownMenuItem(value: c, child: Text(c)),
                ],
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _content,
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(
                    labelText: 'Content *', alignLabelWithHint: true),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set an expiry'),
                subtitle: const Text(
                    'Automatically removed from the feed after this time'),
                value: _hasExpiry,
                onChanged: (v) => setState(() {
                  _hasExpiry = v;
                  if (!v) {
                    _expiryDate = null;
                    _expiryTime = null;
                  }
                }),
              ),
              if (_hasExpiry) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickExpiryDate,
                        icon: const Icon(Icons.event_busy_outlined),
                        label: Text('Expires: ${_fmtExpiryDate()}'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickExpiryTime,
                        icon: const Icon(Icons.schedule_outlined),
                        label: Text(_fmtExpiryTime()),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              if (_imageUrl != null) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(_imageUrl!, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: IconButton.filled(
                        style: IconButton.styleFrom(
                            backgroundColor: Colors.black54),
                        onPressed: () => setState(() => _imageUrl = null),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              OutlinedButton.icon(
                onPressed: _uploadingImage ? null : _pickImage,
                icon: _uploadingImage
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_photo_alternate_outlined),
                label: Text(_imageUrl == null ? 'Add Image' : 'Replace Image'),
              ),
              const SizedBox(height: 8),
              SchedulePicker(
                value: _publishAt,
                onChanged: (v) => setState(() => _publishAt = v),
              ),
              const SizedBox(height: 16),
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
                          : Text(_publishAt == null ? 'Publish' : 'Schedule'),
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
