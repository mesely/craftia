import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/icons/usta_icon.dart';
import '../../core/icons/usta_icons.dart';
import '../../core/theme/app_colors.dart';

/// Three destinations, each with a real job: find an usta, follow requests, settings.
/// There is deliberately no map tab: location is infrastructure, not a destination.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = <({String label, UstaIconData icon})>[
    (label: 'Ana Sayfa', icon: UstaIcons.home),
    (label: 'Taleplerim', icon: UstaIcons.requests),
    (label: 'Profil', icon: UstaIcons.user),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
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
            for (final d in _destinations)
              NavigationDestination(icon: UstaIcon(d.icon), label: d.label),
          ],
        ),
      ),
    );
  }
}
