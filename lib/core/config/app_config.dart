import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Public runtime configuration only. Database credentials never reach the app.
abstract final class AppConfig {
  static const _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// `--dart-define=API_BASE_URL=https://api.example.com`. Defaults to the local
  /// backend (Android emulators reach the host machine at 10.0.2.2).
  static String get apiBaseUrl {
    if (_apiBaseUrl.isNotEmpty) return _apiBaseUrl;
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  /// Relative server paths (e.g. chat photos) become absolute URLs here.
  static String resolve(String pathOrUrl) =>
      pathOrUrl.startsWith('http') ? pathOrUrl : '$apiBaseUrl$pathOrUrl';

  static const supportEmail = 'destek@usta.app';
  static const legalEmail = 'hukuk@ustaapp.com';
  static const appVersion = '2.1.0';
}
