import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mysun_app/core/utils/date_fmt.dart';
import 'package:mysun_app/data/models/transport_provider.dart';
import 'package:mysun_app/providers/booking_providers.dart';
import 'package:mysun_app/providers/repositories.dart';
import 'package:mysun_app/providers/transport_providers.dart';

/// Lets a student give a rider 1-5 stars. Pre-fills their earlier rating.
Future<void> showRateDialog(
    BuildContext context, WidgetRef ref, TransportProvider rider) {
  return showDialog<void>(
    context: context,
    builder: (_) => _RateDialog(rider: rider),
  );
}

class _RateDialog extends ConsumerStatefulWidget {
  const _RateDialog({required this.rider});
  final TransportProvider rider;

  @override
  ConsumerState<_RateDialog> createState() => _RateDialogState();
}

class _RateDialogState extends ConsumerState<_RateDialog> {
  int _stars = 0;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    ref
        .read(transportRepositoryProvider)
        .myRating(widget.rider.id)
        .then((v) {
      if (mounted && v != null && _stars == 0) setState(() => _stars = v);
    }).catchError((_) {});
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      await ref.read(transportRepositoryProvider).rate(widget.rider.id, _stars);
      ref.invalidate(transportProvidersProvider);
      nav.pop();
      messenger.showSnackBar(
          const SnackBar(content: Text('Thanks, your rating was saved')));
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
      title: Text('Rate ${widget.rider.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: '$i star${i == 1 ? '' : 's'}',
                  onPressed: _saving ? null : () => setState(() => _stars = i),
                  icon: Icon(
                    i <= _stars ? Icons.star_rounded : Icons.star_border_rounded,
                    size: 34,
                    color: Colors.amber.shade600,
                  ),
                ),
            ],
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: (_stars == 0 || _saving) ? null : _submit,
          child: Text(_saving ? 'Saving...' : 'Submit'),
        ),
      ],
    );
  }
}

/// Bottom sheet to request a ride from [rider].
Future<void> showBookingSheet(
    BuildContext context, WidgetRef ref, TransportProvider rider) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _BookingSheet(rider: rider),
  );
}

class _BookingSheet extends ConsumerStatefulWidget {
  const _BookingSheet({required this.rider});
  final TransportProvider rider;

  @override
  ConsumerState<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends ConsumerState<_BookingSheet> {
  final _form = GlobalKey<FormState>();
  final _pickup = TextEditingController();
  final _destination = TextEditingController();
  final _note = TextEditingController();
  DateTime? _when; // null = as soon as possible
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _pickup.dispose();
    _destination.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _when ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_when ?? now.add(const Duration(minutes: 30))),
    );
    if (time == null) return;
    final picked =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (picked.isBefore(now)) {
      setState(() => _error = 'Pick a time in the future');
      return;
    }
    setState(() {
      _when = picked;
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      await ref.read(bookingRepositoryProvider).create(
            providerId: widget.rider.id,
            pickup: _pickup.text.trim(),
            destination: _destination.text.trim(),
            requestedTime: _when,
            note: _note.text,
          );
      ref.invalidate(myBookingsProvider);
      nav.pop();
      messenger.showSnackBar(SnackBar(
        content: Text('Request sent to ${widget.rider.name}'),
        action: SnackBarAction(
            label: 'View', onPressed: () => context.push('/bookings')),
      ));
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = '$e';
        });
      }
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().length < 2) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Book ${widget.rider.name}',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 14),
              TextFormField(
                controller: _pickup,
                maxLength: 120,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                    labelText: 'Pick-up point',
                    prefixIcon: Icon(Icons.trip_origin)),
                validator: _required,
              ),
              TextFormField(
                controller: _destination,
                maxLength: 120,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                    labelText: 'Destination',
                    prefixIcon: Icon(Icons.place_outlined)),
                validator: _required,
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('As soon as possible'),
                    selected: _when == null,
                    onSelected: (_) => setState(() => _when = null),
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.schedule, size: 18),
                    label: Text(_when == null
                        ? 'Choose a time'
                        : '${DateFmt.dayLabel(_when!)}, ${DateFmt.time(_when!)}'),
                    selected: _when != null,
                    onSelected: (_) => _pickTime(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _note,
                maxLength: 300,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Note for the rider (optional)'),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(_error!,
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
              FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50)),
                child: Text(_saving ? 'Sending...' : 'Send request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
