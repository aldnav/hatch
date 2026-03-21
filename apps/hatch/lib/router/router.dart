import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:hatch/features/auth/auth_screen.dart';
import 'package:hatch/features/home/home_screen.dart';
import 'package:hatch/features/settings/settings_screen.dart';
import 'package:hatch/features/trip/trip_detail_screen.dart';
import 'package:hatch/providers/auth_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

/// Named route constants — use these instead of raw strings.
abstract final class Routes {
  static const auth = 'auth';
  static const home = 'home';
  static const tripDetail = 'trip-detail';
  static const settings = 'settings';
}

@Riverpod(keepAlive: true)
GoRouter router(RouterRef ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: true,

    /// Re-evaluate redirect whenever auth state changes.
    refreshListenable: _AuthNotifier(ref),

    redirect: (BuildContext context, GoRouterState state) {
      final onAuth = state.matchedLocation == '/auth';

      if (!isAuthenticated && !onAuth) return '/auth';
      if (isAuthenticated && onAuth) return '/home';
      return null;
    },

    routes: [
      GoRoute(
        path: '/auth',
        name: Routes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/home',
        name: Routes.home,
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'trip/:id',
            name: Routes.tripDetail,
            builder: (context, state) => TripDetailScreen(
              tripId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        name: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
}

/// Bridges Riverpod auth state into a [ChangeNotifier] so GoRouter
/// refreshes its redirect on every auth state change.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(RouterRef ref) {
    ref.listen(isAuthenticatedProvider, (_, __) => notifyListeners());
  }
}
