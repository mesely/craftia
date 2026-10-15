import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/account.dart';
import '../../data/models/auth_methods.dart';
import '../../data/models/provider_application.dart';
import '../../data/models/session.dart';
import '../../data/providers.dart';
import '../../core/errors/app_failure.dart';
import 'auth_store.dart';
import 'identity.dart';

class AuthState {
  const AuthState({this.account, this.token, this.onboardingSeen = false});

  final Account? account;
  final String? token;
  final bool onboardingSeen;

  bool get signedIn => account != null;
  bool get isProvider => account?.isProvider ?? false;
}

/// Loaded once in `bootstrap` so the first frame already knows who is signed in.
final initialAuthProvider = Provider<AuthSnapshot>(
  (ref) => const AuthSnapshot(),
);

/// Identity comes from Firebase Authentication (e-mail + password, Google); the server verifies the
/// Firebase ID token, owns the account record and hands out the signed session the phone keeps.
/// Without Firebase (tests, plain builds) sign-in falls back to the app's own password database.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final snapshot = ref.watch(initialAuthProvider);
    return AuthState(
      account: snapshot.account,
      token: snapshot.token,
      onboardingSeen: snapshot.onboardingSeen,
    );
  }

  Future<void> completeOnboarding() async {
    if (state.onboardingSeen) return;
    state = AuthState(
      account: state.account,
      token: state.token,
      onboardingSeen: true,
    );
    await AuthStore.saveOnboardingSeen();
  }

  /// True when sign-in goes through Firebase (the app has it and the server accepts it).
  Future<bool> _viaFirebase() async {
    if (!ref.read(identityProvider).available) return false;
    final methods = await ref.read(accountsRepositoryProvider).methods();
    return methods.allows(SignInMethod.email);
  }

  Future<Account> registerCustomer({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    if (!await _viaFirebase()) {
      return _start(
        await ref
            .read(accountsRepositoryProvider)
            .registerCustomer(
              name: name,
              phone: phone,
              email: email,
              password: password,
            ),
      );
    }
    return _firebaseRegister(
      email,
      password,
      role: 'customer',
      name: name,
      phone: phone,
    );
  }

  /// Creates the usta's listing and the account that manages it.
  Future<Account> registerProvider({
    required String name,
    required String phone,
    required String email,
    required String password,
    required ProviderApplication application,
  }) async {
    if (!await _viaFirebase()) {
      return _start(
        await ref
            .read(accountsRepositoryProvider)
            .registerProvider(
              name: name,
              phone: phone,
              email: email,
              password: password,
              application: application,
            ),
      );
    }
    return _firebaseRegister(
      email,
      password,
      role: 'provider',
      name: name,
      phone: phone,
      application: application,
    );
  }

  Future<Account> _firebaseRegister(
    String email,
    String password, {
    required String role,
    required String name,
    required String phone,
    ProviderApplication? application,
  }) async {
    final identity = ref.read(identityProvider);
    final token = await identity.emailIdToken(email, password, create: true);
    try {
      final outcome = await ref
          .read(accountsRepositoryProvider)
          .firebaseLogin(
            token,
            role: role,
            name: name,
            phone: phone,
            email: email,
            application: application,
          );
      final account = await _start(outcome.session as Session);
      await identity.sendEmailVerification();
      return account;
    } catch (_) {
      await identity.discardNewUser();
      rethrow;
    }
  }

  /// A customer who decides to offer services: same person, usta role added.
  Future<Account> upgradeToProvider(ProviderApplication application) async =>
      _start(await ref.read(accountsRepositoryProvider).upgrade(application));

  /// Throws an [AppFailure] with a Turkish message when the details do not match.
  Future<Account> signIn(String identifier, String password) async {
    if (!await _viaFirebase()) {
      return _start(
        await ref.read(accountsRepositoryProvider).login(identifier, password),
      );
    }
    final identity = ref.read(identityProvider);
    final token = await identity.emailIdToken(identifier, password);
    final outcome = await ref
        .read(accountsRepositoryProvider)
        .firebaseLogin(token);
    if (outcome.needsProfile) {
      await identity.signOut();
      throw const AppFailure(
        FailureKind.invalid,
        'Bu e-posta için kayıtlı bir hesap bulamadık. Önce kayıt ol.',
      );
    }
    return _start(outcome.session as Session);
  }

  /// "Şifremi unuttum": Firebase mails a reset link.
  Future<void> sendPasswordReset(String email) =>
      ref.read(identityProvider).sendPasswordReset(email);

  /// Google. Returns the signed-in account, or null when the person has to say who they are first
  /// (see [completeGoogle]) or closed the sheet. [idToken] is kept for the second step.
  Future<FederatedOutcome?> signInWithGoogle() async {
    final token = await ref.read(identityProvider).googleIdToken();
    if (token == null) return null;
    _googleToken = token;
    final outcome = await ref
        .read(accountsRepositoryProvider)
        .firebaseLogin(token);
    if (!outcome.needsProfile) await _start(outcome.session as Session);
    return outcome;
  }

  String? _googleToken;

  /// The second step for someone new: they confirmed their name (they start as a customer).
  Future<Account> completeGoogle({required String name, String? phone}) async {
    final token = _googleToken;
    if (token == null) {
      throw const AppFailure(
        FailureKind.invalid,
        'Giriş tamamlanamadı. Tekrar dene.',
      );
    }
    final outcome = await ref
        .read(accountsRepositoryProvider)
        .firebaseLogin(token, role: 'customer', name: name, phone: phone);
    return _start(outcome.session as Session);
  }

  Future<void> signOut() async {
    await ref.read(identityProvider).signOut();
    await AuthStore.saveSession(null, null);
    state = AuthState(onboardingSeen: state.onboardingSeen);
  }

  /// KVKK right to erasure: server side first, then this phone.
  Future<void> deleteAccount() async {
    final account = state.account;
    if (account == null) return;
    await ref.read(accountsRepositoryProvider).deleteAccount(account.id);
    await ref.read(identityProvider).deleteUser();
    await signOut();
  }

  /// The server rejected the session (expired or revoked): ask the person to sign in again.
  void sessionExpired() {
    if (state.signedIn) signOut();
  }

  Future<Account> _start(Session session) async {
    state = AuthState(
      account: session.account,
      token: session.token,
      onboardingSeen: true,
    );
    await AuthStore.saveSession(session.account, session.token);
    await AuthStore.saveOnboardingSeen();
    return session.account;
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
