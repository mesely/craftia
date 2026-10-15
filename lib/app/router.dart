import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/models/complaint.dart';
import '../data/models/usta.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/customer_register_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/provider_register_screen.dart';
import '../features/auth/welcome_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/orders/requests_screen.dart';
import '../features/profile/profile_edit_screen.dart';
import '../features/provider/usta_detail_screen.dart';
import '../features/safety/complaint_screen.dart';
import '../features/safety/official_screen.dart';
import '../features/settings/document_screen.dart';
import '../features/settings/guide_screen.dart';
import '../features/settings/profile_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/support_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/shell/home_tab.dart';
import '../features/studio/promotion_screen.dart';
import '../features/studio/provider_page_screen.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// First launch goes to the welcome pages. After that everything can be browsed without an
/// account; sending a request, messaging, reviewing and complaining ask for one at that moment.
String? _redirect(AuthState auth, GoRouterState state) {
  final path = state.matchedLocation;
  final inAuthFlow =
      path == '/welcome' || path == '/login' || path.startsWith('/register');
  final isPublicInfo = path.startsWith('/legal');
  if (!auth.onboardingSeen && !inAuthFlow && !isPublicInfo) return '/welcome';
  // Signed-in people have no reason to see welcome/login again. (The usta registration page
  // shows its own "done" step after the account exists, so it is left alone.)
  if (auth.signedIn &&
      (path == '/welcome' ||
          path == '/login' ||
          path == '/register/customer')) {
    return '/';
  }
  if (!auth.isProvider && (path == '/page' || path == '/promote')) return '/';
  return null;
}

GoRouter buildRouter({
  String initialLocation = '/',
  Listenable? refreshListenable,
  GoRouterRedirect? redirect,
}) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: initialLocation,
    refreshListenable: refreshListenable,
    redirect: redirect,
    routes: [
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomeScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/register/customer',
        builder: (_, _) => const CustomerRegisterScreen(),
      ),
      GoRoute(
        path: '/register/provider',
        builder: (_, _) => const ProviderRegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, _) => const HomeTab())],
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
                path: '/page',
                builder: (_, _) => const ProviderPageScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'support',
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) => const SupportScreen(),
                  ),
                  GoRoute(
                    path: 'guide',
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) => const GuideScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Full-screen pages (hide the tab bar) and deep-linkable.
      GoRoute(
        path: '/usta/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) => UstaDetailScreen(
          id: state.pathParameters['id']!,
          initial: state.extra is Usta ? state.extra! as Usta : null,
        ),
      ),
      GoRoute(
        path: '/chat/:id',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            ChatScreen(conversationId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/profile',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            parentNavigatorKey: _rootKey,
            builder: (_, _) => const ProfileEditScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/promote',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const PromotionScreen(),
      ),
      GoRoute(
        path: '/notifications',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/official',
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const OfficialScreen(),
      ),
      GoRoute(
        path: '/complaint',
        parentNavigatorKey: _rootKey,
        builder: (_, state) {
          final target = state.extra;
          return ComplaintScreen(
            target: target is ComplaintTarget
                ? target
                : const ComplaintTarget(
                    type: ComplaintTargetType.provider,
                    id: '',
                    name: '',
                  ),
          );
        },
      ),
      GoRoute(
        path: '/legal/:doc',
        parentNavigatorKey: _rootKey,
        builder: (_, state) =>
            DocumentScreen(docId: state.pathParameters['doc']!),
      ),
    ],
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, _) => refresh.value++);
  final router = buildRouter(
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref.read(authProvider), state),
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
