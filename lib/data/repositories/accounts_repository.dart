import '../../core/errors/app_failure.dart';
import '../datasources/remote_data_source.dart';
import '../models/provider_application.dart';
import '../models/session.dart';
import '../models/account.dart';
import '../models/auth_methods.dart';

/// Sign-up, sign-in and the KVKK rights (data export, deletion), all against the database.
class AccountsRepository {
  AccountsRepository(this._remote);

  final RemoteDataSource _remote;

  Future<Session> registerCustomer({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) => guarded(
    () async => Session.fromJson(
      await _remote.register({
        'role': 'customer',
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'password': password,
      }),
    ),
  );

  /// Creates the account and the usta listing in one step.
  Future<Session> registerProvider({
    required String name,
    required String phone,
    required String email,
    required String password,
    required ProviderApplication application,
  }) => guarded(
    () async => Session.fromJson(
      await _remote.register({
        'role': 'provider',
        'name': name.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'password': password,
        'provider': application.toJson(),
      }),
    ),
  );

  Future<Session> login(String identifier, String password) => guarded(
    () async => Session.fromJson(
      await _remote.login({
        'identifier': identifier.trim(),
        'password': password,
      }),
    ),
  );

  Future<AuthMethods> methods() async {
    try {
      return AuthMethods.fromJson(await _remote.authMethods());
    } catch (_) {
      return AuthMethods.none;
    }
  }

  /// Google / Apple / SMS sign-in with a Firebase ID token. Returns a session, or what the
  /// server suggests for a first-time person who still has to choose a role.
  Future<FederatedOutcome> firebaseLogin(
    String idToken, {
    String? role,
    String? name,
    String? phone,
  }) => guarded(() async {
    final json = await _remote.firebaseLogin({
      'idToken': idToken,
      'role': ?role,
      'name': ?name,
      'phone': ?phone,
    });
    if (json['needsProfile'] == true) {
      final s = Map<String, dynamic>.from(json['suggested'] as Map? ?? {});
      return FederatedOutcome.needsProfile({
        'name': '${s['name'] ?? ''}',
        'email': '${s['email'] ?? ''}',
        'phone': '${s['phone'] ?? ''}',
      });
    }
    return FederatedOutcome.session(Session.fromJson(json));
  });

  /// A signed-in customer who starts offering services.
  Future<Session> upgrade(ProviderApplication application) => guarded(
    () async => Session.fromJson(
      await _remote.upgrade({'provider': application.toJson()}),
    ),
  );

  Future<Account> updateProfile(
    String id, {
    String? name,
    String? phone,
    String? email,
  }) => guarded(
    () async => Account.fromJson(
      await _remote.updateAccount(id, {
        'name': ?name,
        'phone': ?phone,
        'email': ?email,
      }),
    ),
  );

  /// Everything stored about the person, as JSON-encodable data.
  Future<Map<String, dynamic>> exportData(String accountId) =>
      guarded(() => _remote.exportData(accountId));

  Future<void> deleteAccount(String accountId) =>
      guarded(() => _remote.deleteAccount(accountId));
}
