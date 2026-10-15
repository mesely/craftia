import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/account.dart';

/// What is remembered on the phone between launches.
class AuthSnapshot {
  const AuthSnapshot({this.account, this.token, this.onboardingSeen = false});

  final Account? account;

  /// The signed session issued by the server (sent as `Authorization: Bearer …`).
  final String? token;
  final bool onboardingSeen;
}

/// Phone-side persistence: the session and the onboarding flag. Passwords are never stored here;
/// accounts and password hashes live in the database behind the API.
class AuthStore {
  static const _sessionKey = 'session_account';
  static const _tokenKey = 'session_token';
  static const _onboardingKey = 'onboarding_seen';

  static Future<AuthSnapshot> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionKey);
      final token = prefs.getString(_tokenKey);
      // An account without a server session (older builds) cannot act: start signed out.
      final signedIn = raw != null && token != null && token.isNotEmpty;
      return AuthSnapshot(
        account: signedIn
            ? Account.fromJson(
                Map<String, dynamic>.from(jsonDecode(raw) as Map),
              )
            : null,
        token: signedIn ? token : null,
        onboardingSeen: prefs.getBool(_onboardingKey) ?? false,
      );
    } catch (_) {
      return const AuthSnapshot();
    }
  }

  static Future<void> saveSession(Account? account, String? token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (account == null || token == null) {
        await prefs.remove(_sessionKey);
        await prefs.remove(_tokenKey);
      } else {
        await prefs.setString(_sessionKey, jsonEncode(account.toJson()));
        await prefs.setString(_tokenKey, token);
      }
    } catch (_) {
      // The session just won't survive a restart.
    }
  }

  static Future<void> saveOnboardingSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
    } catch (_) {}
  }
}
