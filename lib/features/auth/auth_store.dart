import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/account.dart';

/// What is remembered on the phone between launches.
class AuthSnapshot {
  const AuthSnapshot({this.account, this.onboardingSeen = false});

  final Account? account;
  final bool onboardingSeen;
}

class _LocalCredential {
  const _LocalCredential(this.account, this.salt, this.hash);

  final Account account;
  final String salt;
  final String hash;

  Map<String, dynamic> toJson() => {
    'account': account.toJson(),
    'salt': salt,
    'hash': hash,
  };

  factory _LocalCredential.fromJson(Map<String, dynamic> json) =>
      _LocalCredential(
        Account.fromJson(Map<String, dynamic>.from(json['account'] as Map)),
        (json['salt'] ?? '').toString(),
        (json['hash'] ?? '').toString(),
      );
}

/// Phone-side persistence for the mock sign-in stage: the session, the onboarding flag and a small
/// registry of accounts created on this device (passwords are stored only as salted SHA-256).
/// A real identity provider replaces this behind the same interface.
class AuthStore {
  static const _sessionKey = 'session_account';
  static const _onboardingKey = 'onboarding_seen';
  static const _registryKey = 'local_accounts';

  static Future<AuthSnapshot> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionKey);
      return AuthSnapshot(
        account: raw == null
            ? null
            : Account.fromJson(
                Map<String, dynamic>.from(jsonDecode(raw) as Map),
              ),
        onboardingSeen: prefs.getBool(_onboardingKey) ?? false,
      );
    } catch (_) {
      return const AuthSnapshot();
    }
  }

  static Future<void> saveSession(Account? account) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (account == null) {
        await prefs.remove(_sessionKey);
      } else {
        await prefs.setString(_sessionKey, jsonEncode(account.toJson()));
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

  /// Phone numbers compare by digits, e-mails by lower case.
  static String normalizeIdentifier(String raw) {
    final t = raw.trim().toLowerCase();
    if (t.contains('@')) return t;
    final digits = t.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('90')) {
      return '0${digits.substring(2)}';
    }
    if (digits.length == 10) return '0$digits';
    return digits.isEmpty ? t : digits;
  }

  static String _hash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();

  static Future<Map<String, _LocalCredential>> _registry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_registryKey);
      if (raw == null) return {};
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      return {
        for (final e in map.entries)
          e.key: _LocalCredential.fromJson(
            Map<String, dynamic>.from(e.value as Map),
          ),
      };
    } catch (_) {
      return {};
    }
  }

  static Future<void> _saveRegistry(Map<String, _LocalCredential> reg) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _registryKey,
        jsonEncode({for (final e in reg.entries) e.key: e.value.toJson()}),
      );
    } catch (_) {}
  }

  /// Remembers a new account under every identifier it can sign in with.
  static Future<void> register(Account account, String password) async {
    final reg = await _registry();
    final random = Random.secure();
    final salt = List.generate(
      8,
      (_) => random.nextInt(256).toRadixString(16),
    ).join();
    final cred = _LocalCredential(account, salt, _hash(salt, password));
    for (final id in [account.email, account.phone]) {
      if (id.trim().isNotEmpty) reg[normalizeIdentifier(id)] = cred;
    }
    await _saveRegistry(reg);
  }

  /// The matching account when [identifier] + [password] are right, otherwise null.
  static Future<Account?> verify(String identifier, String password) async {
    final cred = (await _registry())[normalizeIdentifier(identifier)];
    if (cred == null) return null;
    return _hash(cred.salt, password) == cred.hash ? cred.account : null;
  }

  static Future<bool> isRegistered(String identifier) async =>
      (await _registry()).containsKey(normalizeIdentifier(identifier));

  static Future<void> forget(Account account) async {
    final reg = await _registry();
    reg.removeWhere((_, c) => c.account.id == account.id);
    await _saveRegistry(reg);
  }

  static String newAccountId() {
    final random = Random.secure();
    return List.generate(
      12,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}
