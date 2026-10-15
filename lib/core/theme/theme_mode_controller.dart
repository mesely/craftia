import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'theme_mode';

/// The in-app "Görünüm" setting. [system] follows the phone.
enum AppThemeMode {
  system('system', 'Telefonu izle', 'Telefonun açık ya da koyu ayarına uyar.'),
  light('light', 'Açık', 'Aydınlık ortamlar için.'),
  dark('dark', 'Koyu', 'Gece ve loş ortamlar için, gözü yormaz.');

  const AppThemeMode(this.storageKey, this.label, this.description);

  final String storageKey;
  final String label;
  final String description;

  static AppThemeMode fromStorage(String? key) =>
      AppThemeMode.values.firstWhere(
        (m) => m.storageKey == key,
        orElse: () => AppThemeMode.system,
      );

  Brightness resolve(Brightness platform) => switch (this) {
    AppThemeMode.system => platform,
    AppThemeMode.light => Brightness.light,
    AppThemeMode.dark => Brightness.dark,
  };
}

/// Loaded once in `bootstrap` so the first frame already has the right colours.
final initialThemeModeProvider = Provider<AppThemeMode>(
  (ref) => AppThemeMode.light,
);

Future<AppThemeMode> loadSavedThemeMode() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return AppThemeMode.fromStorage(prefs.getString(_prefsKey));
  } catch (_) {
    return AppThemeMode.system;
  }
}

class ThemeModeController extends Notifier<AppThemeMode> {
  @override
  AppThemeMode build() => ref.watch(initialThemeModeProvider);

  Future<void> select(AppThemeMode mode) async {
    if (mode == state) return;
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.storageKey);
    } catch (_) {
      // Not persisted this time; the choice still applies for this session.
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, AppThemeMode>(
  ThemeModeController.new,
);
