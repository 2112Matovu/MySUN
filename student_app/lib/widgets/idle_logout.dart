import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mysun_app/providers/auth_provider.dart';

/// Signs the user out after [timeout] without any touch, including time spent
/// with the app in the background. Wrapped around the shell for admin-level
/// accounts only (NFR-SEC-09).
class IdleLogout extends ConsumerStatefulWidget {
  const IdleLogout({
    super.key,
    required this.child,
    this.timeout = const Duration(minutes: 30),
  });

  final Widget child;
  final Duration timeout;

  @override
  ConsumerState<IdleLogout> createState() => _IdleLogoutState();
}

class _IdleLogoutState extends ConsumerState<IdleLogout> with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _lastActivity = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _arm();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  void _arm() {
    _timer?.cancel();
    _timer = Timer(widget.timeout, _expire);
  }

  void _touch() {
    _lastActivity = DateTime.now();
    _arm();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Timers pause with the app, so check the wall clock on return.
    if (state == AppLifecycleState.resumed &&
        DateTime.now().difference(_lastActivity) >= widget.timeout) {
      _expire();
    }
  }

  void _expire() {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('You were signed out after 30 minutes of inactivity.')),
    );
    ref.read(authProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _touch(),
      child: widget.child,
    );
  }
}
