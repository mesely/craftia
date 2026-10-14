import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_glyphs/phosphor_glyphs.dart';

import '../../core/theme/app_colors.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations =
      <({String label, IconData icon, IconData activeIcon})>[
        (
          label: 'Keşfet',
          icon: PhosphorIconsRegular.compass,
          activeIcon: PhosphorIconsFill.compass,
        ),
        (
          label: 'Harita',
          icon: PhosphorIconsRegular.mapTrifold,
          activeIcon: PhosphorIconsFill.mapTrifold,
        ),
        (
          label: 'Ara',
          icon: PhosphorIconsRegular.magnifyingGlass,
          activeIcon: PhosphorIconsBold.magnifyingGlass,
        ),
        (
          label: 'Taleplerim',
          icon: PhosphorIconsRegular.clipboardText,
          activeIcon: PhosphorIconsFill.clipboardText,
        ),
        (
          label: 'Profil',
          icon: PhosphorIconsRegular.user,
          activeIcon: PhosphorIconsFill.user,
        ),
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
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.activeIcon),
                label: d.label,
              ),
          ],
        ),
      ),
    );
  }
}
