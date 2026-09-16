import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mysun_app/data/models/accommodation_listing.dart';
import 'package:mysun_app/data/models/publisher_submission.dart';
import 'package:mysun_app/providers/accommodation_providers.dart';
import 'package:mysun_app/providers/auth_provider.dart';
import 'package:mysun_app/providers/publisher_provider.dart';
import 'package:mysun_app/providers/repositories.dart';
import 'package:mysun_app/widgets/image_upload_helper.dart';

/// §4.4-style publisher form for the Accommodation service (§6, §6.4),
/// extended with pricing / gazetted status / room-sharing / photos.
///
/// Pass [draft] to resume an existing draft from the Drafts screen — saving
/// or publishing then updates that same record instead of creating a new one.
class CreateAccommodationScreen extends ConsumerStatefulWidget {
  const CreateAccommodationScreen({super.key, this.draft});

  final PublisherSubmission? draft;

  @override
  ConsumerState<CreateAccommodationScreen> createState() =>
      _CreateAccommodationScreenState();
}

class _CreateAccommodationScreenState
    extends ConsumerState<CreateAccommodationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: _form?['name'] as String?);
  late final _location =
      TextEditingController(text: _form?['location'] as String?);
  late final _price = TextEditingController(text: _form?['price'] as String?);
  late final _phone = TextEditingController(text: _form?['phone'] as String?);
  late final _description =
      TextEditingController(text: _form?['description'] as String?);

  late AccommodationType _type = _form?['type'] == null
      ? AccommodationType.hostel
      : AccommodationType.fromJson(_form!['type'] as String);
  late RoomSharingType _roomSharing = _form?['roomSharing'] == null
      ? RoomSharingType.shared
      : RoomSharingType.fromJson(_form!['roomSharing'] as String);
  late bool _isGazetted = _form?['isGazetted'] as bool? ?? false;
  late final List<String> _images =
      (_form?['images'] as List<dynamic>?)?.cast<String>().toList() ?? [];
  bool _saving = false;
  bool _uploadingImage = false;

  Map<String, dynamic>? get _form => widget.draft?.formData;

  Map<String, dynamic> _buildFormData() => {
        'name': _name.text,
        'location': _location.text,
        'price': _price.text,
        'phone': _phone.text,
        'description': _description.text,
        'type': _type.toJson(),
        'roomSharing': _roomSharing.toJson(),
        'isGazetted': _isGazetted,
        'images': _images,
      };

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _price.dispose();
    _phone.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _addImage() async {
    setState(() => _uploadingImage = true);
    final url = await pickAndUploadImage(context, ref);
    if (!mounted) return;
    setState(() {
      _uploadingImage = false;
      if (url != null) _images.add(url);
    });
  }

  Future<void> _save({required bool submit}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      if (submit) {
        final user = ref.read(currentUserProvider);
        final saved = await ref.read(accommodationRepositoryProvider).create(
              AccommodationListing(
                id: '',
                name: _name.text.trim(),
                type: _type,
                location: _location.text.trim(),
                price: int.tryParse(_price.text.trim()) ?? 0,
                isGazetted: _isGazetted,
                roomSharing: _roomSharing,
                contactPhone: _phone.text.trim(),
                imageUrls: _images,
                description: _description.text.trim().isEmpty
                    ? null
                    : _description.text.trim(),
                publisherName: user.faculty ?? user.name,
              ),
            );
        await ref.read(publisherRepositoryProvider).publish(
              draftId: widget.draft?.id,
              type: SubmissionType.accommodation,
              title: _name.text.trim(),
              contentId: saved.id,
            );
        ref.invalidate(accommodationsProvider);
      } else {
        await ref.read(publisherRepositoryProvider).saveDraft(
              id: widget.draft?.id,
              type: SubmissionType.accommodation,
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
          ? 'Listing published to Services > Accommodation'
          : 'Draft saved'),
    ));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Accommodation Listing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration:
                    const InputDecoration(labelText: 'Hostel/Rental Name *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<AccommodationType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type *'),
                items: [
                  for (final t in AccommodationType.values)
                    DropdownMenuItem(value: t, child: Text(t.label)),
                ],
                onChanged: (v) => setState(() => _type = v!),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _location,
                decoration: const InputDecoration(
                  labelText: 'Location *',
                  hintText: 'e.g. 5 min walk from Main Gate',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price per ${_type.priceUnit} (UGX) *',
                  prefixText: 'UGX ',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (int.tryParse(v.trim()) == null) return 'Numbers only';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Gazetted by the university'),
                subtitle: const Text(
                    'On = registered/approved. Off = independent listing.'),
                value: _isGazetted,
                onChanged: (v) => setState(() => _isGazetted = v),
              ),
              const SizedBox(height: 6),
              Text('Room sharing *', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final r in RoomSharingType.values)
                    ChoiceChip(
                      label: Text(r.label),
                      selected: _roomSharing == r,
                      onSelected: (_) => setState(() => _roomSharing = r),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration:
                    const InputDecoration(labelText: 'Contact phone *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                    labelText: 'Description', alignLabelWithHint: true),
              ),
              const SizedBox(height: 14),
              Text('Photos', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < _images.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                _images[i],
                                width: 90,
                                height: 90,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _images.removeAt(i)),
                                child: const CircleAvatar(
                                  radius: 10,
                                  backgroundColor: Colors.black54,
                                  child: Icon(Icons.close,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    InkWell(
                      onTap: _uploadingImage ? null : _addImage,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Theme.of(context).colorScheme.outline),
                        ),
                        child: _uploadingImage
                            ? const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : const Icon(Icons.add_a_photo_outlined),
                      ),
                    ),
                  ],
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
                          : const Text('Publish Listing'),
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
