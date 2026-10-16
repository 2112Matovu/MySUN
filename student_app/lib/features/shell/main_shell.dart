import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mysun_app/providers/auth_provider.dart';
import 'package:mysun_app/widgets/idle_logout.dart';

/// Bottom-nav host (spec §4.3, §4.5). Home/Events/Services/Bookmarks are
/// always visible; Publish (publishers) and Admin (admin/minor-admin) are
/// independently conditional extra branches — an admin who isn't a publisher
/// sees Admin but not Publish, so the destination shown at a given position
/// doesn't always match its underlying branch index. [_Tab] keeps the two
/// paired so tapping a visible tab always jumps to the right branch.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _go(int branchIndex) {
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserProvider).role;

    final tabs = <_Tab>[
      const _Tab(
        branchIndex: 0,
        destination: NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
      ),
      const _Tab(
        branchIndex: 1,
        destination: NavigationDestination(
          icon: Icon(Icons.event_outlined),
          selectedIcon: Icon(Icons.event),
          label: 'Events',
        ),
      ),
      const _Tab(
        branchIndex: 2,
        destination: NavigationDestination(
          icon: Icon(Icons.apps_outlined),
          selectedIcon: Icon(Icons.apps),
          label: 'Services',
        ),
      ),
      const _Tab(
        branchIndex: 3,
        destination: NavigationDestination(
          icon: Icon(Icons.bookmark_border_outlined),
          selectedIcon: Icon(Icons.bookmark),
          label: 'Bookmarks',
        ),
      ),
      if (role.canPublish)
        const _Tab(
          branchIndex: 4,
          destination: NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Publish',
          ),
        ),
      if (role.isAdminLevel)
        const _Tab(
          branchIndex: 5,
          destination: NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
        ),
    ];

    final selected = tabs.indexWhere((t) => t.branchIndex == navigationShell.currentIndex);

    final scaffold = Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected < 0 ? 0 : selected,
        onDestinationSelected: (i) => _go(tabs[i].branchIndex),
        destinations: [for (final t in tabs) t.destination],
      ),
    );
    // Admin sessions time out after 30 idle minutes (NFR-SEC-09).
    return role.isAdminLevel ? IdleLogout(child: scaffold) : scaffold;
  }
}

class _Tab {
  const _Tab({required this.branchIndex, required this.destination});
  final int branchIndex;
  final NavigationDestination destination;
}
