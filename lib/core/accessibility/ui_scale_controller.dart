import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ui_scale.dart';

const _prefsKey = 'ui_scale';

/// Loaded once in `bootstrap` (a single small prefs read) so the very first frame
/// already has the user's size. Tests override it.
final initialUiScaleProvider = Provider<UiScale>((ref) => UiScale.normal);

Future<UiScale> loadSavedUiScale() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return UiScale.fromStorage(prefs.getString(_prefsKey));
  } catch (_) {
    return UiScale.normal;
  }
}

class UiScaleController extends Notifier<UiScale> {
  @override
  UiScale build() => ref.watch(initialUiScaleProvider);

  Future<void> select(UiScale scale) async {
    if (scale == state) return;
    state = scale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, scale.storageKey);
    } catch (_) {
      // Not persisted this time; the choice still applies for this session.
    }
  }
}

final uiScaleProvider = NotifierProvider<UiScaleController, UiScale>(
  UiScaleController.new,
);
