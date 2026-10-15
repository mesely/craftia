import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../core/accessibility/ui_scale_controller.dart';
import '../core/theme/theme_mode_controller.dart';
import '../features/auth/auth_controller.dart';
import '../core/firebase/firebase_options.dart';
import '../features/auth/auth_store.dart';
import '../features/auth/firebase_identity.dart';
import '../features/auth/identity.dart';
import '../data/providers.dart';
import 'app.dart';

/// Keeps startup light: no GPS, network or database work happens before the first frame.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr_TR');
  final uiScale = await loadSavedUiScale();
  final themeMode = await loadSavedThemeMode();
  final auth = await AuthStore.load();
  // Firebase Authentication. If it cannot start the app still works with its own sign-in.
  IdentityProvider identity = const NoIdentity();
  try {
    await Firebase.initializeApp(options: UstaFirebase.current);
    identity = FirebaseIdentity();
  } catch (e) {
    debugPrint('Firebase unavailable, using the app\'s own sign-in: $e');
  }
  runApp(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        initialUiScaleProvider.overrideWithValue(uiScale),
        initialThemeModeProvider.overrideWithValue(themeMode),
        initialAuthProvider.overrideWithValue(auth),
        identityProvider.overrideWithValue(identity),
        // The API client sends the signed session and signs out when it is refused.
        sessionTokenProvider.overrideWith(
          (ref) => ref.watch(authProvider.select((s) => s.token)),
        ),
        sessionExpiredProvider.overrideWith(
          (ref) =>
              () => ref.read(authProvider.notifier).sessionExpired(),
        ),
      ],
      child: const UstaApp(),
    ),
  );
}
