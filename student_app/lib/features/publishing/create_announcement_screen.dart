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
  bool _saving = false;

  Map<String, dynamic>? get _form => widget.draft?.formData;

  Map<String, dynamic> _buildFormData() => {
        'title': _title.text,
        'content': _content.text,
        'department': _department,
        'category': _category,
      };

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _save({required bool submit}) async {
    if (!_formKey.currentState!.validate()) return;
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
      content: Text(submit ? 'Published to the campus feed' : 'Draft saved'),
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
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Image upload arrives with the backend')),
                ),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add Image'),
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
