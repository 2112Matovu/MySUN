import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mysun_app/data/models/user_role.dart';
import 'package:mysun_app/features/admin/admin_dashboard_screen.dart';
import 'package:mysun_app/features/admin/analytics_screen.dart';
import 'package:mysun_app/features/admin/audit_log_screen.dart';
import 'package:mysun_app/features/admin/grant_role_screen.dart';
import 'package:mysun_app/features/admin/minor_admin_management_screen.dart';
import 'package:mysun_app/features/admin/moderation_queue_screen.dart';
import 'package:mysun_app/features/admin/user_management_screen.dart';
import 'package:mysun_app/features/announcements/announcement_detail_screen.dart';
import 'package:mysun_app/features/auth/forgot_password_screen.dart';
import 'package:mysun_app/features/auth/login_screen.dart';
import 'package:mysun_app/features/auth/signup_screen.dart';
import 'package:mysun_app/features/bookmarks/bookmarks_screen.dart';
import 'package:mysun_app/features/events/event_detail_screen.dart';
import 'package:mysun_app/features/events/events_screen.dart';
import 'package:mysun_app/features/home/home_screen.dart';
import 'package:mysun_app/features/notifications/notifications_screen.dart';
import 'package:mysun_app/features/profile/profile_screen.dart';
import 'package:mysun_app/data/models/publisher_submission.dart';
import 'package:mysun_app/features/publishing/create_accommodation_screen.dart';
import 'package:mysun_app/features/publishing/create_announcement_screen.dart';
import 'package:mysun_app/features/publishing/create_event_screen.dart';
import 'package:mysun_app/features/publishing/create_transport_screen.dart';
import 'package:mysun_app/features/publishing/drafts_screen.dart';
import 'package:mysun_app/features/publishing/my_performance_screen.dart';
import 'package:mysun_app/features/publishing/publisher_dashboard_screen.dart';
import 'package:mysun_app/features/search/search_screen.dart';
import 'package:mysun_app/features/services/accommodation_detail_screen.dart';
import 'package:mysun_app/features/services/services_hub_screen.dart';
import 'package:mysun_app/features/shell/main_shell.dart';
import 'package:mysun_app/features/splash/splash_screen.dart';
import 'package:mysun_app/features/transport/bookings_screen.dart';
import 'package:mysun_app/features/transport/bus_schedule_screen.dart';
import 'package:mysun_app/providers/auth_provider.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Reachable while logged out (spec §4.2).
const _publicRoutes = {'/splash', '/login', '/signup', '/forgot-password'};

/// Admin routes reachable only by a full Super Admin (§5.1) — a Minor Admin
/// gets Moderation but not user/analytics/minor-admin management.
const _superAdminOnlyRoutes = {
  '/admin/users',
  '/admin/analytics',
  '/admin/audit',
  '/admin/minor-admins',
  '/admin/grant-access',
};

/// Bridges Riverpod's [authProvider] to go_router's `refreshListenable` so a
/// login/logout re-runs `redirect` on the *current* location instead of
/// rebuilding [GoRouter] (which would reset navigation to `initialLocation`).
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

/// Role-based redirect per §4.2 "After Login - Role Detection" and §4.5
/// "Access Control Logic".
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      if (loc == '/splash') return null;

      if (!auth.isLoggedIn) {
        return _publicRoutes.contains(loc) ? null : '/login';
      }

      final role = auth.user!.role;
      if (_publicRoutes.contains(loc)) return '/';
      if (loc.startsWith('/publish') && !role.canPublish) return '/';
      if (loc.startsWith('/admin')) {
        if (!role.isAdminLevel) return '/';
        if (role != UserRole.admin && _superAdminOnlyRoutes.contains(loc)) {
          return '/admin';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignUpScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/admin/moderation',
        builder: (context, state) => const ModerationQueueScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/admin/users',
        builder: (context, state) => const UserManagementScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/admin/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/admin/audit',
        builder: (context, state) => const AuditLogScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/admin/minor-admins',
        builder: (context, state) => const MinorAdminManagementScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/admin/grant-access',
        builder: (context, state) =>
            GrantRoleScreen(presetRole: state.extra as UserRole?),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/announcement/:id',
        builder: (context, state) =>
            AnnouncementDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/event/:id',
        builder: (context, state) =>
            EventDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/bus-schedule',
        builder: (context, state) => const BusScheduleScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/accommodation/:id',
        builder: (context, state) =>
            AccommodationDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/bookings',
        builder: (context, state) => const BookingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/publish/drafts',
        builder: (context, state) => const DraftsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/publish/performance',
        builder: (context, state) => const MyPerformanceScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/publish/new-announcement',
        builder: (context, state) => CreateAnnouncementScreen(
            draft: state.extra as PublisherSubmission?),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/publish/new-event',
        builder: (context, state) =>
            CreateEventScreen(draft: state.extra as PublisherSubmission?),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/publish/new-accommodation',
        builder: (context, state) => CreateAccommodationScreen(
            draft: state.extra as PublisherSubmission?),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/publish/new-transport',
        builder: (context, state) => CreateTransportProviderScreen(
            draft: state.extra as PublisherSubmission?),
      ),
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: _rootKey,
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellKey,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/events',
                builder: (context, state) => const EventsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/services',
                builder: (context, state) => const ServicesHubScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookmarks',
                builder: (context, state) => const BookmarksScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/publish',
                builder: (context, state) => const PublisherDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/admin',
                builder: (context, state) => const AdminDashboardScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
