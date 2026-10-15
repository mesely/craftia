import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../core/accessibility/ui_scale_controller.dart';
import '../core/theme/theme_mode_controller.dart';
import '../features/auth/auth_controller.dart';
import '../features/auth/auth_store.dart';
import 'app.dart';

/// Keeps startup light: no GPS, network or database work happens before the first frame.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  final uiScale = await loadSavedUiScale();
  final themeMode = await loadSavedThemeMode();
  final auth = await AuthStore.load();
  runApp(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        initialUiScaleProvider.overrideWithValue(uiScale),
        initialThemeModeProvider.overrideWithValue(themeMode),
        initialAuthProvider.overrideWithValue(auth),
      ],
      child: const UstaApp(),
    ),
  );
}
