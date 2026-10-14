import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/usta.dart';
import '../features/categories/categories_screen.dart';
import '../features/discovery/discovery_screen.dart';
import '../features/map/map_screen.dart';
import '../features/orders/requests_screen.dart';
import '../features/provider/usta_detail_screen.dart';
import '../features/settings/become_provider_screen.dart';
import '../features/settings/document_screen.dart';
import '../features/settings/guide_screen.dart';
import '../features/settings/profile_screen.dart';
import '../features/settings/support_screen.dart';
import '../features/shell/app_shell.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

GoRouter buildRouter({String initialLocation = '/'}) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/', builder: (_, _) => const DiscoveryScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/map', builder: (_, _) => const MapScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/categories',
                builder: (_, _) => const CategoriesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/requests',
                builder: (_, _) => const RequestsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'become-provider',
                    builder: (_, _) => const BecomeProviderScreen(),
                  ),
                  GoRoute(
                    path: 'support',
                    builder: (_, _) => const SupportScreen(),
                  ),
                  GoRoute(
                    path: 'guide',
                    builder: (_, _) => const GuideScreen(),
                  ),
                  GoRoute(
                    path: 'legal/:doc',
                    builder: (_, state) =>
                        DocumentScreen(docId: state.pathParameters['doc']!),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Full-screen (hides the tab bar) and deep-linkable: /usta/<id>
      GoRoute(
        path: '/usta/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => UstaDetailScreen(
          id: state.pathParameters['id']!,
          initial: state.extra is Usta ? state.extra! as Usta : null,
        ),
      ),
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final router = buildRouter();
  ref.onDispose(router.dispose);
  return router;
});
