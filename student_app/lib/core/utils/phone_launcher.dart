import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the phone's dialer with [phone] filled in, ready to call.
Future<void> callNumber(BuildContext context, String phone) async {
  final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
  final messenger = ScaffoldMessenger.of(context);
  var launched = false;
  try {
    launched = await launchUrl(Uri(scheme: 'tel', path: cleaned));
  } catch (_) {}
  if (!launched) {
    messenger.showSnackBar(
      SnackBar(content: Text('Could not open the dialer for $phone')),
    );
  }
}
