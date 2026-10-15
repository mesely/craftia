import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';
import '../discovery/discovery_screen.dart';
import '../studio/provider_dashboard_screen.dart';

/// The first tab. Customers (and guests) search for ustas; an usta gets their own dashboard.
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProvider = ref.watch(authProvider.select((s) => s.isProvider));
    return isProvider
        ? const ProviderDashboardScreen()
        : const DiscoveryScreen();
  }
}
