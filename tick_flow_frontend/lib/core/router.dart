import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/view/login_screen.dart';
import '../features/auth/viewmodel/auth_controller.dart';
import '../features/favourites/view/favourites_screen.dart';
import '../features/markets/view/markets_screen.dart';
import '../features/markets/view/search_screen.dart';
import '../features/menu/view/menu_screen.dart';
import '../features/notifications/view/notifications_screen.dart';
import '../features/portfolio/view/portfolio_screen.dart';
import 'widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();
  // Re-run redirect whenever the session changes (sign-in/out, restore done).
  final refresh = ValueNotifier(0);
  ref
    ..onDispose(refresh.dispose)
    ..listen(authControllerProvider, (_, _) => refresh.value++);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/markets',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final here = state.matchedLocation;
      if (auth.isLoading) return here == '/splash' ? null : '/splash';
      final signedIn = auth.value != null;
      if (!signedIn) return here == '/login' ? null : '/login';
      if (here == '/login' || here == '/splash') return '/markets';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const _SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      // Pushed over the tab shell (root navigator), so the bottom bar hides.
      GoRoute(
        path: '/search',
        parentNavigatorKey: rootNavigatorKey,
        builder: (_, _) => const SearchScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/markets', builder: (_, _) => const MarketsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/favourites', builder: (_, _) => const FavouritesScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/portfolio', builder: (_, _) => const PortfolioScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/notifications', builder: (_, _) => const NotificationsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/menu', builder: (_, _) => const MenuScreen())],
          ),
        ],
      ),
    ],
  );
});

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
