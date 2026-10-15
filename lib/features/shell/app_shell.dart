import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_colors.dart';
import '../auth/auth_controller.dart';
import '../orders/requests_controller.dart';
import 'app_top_bar.dart';

/// Three destinations, each with a real job: find an usta, follow requests, settings.
/// There is deliberately no map tab: location is infrastructure, not a destination.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProvider = ref.watch(authProvider.select((s) => s.isProvider));
    final unread = ref.watch(unreadCountProvider);
    final destinations = <({String label, UstaIconData icon, int badge})>[
      (label: 'Ana Sayfa', icon: UstaIcons.home, badge: 0),
      (
        label: isProvider ? 'Talepler' : 'Taleplerim',
        icon: UstaIcons.requests,
        badge: unread,
      ),
      (label: 'Ayarlar', icon: UstaIcons.settings, badge: 0),
    ];

    return Scaffold(
      body: Column(
        children: [
          SafeArea(bottom: false, child: const AppTopBar()),
          Expanded(
            // The top bar already took the status-bar space.
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: navigationShell,
            ),
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (i) => navigationShell.goBranch(
            i,
            initialLocation: i == navigationShell.currentIndex,
          ),
          destinations: [
            for (final d in destinations)
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: d.badge > 0,
                  label: Text('${d.badge > 9 ? '9+' : d.badge}'),
                  child: UstaIcon(d.icon),
                ),
                label: d.label,
              ),
          ],
        ),
      ),
    );
  }
}
